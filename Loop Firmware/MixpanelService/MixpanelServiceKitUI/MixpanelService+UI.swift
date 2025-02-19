//
//  MixpanelService+UI.swift
//  MixpanelServiceKitUI
//
//  Created by Cameron Ingham on 5/29/23.
//

import SwiftUI
import LoopKit
import LoopKitUI
import MixpanelServiceKit
import HealthKit

extension MixpanelService: ServiceUI {
    
    public static var image: UIImage? {
        UIImage(named: "mixpanel_logo", in: Bundle(for: MixpanelServiceTableViewController.self), compatibleWith: nil)!
    }

    public static func setupViewController(colorPalette: LoopUIColorPalette, pluginHost: PluginHost) -> SetupUIResult<ServiceViewController, ServiceUI>
    {
        return .userInteractionRequired(ServiceNavigationController(rootViewController: MixpanelServiceTableViewController(service: MixpanelService(), for: .create)))
    }
    
    public func settingsViewController(colorPalette: LoopUIColorPalette) -> ServiceViewController
    {
        return ServiceNavigationController(rootViewController: MixpanelServiceTableViewController(service: self, for: .update))
    }
    
    public func supportMenuItem(supportInfoProvider: SupportInfoProvider, urlHandler: @escaping (URL) -> Void) -> AnyView? {
        return nil
    }
}
