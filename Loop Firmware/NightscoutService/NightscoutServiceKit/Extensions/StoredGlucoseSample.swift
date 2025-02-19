//
//  StoredGlucoseSample.swift
//  NightscoutServiceKit
//
//  Created by Darin Krauss on 10/13/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import LoopKit
import NightscoutKit

extension StoredGlucoseSample {

    var glucoseEntry: GlucoseEntry {
        let glucoseTrend: GlucoseEntry.GlucoseTrend?
        if let trend = trend {
            glucoseTrend = GlucoseEntry.GlucoseTrend(rawValue: trend.rawValue)
        } else {
            glucoseTrend = nil
        }

        let deviceString: String

        if let device = device, let manufacturer = device.manufacturer, let model = device.model, let name = device.name {
            deviceString = "\(manufacturer) \(model) \(name)"
        } else if let name = device?.name {
            deviceString = "\(name)"
        } else if !provenanceIdentifier.contains("loopkit.Loop") {
            deviceString = provenanceIdentifier
        } else {
            deviceString = "loop://\(UIDevice.current.name)"
        }

        return GlucoseEntry(
            glucose: quantity.doubleValue(for: .milligramsPerDeciliter),
            date: startDate,
            device: deviceString,
            glucoseType: wasUserEntered ? .meter : .sensor,
            trend: glucoseTrend,
            changeRate: trendRate?.doubleValue(for: .milligramsPerDeciliterPerMinute),
            isCalibration: isDisplayOnly
        )
    }

}
