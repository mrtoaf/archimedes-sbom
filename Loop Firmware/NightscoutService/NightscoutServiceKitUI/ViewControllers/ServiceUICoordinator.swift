//
//  ServiceUICoordinator.swift
//  NightscoutServiceKitUI
//
//  Created by Pete Schwamb on 9/7/20.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import Foundation
import HealthKit
import SwiftUI
import LoopKit
import LoopKitUI
import NightscoutServiceKit

enum ServiceScreen {
    case login
    case status
    
    func next() -> ServiceScreen? {
        switch self {
        case .login:
            return nil
        case .status:
            return nil
        }
    }
}

class ServiceUICoordinator: UINavigationController, ServiceOnboarding, CompletionNotifying {
    public weak var serviceOnboardingDelegate: ServiceOnboardingDelegate?
    public weak var completionDelegate: CompletionDelegate?

    private let colorPalette: LoopUIColorPalette

    private var screenStack = [ServiceScreen]()
    private var currentScreen: ServiceScreen { return screenStack.last! }

    private var service: NightscoutService?

    init(service: NightscoutService? = nil, colorPalette: LoopUIColorPalette) {
        self.service = service
        self.colorPalette = colorPalette

        super.init(navigationBarClass: UINavigationBar.self, toolbarClass: UIToolbar.self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        self.navigationBar.prefersLargeTitles = true // ensure nav bar text is displayed correctly
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if service?.isOnboarded == true {
            screenStack = [.status]
        } else {
            screenStack = [.login]
        }

        let viewController = viewControllerForScreen(currentScreen)
        setViewControllers([viewController], animated: false)
    }
        
    private func viewControllerForScreen(_ screen: ServiceScreen) -> UIViewController {
        switch screen {
        case .login:
            if service == nil {
                let service = NightscoutService()
                service.completeCreate()
                serviceOnboardingDelegate?.serviceOnboarding(didCreateService: service)
                self.service = service
            }

            let model = CredentialsViewModel(service: service!)
            model.didSucceed = completeLogin
            model.didCancel = completeLogout
            let view = CredentialsView(viewModel: model, url: service?.siteURL?.absoluteString ?? "", apiSecret: service?.apiSecret ?? "", allowCancel: true)
            let hostedView = hostingController(rootView: view)
            return hostedView
        case .status:
            let viewModel = ServiceStatusViewModel(delegate: service!)
            viewModel.didLogout = completeLogout
            let view = ServiceStatusView(viewModel: viewModel, otpViewModel: OTPViewModel(otpManager: service!.otpManager))
            let hostedView = hostingController(rootView: view)
            return hostedView
        }
    }
    
    private func hostingController<Content: View>(rootView: Content) -> DismissibleHostingController<some View> {
        return DismissibleHostingController(content: rootView, colorPalette: colorPalette)
    }

    private func stepFinished() {
        if let nextScreen = currentScreen.next() {
            navigate(to: nextScreen)
        } else {
            completionDelegate?.completionNotifyingDidComplete(self)
        }
    }

    private func navigate(to screen: ServiceScreen) {
        screenStack.append(screen)
        let viewController = viewControllerForScreen(screen)
        pushViewController(viewController, animated: true)
    }

    private func completeLogin() {
        if let service = service {
            service.completeOnboard()
            serviceOnboardingDelegate?.serviceOnboarding(didOnboardService: service)
        }
        stepFinished()
    }

    private func completeLogout() {
        self.service?.completeDelete()
        self.service = nil
        stepFinished()
    }
}

extension ServiceUICoordinator: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // Pop the current screen from the stack if we're navigating back
        while viewControllers.count < screenStack.count {
            screenStack.removeLast()
        }
    }
}
