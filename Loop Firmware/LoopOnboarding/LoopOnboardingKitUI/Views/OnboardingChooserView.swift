//
//  OnboardingChooserView.swift
//  LoopOnboardingKitUI
//
//  Created by Pete Schwamb on 9/11/20.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKitUI

struct OnboardingChooserView: View {
    var setupWithNightscout: (() -> Void)?
    var setupWithoutNightscout: (() -> Void)?

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text(LocalizedString("Nightscout", comment: "Title on OnboardingChooserView"))
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text(LocalizedString("Loop can work with Nightscout to provide remote caregivers a way to see what Loop is doing. Nightscout use is completely optional with Loop, and you can always set it up later.", comment: "Descriptive text on OnboardingChooserView"))
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: {
                self.setupWithNightscout?()
            }) {
                Text(LocalizedString("Use Nightscout with Loop", comment:"Button title for choosing onboarding with nightscout"))
                    .actionButtonStyle(.secondary)
            }
            Button(action: {
                self.setupWithoutNightscout?()
            }) {
                Text(LocalizedString("Setup Loop without Nightscout", comment:"Button title for choosing onboarding without nightscout"))
                    .actionButtonStyle(.secondary)
            }
        }
        .padding()
        .environment(\.horizontalSizeClass, .compact)
        .navigationBarTitle("")
    }
}

struct OnboardingChooserView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OnboardingChooserView()
        }
        .previewDevice("iPod touch (7th generation)")
    }
}
