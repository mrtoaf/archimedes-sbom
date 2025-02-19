//
//  AppleHealthAuthView.swift
//  LoopOnboarding
//
//  Created by Pete Schwamb on 3/4/22.
//

import SwiftUI
import HealthKit
import LoopKitUI

struct AppleHealthAuthView: View {

    var authorizeHealthStore: ((@escaping () -> Void) -> Void)?

    @State private var processing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                Text(LocalizedString("Apple Health", comment: "Title on AppleHealthAuthView"))
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Image(frameworkImage: "AppleHealthLogo", decorative: true)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                Text(LocalizedString("Apple Health can be used to store blood glucose, insulin and carbohydrate data from Loop.\n\nIf you give Loop permission, Loop can also read glucose and insulin data from glucometers and insulin pens that support Apple Health", comment: "Onboarding, Apple Health Permissions intro paragraph"))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    processing = true
                    authorizeHealthStore?() {
                        processing = false
                    }
                }) {
                    Text(LocalizedString("Share With Apple Health", comment:"Button title for starting apple health permissions request"))
                        .actionButtonStyle(.primary)
                }.disabled(processing == true)
            }
        }
        .padding()
        .environment(\.horizontalSizeClass, .compact)
        .navigationBarTitle("")
        .navigationBarHidden(false)
    }
}
