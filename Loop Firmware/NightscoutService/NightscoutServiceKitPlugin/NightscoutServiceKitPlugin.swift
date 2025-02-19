//
//  NightscoutServiceKitPlugin.swift
//  NightscoutServiceKitPlugin
//
//  Created by Darin Krauss on 9/19/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import os.log
import LoopKitUI
import NightscoutServiceKit
import NightscoutServiceKitUI

class NightscoutServiceKitPlugin: NSObject, ServiceUIPlugin {
    private let log = OSLog(category: "NightscoutServiceKitPlugin")

    public var serviceType: ServiceUI.Type? {
        return NightscoutService.self
    }

    override init() {
        super.init()
        log.default("Instantiated")
    }
}
