//
//  OTPSelectionView.swift
//  NightscoutServiceKitUI
//
//  Created by Bill Gestrich on 4/11/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import SwiftUI
import NightscoutServiceKit

struct OTPSelectionView: View {
    
    @ObservedObject var otpViewModel: OTPViewModel
    @State private var showingAlert = false
    
    var body: some View {
        VStack {
            Text(otpViewModel.otpCode).bold()
            otpViewModel.qrImage?
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.all)
            Text(otpViewModel.tokenName).bold()
        }
        .navigationBarItems(trailing: refreshButton)
    }
    
    private var refreshButton: some View {
        Button(action: {
            showingAlert = true
        }, label: {
            Image(systemName: "arrow.clockwise").imageScale(.large)
        }).alert(isPresented: $showingAlert) {
            Alert(title: Text("Reset Secret Key"),
                  message: Text("Are you sure you want to reset the secret key?"),
                  primaryButton: .default(Text("OK"), action: {
                    otpViewModel.resetSecretKey()
                  }),
                  secondaryButton: .default(Text("Cancel")))
        }
    }
    
    
}

struct OTPSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        OTPSelectionView(otpViewModel: OTPViewModel(otpManager: OTPManager()))
    }
}
