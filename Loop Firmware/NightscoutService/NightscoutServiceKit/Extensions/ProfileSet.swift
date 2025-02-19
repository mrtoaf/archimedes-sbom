//
//  ProfileSet.swift
//  NightscoutServiceKit
//
//  Created by Pete Schwamb on 2/21/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation
import NightscoutKit
import LoopKit
import HealthKit

private extension HKUnit {
    static func glucoseUnitFromNightscoutUnitString(_ unitString: String) -> HKUnit? {
        // Some versions of Loop incorrectly uploaded units with
        // special characters to avoid line breaking.
        if unitString == HKUnit.millimolesPerLiter.shortLocalizedUnitString() ||
            unitString == HKUnit.millimolesPerLiter.shortLocalizedUnitString(avoidLineBreaking: false)
        {
            return .millimolesPerLiter
        }

        if unitString == HKUnit.milligramsPerDeciliter.shortLocalizedUnitString() ||
            unitString == HKUnit.milligramsPerDeciliter.shortLocalizedUnitString(avoidLineBreaking: false)
        {
            return .milligramsPerDeciliter
        }

        return nil
    }
}

extension ProfileSet {
    var therapySettings: TherapySettings? {

        guard let profile = store["Default"],
              let glucoseSafetyLimit = settings.minimumBGGuard,
              let settingsGlucoseUnit = HKUnit.glucoseUnitFromNightscoutUnitString(units)
        else {
            return nil
        }

        // If units are specified on the schedule, prefer those over the units specified on the ProfileSet
        let scheduleGlucoseUnit: HKUnit
        if let profileUnitString = profile.units, let profileUnit = HKUnit.glucoseUnitFromNightscoutUnitString(profileUnitString)
        {
            scheduleGlucoseUnit = profileUnit
        } else {
            scheduleGlucoseUnit = settingsGlucoseUnit
        }

        let targetItems: [RepeatingScheduleValue<DoubleRange>] = zip(profile.targetLow, profile.targetHigh).map { (low,high) in
            return RepeatingScheduleValue(startTime: low.offset, value: DoubleRange(minValue: low.value, maxValue: high.value))
        }

        let targetRangeSchedule = GlucoseRangeSchedule(unit: scheduleGlucoseUnit, dailyItems: targetItems, timeZone: profile.timeZone)

        let correctionRangeOverrides: CorrectionRangeOverrides?
        if let range = settings.preMealTargetRange {
            correctionRangeOverrides = CorrectionRangeOverrides(
                preMeal: GlucoseRange(minValue: range.lowerBound, maxValue: range.upperBound, unit: settingsGlucoseUnit),
                workout: nil // No longer used
            )
        } else {
            correctionRangeOverrides = nil
        }

        let basalSchedule = BasalRateSchedule(
            dailyItems: profile.basal.map { RepeatingScheduleValue(startTime: $0.offset, value: $0.value) },
            timeZone: profile.timeZone)

        let sensitivitySchedule = InsulinSensitivitySchedule(
            unit: scheduleGlucoseUnit,
            dailyItems: profile.sensitivity.map { RepeatingScheduleValue(startTime: $0.offset, value: $0.value) },
            timeZone: profile.timeZone)

        let carbSchedule = CarbRatioSchedule(
            unit: .gram(),
            dailyItems: profile.carbratio.map { RepeatingScheduleValue(startTime: $0.offset, value: $0.value) },
            timeZone: profile.timeZone)


        return TherapySettings(
            glucoseTargetRangeSchedule: targetRangeSchedule,
            correctionRangeOverrides: correctionRangeOverrides,
            overridePresets: settings.overridePresets.compactMap { $0.loopOverride(for: settingsGlucoseUnit) },
            maximumBasalRatePerHour: settings.maximumBasalRatePerHour,
            maximumBolus: settings.maximumBolus,
            suspendThreshold: GlucoseThreshold(unit: settingsGlucoseUnit, value: glucoseSafetyLimit),
            insulinSensitivitySchedule: sensitivitySchedule,
            carbRatioSchedule: carbSchedule,
            basalRateSchedule: basalSchedule,
            defaultRapidActingModel: nil) // Not stored in NS yet
    }
}


extension NightscoutKit.TemporaryScheduleOverride  {

    func loopOverride(for unit: HKUnit) -> LoopKit.TemporaryScheduleOverridePreset? {
        guard let name = name,
            let symbol = symbol
        else {
            return nil
        }

        let target: DoubleRange?
        if let lowerBound = targetRange?.lowerBound,
           let upperBound = targetRange?.upperBound
        {
            target = DoubleRange(minValue: lowerBound, maxValue: upperBound)
        } else {
            target = nil
        }

        let temporaryOverrideSettings = TemporaryScheduleOverrideSettings(
            unit: unit,
            targetRange: target,
            insulinNeedsScaleFactor: insulinNeedsScaleFactor)

        let loopDuration: LoopKit.TemporaryScheduleOverride.Duration

        if duration == 0 {
            loopDuration = .indefinite
        } else {
            loopDuration = .finite(duration)
        }

        return TemporaryScheduleOverridePreset(
            symbol: symbol,
            name: name,
            settings: temporaryOverrideSettings,
            duration: loopDuration)
    }
}
