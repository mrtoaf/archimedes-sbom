//
//  RemoteCommandValidator.swift
//  LoopKit
//
//  Created by Bill Gestrich on 2/25/23.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

struct RemoteCommandValidator {
    
    let otpManager: OTPManager
    let nowDateSource: () -> Date = {Date()}
    
    internal init(otpManager: OTPManager) {
        self.otpManager = otpManager
    }
    
    func validate(remoteNotification: RemoteNotification) throws {
        try validateExpirationDate(remoteNotification: remoteNotification)
        if remoteNotification.otpValidationRequired() {
            try validateOTP(remoteNotification: remoteNotification)
        }
    }
    
    private func validateExpirationDate(remoteNotification: RemoteNotification) throws {
        
        guard let expirationDate = remoteNotification.expiration else {
            return //Skip validation if no date included
        }
        
        if nowDateSource() > expirationDate {
            throw NotificationValidationError.expiredNotification
        }
    }
    
    private func validateOTP(remoteNotification: RemoteNotification) throws {
        
        guard let otp = remoteNotification.otp else {
            throw NotificationValidationError.missingOTP
        }
        
        try otpManager.validatePassword(password: otp, deliveryDate: remoteNotification.sentAt)
    }
    
    enum NotificationValidationError: LocalizedError {
        case missingOTP
        case expiredNotification
        
        var errorDescription: String? {
            switch  self {
            case .missingOTP:
                return LocalizedString("Missing OTP", comment: "Remote command error description: Missing OTP.")
            case .expiredNotification:
                return LocalizedString("Expired", comment: "Remote command error description: expired.")
            }
        }
    }
}
