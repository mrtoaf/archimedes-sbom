//
//  StoredCarbEntry.swift
//  NightscoutServiceKit
//
//  Created by Darin Krauss on 6/20/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKit
import NightscoutKit
import HealthKit

extension SyncCarbObject {

    func carbCorrectionNightscoutTreatment(withObjectId objectId: String? = nil) -> CarbCorrectionNightscoutTreatment? {

        return CarbCorrectionNightscoutTreatment(
            timestamp: startDate,
            enteredBy: "loop://\(UIDevice.current.name)",
            id: objectId,
            carbs: lround(grams),
            absorptionTime: absorptionTime,
            foodType: foodType,
            syncIdentifier: syncIdentifier,
            userEnteredAt: userCreatedDate,
            userLastModifiedAt: userUpdatedDate
        )
    }

}
