//
//  LoopOnboardingPlugin.swift
//  LoopOnboardingPlugin
//
//  Created by Darin Krauss on 1/23/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import os.log
import LoopKitUI
import LoopOnboardingKit
import LoopOnboardingKitUI

class LoopOnboardingPlugin: NSObject, OnboardingUIPlugin {
    private let log = OSLog(category: "LoopOnboardingPlugin")

    public var onboardingType: OnboardingUI.Type? {
        return LoopOnboardingUI.self
    }

    override init() {
        super.init()
        log.default("Instantiated")
    }
}
