//
//  CredentialsViewModel.swift
//  NightscoutServiceKitUI
//
//  Created by Pete Schwamb on 9/7/20.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import NightscoutServiceKit
import LoopKit

public enum CredentialsError: Error {
    case invalidUrl
}

class CredentialsViewModel: ObservableObject {
    @Published var isVerifying: Bool
    @Published var error: Error?

    var service: NightscoutService
    
    var didSucceed: (() -> Void)?
    var didCancel: (() -> Void)?

    init(service: NightscoutService) {
        self.service = service
        isVerifying = false
    }
    
    func attemptAuth(urlString: String, apiSecret: String) {
        if let url = URL(string: urlString) {
            service.siteURL = url
            service.apiSecret = apiSecret
            isVerifying = true
            self.error = nil
            service.verifyConfiguration { (error) in
                DispatchQueue.main.async {
                    self.isVerifying = false
                    self.error = error
                    
                    if error == nil {
                        self.didSucceed?()
                    }
                }
            }
        } else {
            self.error = CredentialsError.invalidUrl
        }
    }
}
