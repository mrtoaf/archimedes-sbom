//
//  TimeInterval.swift
//  NightscoutServiceKit
//
//  Created by Darin Krauss on 6/20/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import Foundation

extension TimeInterval {

    static func minutes(_ minutes: Double) -> TimeInterval {
        return self.init(minutes: minutes)
    }

    static func hours(_ hours: Double) -> TimeInterval {
        return self.init(hours: hours)
    }

    init(minutes: Double) {
        self.init(minutes * 60)
    }

    init(hours: Double) {
        self.init(minutes: hours * 60)
    }

    var minutes: Double {
        return self / 60.0
    }

    var hours: Double {
        return minutes / 60.0
    }

}
