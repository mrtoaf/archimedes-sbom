//
//  LogglyServiceKitPlugin.swift
//  LogglyServiceKitPlugin
//
//  Created by Darin Krauss on 9/19/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import os.log
import LoopKitUI
import LogglyServiceKit
import LogglyServiceKitUI

class LogglyServiceKitPlugin: NSObject, ServiceUIPlugin {
    private let log = OSLog(category: "LogglyServiceKitPlugin")

    public var serviceType: ServiceUI.Type? {
        return LogglyService.self
    }

    override init() {
        super.init()
        log.default("Instantiated")
    }
}
