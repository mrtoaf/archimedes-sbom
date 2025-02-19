//
//  UIColor.swift
//  MixpanelServiceKitUI
//
//  Created by Cameron Ingham on 5/29/23.
//

import UIKit

extension UIColor {

    @nonobjc static let delete = UIColor.HIGRedColor()

    // MARK: - HIG colors
    // See: https://developer.apple.com/ios/human-interface-guidelines/visual-design/color/

    private static func HIGRedColor() -> UIColor {
        return UIColor(red: 1, green: 59 / 255, blue: 48 / 255, alpha: 1)
    }

}
