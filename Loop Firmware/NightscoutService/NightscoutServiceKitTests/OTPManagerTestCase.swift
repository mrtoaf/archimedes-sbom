//
//  OTPManagerTestCase.swift
//  NightscoutServiceKitTests
//
//  Created by Bill Gestrich on 8/13/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import XCTest
@testable import NightscoutServiceKit
@testable import OneTimePassword

class OTPManagerTestCase: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
    

    func testValidOTPs_ProvidesValidOTPs() throws {
        
        //Arrange
        let testCoordinator = OTPTestCoordinator()
        let manager = testCoordinator.createOTPManager()

        //Act
        let validOTPs = try manager.validOTPs()
        
        //Assert
        XCTAssertEqual(validOTPs, testCoordinator.validOTPs())
    }
    
    func testCurrentOTP_ProvidesCurrentOTP() throws {
        
        //Arrange
        let testCoordinator = OTPTestCoordinator()
        let manager = testCoordinator.createOTPManager()
        
        //Act
        let currentOTP = manager.currentOTP()
        
        //Assert
        XCTAssertEqual(currentOTP, testCoordinator.currentOTP())
    }

    func testValidatePassword_WhenOldestAcceptedPasswordUsed_Succeeds() throws {
        
        //Arrange
        let testCoordinator = OTPTestCoordinator()
        let manager = testCoordinator.createOTPManager()
        let oldestOTP = testCoordinator.oldestValidOTP()
        
        //Act + Assert
        XCTAssertNoThrow(try manager.validatePassword(password: oldestOTP.password, deliveryDate: oldestOTP.period.startDate))
    }
    
    func testValidateOTP_WhenExpiredPasswordUsed_Throws() throws {
        
        //Arrange
        let testCoordinator = OTPTestCoordinator()
        let manager = testCoordinator.createOTPManager()
        let expiredOTP = testCoordinator.expiredOTP()
        
        //Act
        var thrownError: Error? = nil
        do {
            try manager.validatePassword(password: expiredOTP.password, deliveryDate: expiredOTP.period.startDate)
        } catch {
            thrownError = error
        }
        
        //Assert
        guard let validationError = thrownError as? OTPManager.OTPValidationError, case .expired = validationError else {
            XCTFail("Unexpected type \(thrownError.debugDescription)")
            return
        }
    
    }
    
    func testValidateOTP_WhenIncorrectPasswordUsed_Throws() throws {
        
        //Arrange
        let testCoordinator = OTPTestCoordinator()
        let manager = testCoordinator.createOTPManager()
        let randomOTP = "123456"
        
        //Act
        var thrownError: Error? = nil
        do {
            try manager.validatePassword(password: randomOTP, deliveryDate: testCoordinator.currentOTP().period.startDate)
        } catch {
            thrownError = error
        }
        
        //Assert
        guard let validationError = thrownError as? OTPManager.OTPValidationError, case .incorrectOTP = validationError else {
            XCTFail("Unexpected type \(thrownError.debugDescription)")
            return
        }
    
    }
    
    func testValidateOTP_WhenBadlyFormattedPasswordUsed_Throws() throws {
        
        //Arrange
        let testCoordinator = OTPTestCoordinator()
        let manager = testCoordinator.createOTPManager()
        let invalidFormatOTP = "12345" //Requires length of 6
        
        //Act
        var thrownError: Error? = nil
        do {
            try manager.validatePassword(password: invalidFormatOTP, deliveryDate: testCoordinator.currentOTP().period.startDate)
        } catch {
            thrownError = error
        }
        
        //Assert
        guard let validationError = thrownError as? OTPManager.OTPValidationError, case .invalidFormat = validationError else {
            XCTFail("Unexpected type \(thrownError.debugDescription)")
            return
        }
    
    }
    
    func testValidateOTP_WhenPasswordReused_Throws() throws {
        
        //Arrange
        let testCoordinator = OTPTestCoordinator()
        let manager = testCoordinator.createOTPManager()
        let otp = testCoordinator.currentOTP()
        try manager.validatePassword(password: otp.password, deliveryDate: otp.period.startDate)
        
        //Act + Assert
        XCTAssertThrowsError(try manager.validatePassword(password: otp.password, deliveryDate: otp.period.startDate))
    }
    
    func testValidateOTP_WhenOTPInsertionFails_Throws() throws {
        
        //Arrange
        let testCoordinator = OTPTestCoordinator()
        testCoordinator.simulateFailedPasswordInsertion = true
        let manager = testCoordinator.createOTPManager()
        let otp = testCoordinator.currentOTP()
        
        //Act + Assert
        XCTAssertThrowsError(try manager.validatePassword(password: otp.password, deliveryDate: otp.period.startDate))
    }
}

///The OTPTestCoordinator provides a fixed, valid sequence of OTPs for testing.
///A factory method is available for creating an OTPManager with same authentication parameters, and current date source.
class OTPTestCoordinator: OTPSecretStore {

    var secretKey: String?
    var keyName: String?
    var recentlyAcceptedPasswords = [String]()
    var simulateFailedPasswordInsertion: Bool = false
    private let otpSequenceAscending: [OTP]
    
    init(){
        
        /*
         To get sequence of OTP codes from an independent source for these tests:
         
         1. Go to https://cryptotools.net/otp
         2. Paste the test secretKey below to site
         3. Capture the Epoch time from site
         4. Capture 4 consecutive codes
         5. Update the startDate below
         6. Update otps below

         */
        
        let startDate = Date(timeIntervalSince1970: 1670001615).floor(precision: OTPManager.defaultTokenPeriod)
        let passwords = ["306469", "649742", "881201", "086432"]
        var otps = [OTP]()
        for (index, password) in passwords.enumerated() {
            let otpStartDate = startDate.addingTimeInterval(TimeInterval(index) * OTPManager.defaultTokenPeriod)
            let otpEndDate = otpStartDate.addingTimeInterval(OTPManager.defaultTokenPeriod)
            otps.append(OTP(period: OTPPeriod(startDate: otpStartDate, endDate: otpEndDate), password: password))
        }
        
        self.secretKey = "2IOF4MG5QSAKMIYD6QJKOBZFH2QV2CYG"
        self.keyName = "Test Key"
        self.otpSequenceAscending = otps
    }
    
    func createOTPManager() -> OTPManager {
        return OTPManager(secretStore: self, nowDateSource: {self.currentOTP().period.startDate})
    }
    
    
    //MARK: OTPSecretStore
    
    func setTokenSecretKey(_ key: String?) throws {
        secretKey = key
    }
    
    func tokenSecretKey() -> String? {
        return secretKey
    }
    
    func tokenSecretKeyName() -> String? {
        return keyName
    }
    
    func setTokenSecretKeyName(_ name: String?) throws {
        keyName = name
    }
    
    func recentAcceptedPasswords() -> [String] {
        return recentlyAcceptedPasswords
    }
    
    func setRecentAcceptedPasswords(_ passwords: [String]) throws {
        if self.simulateFailedPasswordInsertion {
            throw MockSecretStoreError.passwordInsertion
        }
        self.recentlyAcceptedPasswords = passwords
    }
    
    
    //MARK: OTP Test Data
    
    func validOTPs() -> [OTP] {
        let firstIndex = otpSequenceAscending.count - OTPManager.defaultMaxOTPsToAccept
        return Array(otpSequenceAscending[firstIndex...])
    }
    
    func currentOTP() -> OTP {
        return validOTPs().last!
    }
    
    func oldestValidOTP() -> OTP {
        return validOTPs().first!
    }
    
    func expiredOTP() -> OTP {
        assert(otpSequenceAscending.count > OTPManager.defaultMaxOTPsToAccept)
        return otpSequenceAscending.first!
    }
    
    enum MockSecretStoreError: Error {
        case passwordInsertion
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
