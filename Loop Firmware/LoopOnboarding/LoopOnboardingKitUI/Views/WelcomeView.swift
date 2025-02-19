//
//  WelcomeView.swift
//  LoopOnboardingKitUI
//
//  Created by Pete Schwamb on 9/11/20.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKitUI

struct WelcomeView: View {
    var didContinue: (() -> Void)?
    var didLongPressOnLogo: (() -> Void)?

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Spacer()
            Text(LocalizedString("Welcome to Loop", comment: "Title on WelcomeView"))
                .font(.largeTitle)
                .fontWeight(.semibold)
            Image(frameworkImage: "Loop", decorative: true)
                .onLongPressGesture(minimumDuration: 2) {
                    didLongPressOnLogo?()
                }

            Text(LocalizedString("Before using Loop you need to configure a few settings. These settings should be entered with precision and care; they are a critical part of how Loop determines the right amount of insulin to deliver.\n\nIf you are new to Loop, work with your diabetes support team to determine the settings that work best for you.", comment: "Descriptive text on WelcomeView"))
                .foregroundColor(.secondary)
            Spacer()
            Button(action: {
                self.didContinue?()
            }) {
                Text(LocalizedString("Let's Go!", comment:"Button title for starting setup"))
                    .actionButtonStyle(.primary)
            }
        }
        .padding()
        .environment(\.horizontalSizeClass, .compact)
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WelcomeView()
        }
        .previewDevice("iPod touch (7th generation)")
    }
}
