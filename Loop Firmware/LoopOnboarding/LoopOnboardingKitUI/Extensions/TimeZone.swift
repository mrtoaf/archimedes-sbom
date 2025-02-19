//
//  TimeZone.swift
//  LoopOnboardingKitUI
//
//  Created by Pete Schwamb on 1/29/23.
//

import Foundation

extension TimeZone {
    static var currentFixed: TimeZone {
        return TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())!
    }
}
