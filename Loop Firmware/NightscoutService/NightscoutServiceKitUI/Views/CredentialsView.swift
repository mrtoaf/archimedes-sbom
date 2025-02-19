//
//  CredentialsView.swift
//  NightscoutServiceKitUI
//
//  Created by Pete Schwamb on 9/7/20.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKitUI
import NightscoutServiceKit

struct CredentialsView: View, HorizontalSizeClassOverride {
    @ObservedObject var viewModel: CredentialsViewModel
    @ObservedObject var keyboardObserver = KeyboardObserver()
    
    @State var url: String
    @State var apiSecret: String
    
    var allowCancel: Bool
    
    var body: some View {
        VStack {
            Text(LocalizedString("Nightscout Login", comment: "Title on Nightscout CredentialsView"))
                .font(.largeTitle)
                .fontWeight(.semibold)
            Image(frameworkImage: "nightscout", decorative: true)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 150)
            
            TextField("Site URL", text: $url)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
            SecureField("API Secret", text: $apiSecret)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
            
            if self.viewModel.error != nil {
                Text(String(describing: self.viewModel.error!))
            }

            Button(action: { self.viewModel.attemptAuth(urlString: self.url, apiSecret: self.apiSecret) } ) {
                if self.viewModel.isVerifying {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    Text(LocalizedString("Login", comment: "Button text to login on Nightscout CredentialsView"))
                }
            }
            .buttonStyle(ActionButtonStyle(.primary))
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if allowCancel {
                Button(action: { self.viewModel.didCancel?() } ) {
                    Text(LocalizedString("Cancel", comment: "Button text to cancel Nightscout credential input")).padding(.top, 20)
                }
            }
        }
        .padding([.leading, .trailing])
        .offset(y: -keyboardObserver.height*0.4)
        .navigationBarHidden(allowCancel)
        .navigationBarTitle("")
    }
}


struct CredentialsView_Previews: PreviewProvider {
    static var previews: some View {
        CredentialsView(viewModel: CredentialsViewModel(service: NightscoutService()), url: "", apiSecret: "", allowCancel: true)
        .environment(\.colorScheme, .dark)
    }
}
