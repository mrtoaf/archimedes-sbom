//
//  TemporaryScheduleOverride.swift
//  NightscoutServiceKit
//
//  Created by Darin Krauss on 10/17/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import HealthKit
import LoopKit
import NightscoutKit

extension LoopKit.TemporaryScheduleOverride {

    func nsScheduleOverride(for unit: HKUnit) -> NightscoutKit.TemporaryScheduleOverride {
        let nsTargetRange: ClosedRange<Double>?
        if let targetRange = settings.targetRange {
            nsTargetRange = ClosedRange(uncheckedBounds: (
                lower: targetRange.lowerBound.doubleValue(for: unit),
                upper: targetRange.upperBound.doubleValue(for: unit)))
        } else {
            nsTargetRange = nil
        }

        let nsDuration: TimeInterval
        switch duration {
        case .finite(let interval):
            nsDuration = interval
        case .indefinite:
            nsDuration = 0
        }

        return NightscoutKit.TemporaryScheduleOverride(
            duration: nsDuration,
            targetRange: nsTargetRange,
            insulinNeedsScaleFactor: settings.insulinNeedsScaleFactor,
            symbol: context.symbol,
            name: context.name)
    }

}

extension LoopKit.TemporaryScheduleOverride.Context {

    var name: String? {
        switch self {
        case .custom:
            return nil
        case .legacyWorkout:
            return LocalizedString("Workout", comment: "Name uploaded to Nightscout for legacy workout override")
        case .preMeal:
            return LocalizedString("Pre-Meal", comment: "Name uploaded to Nightscout for Pre-Meal override")
        case .preset(let preset):
            return preset.name
        }
    }

    var symbol: String? {
        switch self {
        case .preset(let preset):
            return preset.symbol
        default:
            return nil
        }
    }

}

extension LoopKit.TemporaryScheduleOverridePreset {

    func nsScheduleOverride(for unit: HKUnit) -> NightscoutKit.TemporaryScheduleOverride {
        let nsTargetRange: ClosedRange<Double>?
        if let targetRange = settings.targetRange {
            nsTargetRange = ClosedRange(uncheckedBounds: (
                lower: targetRange.lowerBound.doubleValue(for: unit),
                upper: targetRange.upperBound.doubleValue(for: unit)))
        } else {
            nsTargetRange = nil
        }

        let nsDuration: TimeInterval
        switch duration {
        case .finite(let interval):
            nsDuration = interval
        case .indefinite:
            nsDuration = 0
        }

        return NightscoutKit.TemporaryScheduleOverride(
            duration: nsDuration,
            targetRange: nsTargetRange,
            insulinNeedsScaleFactor: settings.insulinNeedsScaleFactor,
            symbol: self.symbol,
            name: self.name)
    }

}
