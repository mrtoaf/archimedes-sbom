//
//  StoredDosingDecision.swift
//  NightscoutServiceKit
//
//  Created by Darin Krauss on 10/17/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import Foundation
import HealthKit
import LoopKit
import NightscoutKit

extension StoredDosingDecision {
    
    var loopStatusIOB: IOBStatus? {
        guard let insulinOnBoard = insulinOnBoard else {
            return nil
        }
        return IOBStatus(timestamp: insulinOnBoard.startDate, iob: insulinOnBoard.value)
    }
    
    var loopStatusCOB: COBStatus? {
        guard let carbsOnBoard = carbsOnBoard else {
            return nil
        }
        return COBStatus(cob: carbsOnBoard.quantity.doubleValue(for: HKUnit.gram()), timestamp: carbsOnBoard.startDate)
    }
    
    var loopStatusPredicted: PredictedBG? {
        guard let predictedGlucose = predictedGlucose, let startDate = predictedGlucose.first?.startDate else {
            return nil
        }
        return PredictedBG(startDate: startDate, values: predictedGlucose.map { $0.quantity })
    }
    
    var loopStatusAutomaticDoseRecommendation: NightscoutKit.AutomaticDoseRecommendation? {
        guard let automaticDoseRecommendation = automaticDoseRecommendation else {
            return nil
        }
        
        let nightscoutTempBasalAdjustment: TempBasalAdjustment?
        
        if let basalAdjustment = automaticDoseRecommendation.basalAdjustment {
            nightscoutTempBasalAdjustment = TempBasalAdjustment(rate: basalAdjustment.unitsPerHour, duration: basalAdjustment.duration)
        } else {
            nightscoutTempBasalAdjustment = nil
        }
        
        return NightscoutKit.AutomaticDoseRecommendation(
            timestamp: date,
            tempBasalAdjustment: nightscoutTempBasalAdjustment,
            bolusVolume: automaticDoseRecommendation.bolusUnits ?? 0)
    }

    var loopStatusRecommendedBolus: Double? {
        guard let manualBolusRecommendation = manualBolusRecommendation else {
            return nil
        }
        return manualBolusRecommendation.recommendation.amount
    }
    
    var loopStatusEnacted: LoopEnacted? {
        guard let automaticDoseRecommendation = automaticDoseRecommendation, errors.isEmpty else {
            return nil
        }
        let tempBasal = automaticDoseRecommendation.basalAdjustment
        // NS needs to be updated to support an "enacted" field with no rate. Once that happens, we should not report a fake cancel here, and rate/duration should be nil instead of 0
        return LoopEnacted(rate: tempBasal?.unitsPerHour ?? 0, duration: tempBasal?.duration ?? 0, timestamp: date, received: true, bolusVolume: automaticDoseRecommendation.bolusUnits ?? 0)
    }

    var loopStatusFailureReason: String? {
        return errors.first?.description
    }
    
    var pumpStatusBattery: BatteryStatus? {
        guard let pumpBatteryChargeRemaining = pumpManagerStatus?.pumpBatteryChargeRemaining else {
            return nil
        }
        return BatteryStatus(percent: Int(round(pumpBatteryChargeRemaining * 100)), voltage: nil, status: nil)
    }
    
    var pumpStatusBolusing: Bool {
        guard let pumpManagerStatus = pumpManagerStatus, case .inProgress = pumpManagerStatus.bolusState else {
            return false
        }
        return true
    }
    
    var pumpStatusReservoir: Double? {
        guard let lastReservoirValue = lastReservoirValue, lastReservoirValue.startDate > Date().addingTimeInterval(.minutes(-15)) else {
            return nil
        }
        return lastReservoirValue.unitVolume
    }
    
    var pumpStatus: PumpStatus? {
        guard let pumpManagerStatus = pumpManagerStatus else {
            return nil
        }

        return PumpStatus(
            clock: date,
            pumpID: pumpManagerStatus.device.localIdentifier ?? "Unknown",
            manufacturer: pumpManagerStatus.device.manufacturer,
            model: pumpManagerStatus.device.model,
            iob: nil,
            battery: pumpStatusBattery,
            suspended: pumpManagerStatus.basalDeliveryState?.isSuspended,
            bolusing: pumpStatusBolusing,
            reservoir: pumpStatusReservoir,
            secondsFromGMT: pumpManagerStatus.timeZone.secondsFromGMT(),
            reservoirDisplayOverride: pumpStatusHighlight?.localizedMessage,
            reservoirLevelOverride: pumpStatusHighlight?.reservoirLevelOverride
        )
    }
    
    var overrideStatus: NightscoutKit.OverrideStatus {
        guard let scheduleOverride = scheduleOverride, scheduleOverride.isActive(),
            let glucoseTargetRange = glucoseTargetRangeSchedule?.value(at: date) else
        {
            return NightscoutKit.OverrideStatus(timestamp: date, active: false)
        }
        
        let unit = glucoseTargetRangeSchedule?.unit ?? HKUnit.milligramsPerDeciliter
        let lowerTarget = HKQuantity(unit: unit, doubleValue: glucoseTargetRange.minValue)
        let upperTarget = HKQuantity(unit: unit, doubleValue: glucoseTargetRange.maxValue)
        let currentCorrectionRange = CorrectionRange(minValue: lowerTarget, maxValue: upperTarget)
        let duration = scheduleOverride.duration != .indefinite ? round(scheduleOverride.actualEndDate.timeIntervalSince(date)): nil
        
        return NightscoutKit.OverrideStatus(name: scheduleOverride.context.name,
                                                  timestamp: date,
                                                  active: true,
                                                  currentCorrectionRange: currentCorrectionRange,
                                                  duration: duration,
                                                  multiplier: scheduleOverride.settings.insulinNeedsScaleFactor)
    }
    
    var uploaderStatus: UploaderStatus {
        let uploaderDevice = UIDevice.current
        let battery = uploaderDevice.isBatteryMonitoringEnabled ? Int(uploaderDevice.batteryLevel * 100) : 0
        return UploaderStatus(name: uploaderDevice.name, timestamp: date, battery: battery)
    }
    
    func deviceStatus(automaticDoseDecision: StoredDosingDecision?) -> DeviceStatus {
        return DeviceStatus(device: "loop://\(UIDevice.current.name)",
            timestamp: date,
            pumpStatus: pumpStatus,
            uploaderStatus: uploaderStatus,
            loopStatus: LoopStatus(name: Bundle.main.bundleDisplayName,
                                   version: Bundle.main.fullVersionString,
                                   timestamp: date,
                                   iob: loopStatusIOB,
                                   cob: loopStatusCOB,
                                   predicted: loopStatusPredicted,
                                   automaticDoseRecommendation: loopStatusAutomaticDoseRecommendation,
                                   recommendedBolus: loopStatusRecommendedBolus,
                                   enacted: automaticDoseDecision?.loopStatusEnacted,
                                   failureReason: automaticDoseDecision?.loopStatusFailureReason),
            overrideStatus: overrideStatus)
    }
    
}

extension StoredDosingDecision.Issue {
    var description: String {
        var description = id
        if let details = details {
            description += String(describing: details)
        }
        return description
    }
}

extension StoredDosingDecision.StoredDeviceHighlight {
    var reservoirLevelOverride: NightscoutSeverityLevel {
        switch state {
        case .normalPump, .normalCGM:
            return .none
        case .warning:
            return .warn
        case .critical:
            return .urgent
        }
    }
}

