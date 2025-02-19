//
//  UsageDataPrivacyPreferenceMenuItem.swift
//  LoopSupportKitUI
//
//  Created by Pete Schwamb on 12/31/22.
//

import Foundation


import SwiftUI
import LoopKitUI

public struct UsageDataPrivacyPreferenceMenuItem: View {

    @State var preference: UsageDataPrivacyPreference

    private var analytics = LoopKitAnalytics.shared

    init() {
        self.preference = analytics.usageDataPrivacyPreference ?? .noSharing
    }

    private func destination() -> UsageDataPrivacyPreferenceView {
        return UsageDataPrivacyPreferenceView(
            preference: preference,
            onboardingMode: false,
            didChoosePreference: { newValue in
                self.analytics.updateUsageDataPrivacyPreference(newValue: newValue)
                preference = newValue
            },
            didFinish: nil)
    }

    public var body: some View {
        NavigationLink(LocalizedString("Usage Data Sharing", comment: "Navigation Link Title for Usage Data Sharing"), destination: destination)
    }
}


