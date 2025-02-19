//
//  OTPViewModel.swift
//  NightscoutServiceKitUI
//
//  Created by Bill Gestrich on 5/2/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import NightscoutServiceKit
import SwiftUI


class OTPViewModel: ObservableObject {
    
    @Published var otpCode: String = ""
    @Published var tokenName: String = ""
    @Published var qrImage: Image? = nil
    
    private var timer: Timer? = nil
    private var otpManager: OTPManager

    init(otpManager: OTPManager) {
        self.otpManager = otpManager
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.refreshCurrentOTP()
        }
        refreshCurrentOTP()
    }
    
    func resetSecretKey() {
        otpManager.resetSecretKey()
        refreshCurrentOTP()
    }
    
    private func refreshCurrentOTP() {
        self.otpCode = otpManager.currentPassword() ?? ""
        self.tokenName = otpManager.tokenName() ?? ""
        if let url = otpManager.otpURL {
            self.qrImage = createQRImage(otpURL: url)
        }
    }
    
    private func createQRImage(otpURL: String) -> Image? {
        
        //Get data and apply CIFilter
        let data = otpURL.data(using: String.Encoding.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            assertionFailure("Could not create CIFilter")
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 6, y: 6)
        guard let ciOutputImage = filter.outputImage?.transformed(by: transform) else {
            assertionFailure("Could not transform with CIFilter")
            return nil
        }
        
        return ciOutputImage.toSwiftImage()
    }
}

private extension CIImage {
    //https://stackoverflow.com/questions/58087991/converting-from-uiimage-to-a-swiftui-image-results-in-a-blank-image-of-the-same
    func toSwiftImage() -> Image? {
        
        //Convert to CGImage
        let context = CIContext()
        guard let cgOutputImage = context.createCGImage(self, from: self.extent) else {
            assertionFailure("Could not create CGImage")
            return nil
        }
        
        //Convert to UIImage
        let uiImage = UIImage(cgImage: cgOutputImage)
        
        //Convert to Swift Image
        return Image(uiImage: uiImage)
    }
}
