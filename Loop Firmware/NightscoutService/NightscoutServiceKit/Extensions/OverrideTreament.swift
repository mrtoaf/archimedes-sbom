//
//  OverrideTreament.swift
//  NightscoutServiceKit
//
//  Created by Pete Schwamb on 2/28/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation
import NightscoutKit
import LoopKit
import HealthKit

extension OverrideTreatment {
    convenience init(override: LoopKit.TemporaryScheduleOverride) {

        // NS Treatments should be in mg/dL
        let unit: HKUnit = .milligramsPerDeciliter

        let nsTargetRange: ClosedRange<Double>?
        if let targetRange = override.settings.targetRange {
            nsTargetRange = ClosedRange(uncheckedBounds: (
                lower: targetRange.lowerBound.doubleValue(for: unit),
                upper: targetRange.upperBound.doubleValue(for: unit)))
        } else {
            nsTargetRange = nil
        }

        let reason: String
        switch override.context {
        case .custom:
            reason = NSLocalizedString("Custom Override", comment: "Name of custom override")
        case .legacyWorkout:
            reason = NSLocalizedString("Workout", comment: "Name of legacy workout override")
        case .preMeal:
            reason = NSLocalizedString("Pre-Meal", comment: "Name of pre-meal workout override")
        case .preset(let preset):
            reason = preset.symbol + " " + preset.name
        }

        let remoteAddress: String?
        let enteredBy: String
        if case .remote(let address) = override.enactTrigger {
            remoteAddress = address
            enteredBy = "Loop (via remote command)"
        } else {
            remoteAddress = nil
            enteredBy = "Loop"
        }

        let duration: OverrideTreatment.Duration
        switch override.duration {
        case .finite(let time):
            duration = .finite(time)
        case .indefinite:
            duration = .indefinite
        }

        self.init(startDate: override.startDate, enteredBy: enteredBy, reason: reason, duration: duration, correctionRange: nsTargetRange, insulinNeedsScaleFactor: override.settings.insulinNeedsScaleFactor, remoteAddress:remoteAddress, id: override.syncIdentifier.uuidString)
    }
}
