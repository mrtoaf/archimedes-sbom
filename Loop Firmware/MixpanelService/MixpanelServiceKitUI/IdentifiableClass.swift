//
//  IdentifiableClass.swift
//  MixpanelServiceKitUI
//
//  Created by Cameron Ingham on 5/29/23.
//

import Foundation

protocol IdentifiableClass: AnyObject {
    static var className: String { get }
}

extension IdentifiableClass {

    static var className: String {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }
    
}
