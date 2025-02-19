//
//  MixpanelServiceKitPlugin.swift
//  MixpanelServiceKitPlugin
//
//  Created by Cameron Ingham on 5/29/23.
//

import os.log
import LoopKitUI
import MixpanelServiceKit
import MixpanelServiceKitUI

class MixpanelServiceKitPlugin: NSObject, ServiceUIPlugin {
    private let log = OSLog(category: "MixpanelServiceKitPlugin")

    public var serviceType: ServiceUI.Type? {
        return MixpanelService.self
    }

    override init() {
        super.init()
        log.default("Instantiated")
    }

}
