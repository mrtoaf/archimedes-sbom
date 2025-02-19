//
//  Bundle.swift
//  NightscoutServiceKit
//
//  Created by Darin Krauss on 6/20/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import Foundation

extension Bundle {

    var fullVersionString: String {
        return "\(shortVersionString).\(version)"
    }

    var shortVersionString: String {
        return object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    var version: String {
        return object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }

    var bundleDisplayName: String {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    }
    
}
