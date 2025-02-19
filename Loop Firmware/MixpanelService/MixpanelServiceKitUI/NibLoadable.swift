//
//  NibLoadable.swift
//  MixpanelServiceKitUI
//
//  Created by Cameron Ingham on 5/29/23.
//

import UIKit

protocol NibLoadable: IdentifiableClass {

    static func nib() -> UINib

}

extension NibLoadable {

    static func nib() -> UINib {
        return UINib(nibName: className, bundle: Bundle(for: self))
    }
    
}
