//
//  AmplitudeServiceKitPlugin.swift
//  AmplitudeServiceKitPlugin
//
//  Created by Darin Krauss on 9/19/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import os.log
import LoopKitUI
import AmplitudeServiceKit
import AmplitudeServiceKitUI

class AmplitudeServiceKitPlugin: NSObject, ServiceUIPlugin {
    private let log = OSLog(category: "AmplitudeServiceKitPlugin")

    public var serviceType: ServiceUI.Type? {
        return AmplitudeService.self
    }

    override init() {
        super.init()
        log.default("Instantiated")
    }

}
