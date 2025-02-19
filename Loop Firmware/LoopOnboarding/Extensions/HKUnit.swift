//
//  HKUnit.swift
//  LoopOnboarding
//
//  Created by Pete Schwamb on 3/3/22.
//

import HealthKit

extension HKUnit {
    public static let milligramsPerDeciliter: HKUnit = {
        return HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
    }()
}
