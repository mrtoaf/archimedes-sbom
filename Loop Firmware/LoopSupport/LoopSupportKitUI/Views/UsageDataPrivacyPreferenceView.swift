//
//  UsageDataPrivacyPreferenceView.swift
//  LoopOnboardingKitUI
//
//  Created by Pete Schwamb on 12/29/22.
//

import SwiftUI
import LoopKitUI

public struct UsageDataPrivacyPreferenceView: View {
    var onboardingMode: Bool

    var didChoosePreference: ((UsageDataPrivacyPreference) -> Void)?
    var didFinish: (() -> Void)?

    @State private var preference: UsageDataPrivacyPreference

    public init(preference: UsageDataPrivacyPreference, onboardingMode: Bool, didChoosePreference: ((UsageDataPrivacyPreference) -> Void)? = nil, didFinish: (() -> Void)?) {
        self.preference = preference
        self.onboardingMode = onboardingMode
        self.didChoosePreference = didChoosePreference
        self.didFinish = didFinish
    }

    private func choice(title: String, description: String, sharingPreference: UsageDataPrivacyPreference) -> CheckmarkListItem {
        CheckmarkListItem(
            title: Text(title),
            description: Text(description),
            isSelected: Binding(
                get: { self.preference == sharingPreference},
                set: { isSelected in
                    if isSelected {
                        self.preference = sharingPreference
                    }
                }
            )
        )
    }

    public var body: some View {
        ConfigurationPageScrollView(content: {
            Text(LocalizedString("You can optionally choose to share usage data with Loop developers to improve Loop. Sharing is not required, and Loop will function fully no matter which option you choose. Usage data will not be shared with third parties.", comment: "Main summary text for UsageDataPrivacyPreferenceView"))
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.secondary)
                .padding()
            Card {
                chooser
            }
        }, actionArea: {
            if onboardingMode {
                Spacer()
                Button(action: {
                    self.didFinish?()
                }) {
                    Text(LocalizedString("Continue", comment:"Button title for choosing onboarding without nightscout"))
                        .actionButtonStyle(.primary)
                }
                .padding()
            }
        }) 
        .navigationTitle(Text(LocalizedString("Share Data", comment: "Title on UsageDataPrivacyPreferenceView")))
        .navigationBarHidden(false)
    }

    public var chooser: some View {
        VStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading) {
                choice(title: LocalizedString("No Sharing", comment: "Title in UsageDataPrivacyPreferenceView for no sharing"),
                       description: LocalizedString("Do not share any data.", comment: "Description in UsageDataPrivacyPreferenceView for no sharing"),
                       sharingPreference: .noSharing)
                choice(title: LocalizedString("Share Version Only", comment: "Title in UsageDataPrivacyPreferenceView for shareInstallationStatsOnly"),
                       description: LocalizedString("Anonymously share minimal data about this Loop version, to help developers know how many people are using Loop. Which device, and operating system version will also be shared.", comment: "Description in UsageDataPrivacyPreferenceView for shareInstallationStatsOnly"),
                       sharingPreference: .shareInstallationStatsOnly)
                choice(title: LocalizedString("Share Usage Data", comment: "Title in UsageDataPrivacyPreferenceView for shareUsageDetailsWithDevelopers"),
                       description: LocalizedString("In addition to version information, anonymously share data about how Loop is being used on your phone. Usage data includes events like opening loop, bolusing, adding carbs, and navigating between screens. It does not include health data like glucose values or dosing amounts.", comment: "Description in UsageDataPrivacyPreferenceView for shareUsageDetailsWithDevelopers"),
                       sharingPreference: .shareUsageDetailsWithDevelopers)
            }
        }
        .onChange(of: preference) { newValue in
            didChoosePreference?(newValue)
        }
    }
}
