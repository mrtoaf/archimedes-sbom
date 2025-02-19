//
//  LoopSupportUI.swift
//  LoopSupportKitUI
//
//  Created by Darin Krauss on 1/23/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import Foundation
import SwiftUI
import LoopKit
import LoopKitUI

public final class LoopSupportUI: SupportUI {

    public static var pluginIdentifier: String = "LoopSupportUI"

    private var analytics = LoopKitAnalytics.shared

    public func checkVersion(bundleIdentifier: String, currentVersion: String) async -> LoopKit.VersionUpdate? {
        return nil
    }

    public func softwareUpdateView(bundleIdentifier: String, currentVersion: String, guidanceColors: GuidanceColors, openAppStore: (() -> Void)?) -> AnyView? { nil }
    
    public init?(rawState: RawStateValue) {
        self.rawState = rawState
    }
    
    public var rawState: RawStateValue
    
    public init() {
        rawState = [:]
    }
    
    public func getScenarios(from scenarioURLs: [URL]) -> [LoopScenario] { [] }
    
    public func supportMenuItem(supportInfoProvider: SupportInfoProvider, urlHandler: @escaping (URL) -> Void) -> AnyView? {
        return AnyView(Button(LocalizedString("Submit Bug Report", comment: "Navigation link title for Submit Bug Report"), action: {
            let url = URL(string: "https://github.com/LoopKit/Loop/issues")!
            urlHandler(url)
        }))
    }
    
    public weak var delegate: SupportUIDelegate?

    public func initializationComplete(for services: [LoopKit.Service]) { }

    public func configurationMenuItems() -> [LoopKitUI.CustomMenuItem] {
        let view = Button(LocalizedString("Submit Bug Report", comment: "Navigation link title for Submit Bug Report"), action: {
            let url = URL(string: "https://github.com/LoopKit/Loop/issues")!
            self.delegate?.openURL(url: url)
        })
        return [
            CustomMenuItem(section: .support, view: AnyView(view)),
            CustomMenuItem(section: .configuration, view: AnyView(UsageDataPrivacyPreferenceMenuItem())),
        ]
    }

    public func loopWillReset() { }

    public func loopDidReset() { }

}

// LoopSupport also provides analytics
extension LoopSupportUI: AnalyticsService {

    public static var localizedTitle = LocalizedString("LoopKit Analytics", comment: "Title for LoopKit Analytics")

    public func recordAnalyticsEvent(_ name: String, withProperties properties: [AnyHashable : Any]?, outOfSession: Bool) {
        analytics.recordAnalyticsEvent(name, withProperties: properties, outOfSession: outOfSession)
    }

    public func recordIdentify(_ property: String, value: String) {
        analytics.recordIdentify(property, value: value)
    }

    public func recordIdentify(_ property: String, array: [String]) {
        analytics.recordIdentify(property, array: array)
    }

    public static var serviceIdentifier = "LoopKitAnalytics"

    public var serviceDelegate: LoopKit.ServiceDelegate? {
        get {
            return nil
        }
        set(newValue) {}
    }
    
    public var stateDelegate: LoopKit.StatefulPluggableDelegate? {
        get {
            return nil
        }
        set(newValue) {}
    }

    public var isOnboarded: Bool {
        return true
    }
}
