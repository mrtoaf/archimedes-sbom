//
//  ImportSettingsView.swift
//  LoopOnboardingKitUI
//
//  Created by Pete Schwamb on 2/21/22.
//

import SwiftUI
import LoopKitUI

struct ImportSettingsView: View {

    private var didFinish: ((Bool) -> Void)?
    private var settingsDate: Date

    private var settingsAgeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        return formatter
    }()

    init(settingsDate: Date, didFinish: ((Bool) -> Void)?) {
        self.settingsDate = settingsDate
        self.didFinish = didFinish
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text(LocalizedString("Settings Found", comment: "Title on ImportSettingsView"))
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text(String(format: LocalizedString("We've detected Loop settings stored in your Nightscout! They were last updated %1$@. Would you like to import them?\n\nAfter importing, you will still need to review the imported settings in the following screens and verify that they are correct.", comment: "Format string for main guidance text on ImportSettingsView (1: age of settings)"), settingsAgeFormatter.localizedString(fromTimeInterval: settingsDate.timeIntervalSinceNow)))
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: {
                self.didFinish?(true)
            }) {
                Text(LocalizedString("Import Saved Settings", comment:"Button title for choosing to import settings from nightscout"))
                    .actionButtonStyle(.primary)
            }
            Button(action: {
                self.didFinish?(false)
            }) {
                Text(LocalizedString("Do Not Import Settings", comment:"Button title for skipping setting import from nightscout"))
                    .actionButtonStyle(.secondary)
            }
        }
        .padding()
        .environment(\.horizontalSizeClass, .compact)
        .navigationBarTitle("")
    }
}

struct ImportSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ImportSettingsView(settingsDate: Date().addingTimeInterval(-24 * 60 * 60)) { (shouldImport) in
                print("Should import: \(shouldImport)")
            }
        }
        .previewDevice("iPod touch (7th generation)")
    }
}
