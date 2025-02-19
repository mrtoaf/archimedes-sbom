//
//  OTPManager.swift
//  Loop
//
//  Created by Jose Paredes on 3/28/20.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKit
import OneTimePassword
import Base32

private let OTPSecretKeyService = "OTPSecretKeyService"
private let OTPSecretKeyCreatedService = "OTPSecretKeyCreatedService"
private let OTPRecentAcceptedPasswordsService = "OTPRecentAcceptedPasswordsService"

public protocol OTPSecretStore {
    
    func tokenSecretKey() -> String?
    func setTokenSecretKey(_ key: String?) throws
    
    func tokenSecretKeyName() -> String?
    func setTokenSecretKeyName(_ name: String?) throws
    
    func recentAcceptedPasswords() -> [String]
    func setRecentAcceptedPasswords(_ passwords: [String]) throws
}

extension KeychainManager: OTPSecretStore {
    
    public func tokenSecretKey() -> String? {
        return try? getGenericPasswordForService(OTPSecretKeyService)
    }
    
    public func setTokenSecretKey(_ key: String?) throws {
        try replaceGenericPassword(key, forService: OTPSecretKeyService)
    }
    
    public func tokenSecretKeyName() -> String? {
        return try? getGenericPasswordForService(OTPSecretKeyCreatedService)
    }
    
    public func setTokenSecretKeyName(_ name: String?) throws {
        try replaceGenericPassword(name, forService: OTPSecretKeyCreatedService)
    }
    
    public func recentAcceptedPasswords() -> [String] {
        guard let recentString = try? getGenericPasswordForService(OTPRecentAcceptedPasswordsService) else {
            return []
        }

        return convertRecentAcceptedPasswordsFromString(recentString)
    }
    
    public func setRecentAcceptedPasswords(_ passwords: [String]) throws {
        try replaceGenericPassword(convertRecentAcceptedPasswordsToString(passwords), forService: OTPRecentAcceptedPasswordsService)
    }
    
    func convertRecentAcceptedPasswordsToString(_ recentAcceptedPasswords: [String]) -> String {
        return recentAcceptedPasswords.joined(separator: ",")
    }
    
    func convertRecentAcceptedPasswordsFromString(_ passwordsString: String) -> [String] {
        return passwordsString.split(separator: ",").map({String($0)})
    }
}

public class OTPManager {
    
    private var secretStore: OTPSecretStore
    private var nowDateSource: () -> Date
    let algorithm: Generator.Algorithm = .sha1
    let issuerName = "Loop"
    var tokenPeriod: TimeInterval
    var passwordDigitCount = 6
    let maxOTPsToAccept: Int
    
    public static var defaultTokenPeriod: TimeInterval = 30
    public static var defaultMaxOTPsToAccept = 2
    
    public init(secretStore: OTPSecretStore = KeychainManager(), nowDateSource: @escaping () -> Date = {Date()}, tokenPeriod: TimeInterval = OTPManager.defaultTokenPeriod, maxOTPsToAccept: Int = OTPManager.defaultMaxOTPsToAccept) {
        self.secretStore = secretStore
        self.nowDateSource = nowDateSource
        self.tokenPeriod = tokenPeriod
        self.maxOTPsToAccept = maxOTPsToAccept
        if secretStore.tokenSecretKey() == nil || secretStore.tokenSecretKeyName() == nil {
            resetSecretKey()
        }
    }
    
    public func validatePassword(password: String, deliveryDate: Date?) throws {
        
        guard password.count == passwordDigitCount else {
            throw OTPValidationError.invalidFormat(otp: password)
        }
        
        guard try isValidPassword(password) else {
            let recentOTPs = try otpsSince(date: nowDateSource().addingTimeInterval(-60*60))
            let otpIsExpired = recentOTPs.contains(where: {$0.password == password})
            if otpIsExpired {
                throw OTPValidationError.expired(deliveryDate: deliveryDate, maxOTPsToAccept: maxOTPsToAccept)
            } else {
                throw OTPValidationError.incorrectOTP(otp: password)
            }
        }
        
        let recentlyUsedOTPs = secretStore.recentAcceptedPasswords()
        guard !recentlyUsedOTPs.contains(password) else {
            throw OTPValidationError.previouslyUsed(otp: password)
        }
        
        try storeUsedPassword(password)
    }
    
    private func storeUsedPassword(_ password: String) throws {
        var recentOTPs = [password] + secretStore.recentAcceptedPasswords()
        if recentOTPs.count > maxOTPsToAccept {
            recentOTPs = Array(recentOTPs[0..<maxOTPsToAccept])
        }
        try secretStore.setRecentAcceptedPasswords(recentOTPs)
    }
    
    public func resetSecretKey() {
        let secretKey = createRandomSecretKey()
        let secretKeyName = createSecretKeyName()
        
        do {
            try secretStore.setTokenSecretKey(secretKey)
            try secretStore.setTokenSecretKeyName(secretKeyName)
        } catch {
            print("Could not store OTP to keychain \(error)")
        }
    }
    
    func createRandomSecretKey() -> String {
        let Base32Dictionary = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        return String((0..<32).map{_ in Base32Dictionary.randomElement()!})
    }
    
    func createSecretKeyName() -> String {
        return String(format: "%.0f", round(nowDateSource().timeIntervalSince1970*1000))
    }
    
    func otpToken() -> Token? {
        
        guard let secretKey = secretStore.tokenSecretKey(), let secretKeyName = secretStore.tokenSecretKeyName() else {
            return nil
        }
        
        guard let secretKeyData = MF_Base32Codec.data(fromBase32String: secretKey) else {
            print("Error: Could not create data from secret key")
            return nil
        }
        
        let generator = Generator(factor: .timer(period: TimeInterval(self.tokenPeriod)), secret: secretKeyData, algorithm: algorithm, digits: passwordDigitCount)!
        return Token(name: secretKeyName, issuer: issuerName, generator: generator)
    }
    
    public func validOTPs() throws -> [OTP] {
        return try otpsSince(date: oldestAcceptableOTPPeriod().startDate)
    }
    
    func otpsSince(date: Date) throws -> [OTP] {
        
        guard let token = self.otpToken() else {
            throw OTPValidationError.codeGeneratorFailed
        }
        
        let currentOTPPeriod = currentOTPPeriod()
        
        var toRet = [OTP]()
        for timeInterval in stride(from: date.timeIntervalSince1970, to: currentOTPPeriod.endDate.timeIntervalSince1970, by: tokenPeriod) {
            let otpStartDate = Date(timeIntervalSince1970: timeInterval)
            guard let password = try? token.generator.password(at: otpStartDate) else {
                throw OTPValidationError.codeGeneratorFailed
            }
            let otp = OTP(period: otpPeriodForDate(otpStartDate), password: password)
            toRet.append(otp)
        }
        return toRet
    }
    
    func isValidPassword(_ password: String) throws -> Bool {
        return try validOTPs().contains(where: {$0.password == password})
    }
    
    func oldestAcceptableOTPPeriod() -> OTPPeriod {
        let acceptedLookbackInterval = TimeInterval(maxOTPsToAccept - 1 ) * tokenPeriod
        let startDate = currentOTPPeriod().startDate.addingTimeInterval( -acceptedLookbackInterval )
        return otpPeriodForDate(startDate)
    }
    
    func currentOTPPeriod() -> OTPPeriod {
        return otpPeriodForDate(nowDateSource())
    }
    
    func otpPeriodForDate(_ date: Date) -> OTPPeriod {
        let startDate = date.floor(precision: tokenPeriod)
        let endDate = startDate.addingTimeInterval(tokenPeriod)
        return OTPPeriod(startDate: startDate, endDate: endDate)
    }
    
    public func currentOTP() -> OTP? {
        //We don't use self.otpToken()?.currentPassword as the date can't be injected for testing.
        do {
            return try validOTPs().last
        } catch {
            return nil
        }
    }
    
    public func currentPassword() -> String? {
        return currentOTP()?.password
    }
    
    public func tokenName() -> String? {
        return self.otpToken()?.name
    }
    
    public var otpURL: String? {
        
        guard let secretKey = secretStore.tokenSecretKey(), let tokenName = secretStore.tokenSecretKeyName() else {
            return nil
        }
        
        let queryItems = [
            URLQueryItem(name: "algorithm", value: algorithm.otpURLStringComponent()),
            URLQueryItem(name: "digits", value: "\(passwordDigitCount)"),
            URLQueryItem(name: "issuer", value: issuerName),
            URLQueryItem(name: "period", value: "\(Int(tokenPeriod))"),
            URLQueryItem(name: "secret", value: secretKey),
        ]
        
        let components = URLComponents(scheme: "otpauth", host: "totp", path: "/" + tokenName, queryItems: queryItems)
        return components.url?.absoluteString
    }
    
    enum OTPValidationError: LocalizedError {
        case missingOTP
        case expired(deliveryDate: Date?, maxOTPsToAccept: Int)
        case previouslyUsed(otp: String)
        case incorrectOTP(otp: String)
        case invalidFormat(otp: String)
        case codeGeneratorFailed
        
        var errorDescription: String? {
            switch self {
            case .missingOTP:
                return "Error: Password is required."
            case .expired(let deliveryDate, let maxOTPsToAccept):
                if let deliveryDate = deliveryDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "h:mm"
                    return String(format: "Error: Password sent at %@ has expired. Only the last %u passwords are accepted. See LoopDocs for troubleshooting.", dateFormatter.string(from: deliveryDate), maxOTPsToAccept)
                } else {
                    return String(format: "Error: Password has expired. See LoopDocs for troubleshooting.")
                }
            case .previouslyUsed(let otp):
                return "Error: Password \(otp) was already used. Wait for a new password for each command."
            case .invalidFormat(let otp):
                return "Error: Password has an invalid format: \(otp)."
            case .incorrectOTP(let otp):
                return "Error: Password is incorrect: \(otp)."
            case .codeGeneratorFailed:
                return "Error: Password validation is not available. See LoopDocs to setup."
            }
        }
    }
    
}

public struct OTP: Equatable {
    public let period: OTPPeriod
    public let password: String
}

public struct OTPPeriod: Equatable {
    public let startDate: Date
    public let endDate: Date
}

extension Generator.Algorithm {
    
    func otpURLStringComponent() -> String {
        switch self {
        case .sha1:
            return "SHA1"
        case .sha256:
            return "SHA256"
        case .sha512:
            return "SHA512"
        }
    }
}

extension URLComponents {
    init(scheme: String,
         host: String,
         path: String,
         queryItems: [URLQueryItem]) {
        self.init()
        self.scheme = scheme
        self.host = host
        self.path = path
        self.queryItems = queryItems
    }
}

//Rounding extension from https://stackoverflow.com/questions/1149256/round-nsdate-to-the-nearest-5-minutes
extension Date {

    public func round(precision: TimeInterval) -> Date {
        return round(precision: precision, rule: .toNearestOrAwayFromZero)
    }

    public func ceil(precision: TimeInterval) -> Date {
        return round(precision: precision, rule: .up)
    }

    public func floor(precision: TimeInterval) -> Date {
        return round(precision: precision, rule: .down)
    }

    private func round(precision: TimeInterval, rule: FloatingPointRoundingRule) -> Date {
        let seconds = (self.timeIntervalSinceReferenceDate / precision).rounded(rule) *  precision;
        return Date(timeIntervalSinceReferenceDate: seconds)
    }
}
