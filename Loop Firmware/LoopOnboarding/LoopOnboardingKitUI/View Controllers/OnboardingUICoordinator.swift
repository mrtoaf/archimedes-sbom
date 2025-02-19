//
//  OnboardingUIController.swift
//  LoopOnboardingKitUI
//
//  Created by Pete Schwamb on 9/7/20.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import os.log
import Foundation
import HealthKit
import SwiftUI
import LoopKit
import LoopKitUI
import NightscoutServiceKit
import LoopSupportKitUI

enum OnboardingScreen: CaseIterable {
    case welcome
    case appleHealth
    case usageDataSharingPreference
    case nightscoutChooser
    case importSettings
    case suspendThresholdInfo
    case suspendThresholdEditor
    case correctionRangeInfo
    case correctionRangeEditor
    case correctionRangePreMealOverrideInfo
    case correctionRangePreMealOverrideEditor
    case carbRatioInfo
    case carbRatioEditor
    case basalRatesInfo
    case basalRatesEditor
    case deliveryLimitsInfo
    case deliveryLimitsEditor
    case insulinSensitivityInfo
    case insulinSensitivityEditor
    case therapySettingsRecap

    func next() -> OnboardingScreen? {
        guard let nextIndex = Self.allCases.firstIndex(where: { $0 == self }).map({ $0 + 1 }),
              nextIndex < Self.allCases.count else {
            return nil
        }
        return Self.allCases[nextIndex]
    }
}

class OnboardingUICoordinator: UINavigationController, CGMManagerOnboarding, PumpManagerOnboarding, ServiceOnboarding, CompletionNotifying {
    public weak var onboardingDelegate: OnboardingDelegate?
    public weak var cgmManagerOnboardingDelegate: CGMManagerOnboardingDelegate?
    public weak var pumpManagerOnboardingDelegate: PumpManagerOnboardingDelegate?
    public weak var serviceOnboardingDelegate: ServiceOnboardingDelegate?
    public weak var completionDelegate: CompletionDelegate?

    private let onboarding: LoopOnboardingUI
    private let onboardingProvider: OnboardingProvider

    private let initialTherapySettings: TherapySettings

    private var nightscoutOnboardingViewController: UIViewController?

    private var importedTherapySettings: TherapySettings?
    private var importedTherapySettingsDate: Date?
    private var shouldUseImportedSettings: Bool = false

    private let displayGlucosePreference: DisplayGlucosePreference
    private let colorPalette: LoopUIColorPalette

    private var screenStack = [OnboardingScreen]()
    private var currentScreen: OnboardingScreen { return screenStack.last! }

    private var service: Service?

    private var therapySettingsViewModel: TherapySettingsViewModel? // Used for keeping track of & updating settings

    private let log = OSLog(category: "OnboardingUICoordinator")

    private static let serviceIdentifier = "NightscoutService"

    init(onboarding: LoopOnboardingUI, onboardingProvider: OnboardingProvider, initialTherapySettings: TherapySettings, displayGlucosePreference: DisplayGlucosePreference, colorPalette: LoopUIColorPalette) {
        self.onboarding = onboarding
        self.onboardingProvider = onboardingProvider
        self.initialTherapySettings = initialTherapySettings
        self.displayGlucosePreference = displayGlucosePreference
        self.colorPalette = colorPalette
        self.service = onboardingProvider.activeServices.first(where: { $0.pluginIdentifier == OnboardingUICoordinator.serviceIdentifier })

        super.init(navigationBarClass: UINavigationBar.self, toolbarClass: UIToolbar.self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        navigationBar.prefersLargeTitles = true // Ensure nav bar text is displayed correctly
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        screenStack = [.welcome]
        let viewController = viewControllerForScreen(currentScreen)
        setViewControllers([viewController], animated: false)
    }

    private func viewControllerForScreen(_ screen: OnboardingScreen) -> UIViewController {
        switch screen {
        case .welcome:
            let view = WelcomeView(didContinue: { [weak self] in
                guard let self = self else {
                    return
                }
                if self.service?.isOnboarded == true {
                    // If the Nightscout service already created and onboarded, then check for available settings import
                    self.checkForAvailableSettingsImport()
                } else {
                    self.stepFinished()
                }
            }, didLongPressOnLogo: {
                self.mockTherapySettingsAndSkipOnboarding()
            })
            return hostingController(rootView: view)
        case .usageDataSharingPreference:
            let view = UsageDataPrivacyPreferenceView(
                preference: LoopKitAnalytics.shared.usageDataPrivacyPreference ?? .shareInstallationStatsOnly,
                onboardingMode: true,
                didChoosePreference: { newPreference in
                    LoopKitAnalytics.shared.updateUsageDataPrivacyPreference(newValue: newPreference)
                },
                didFinish: {
                    self.stepFinished()
                }
            )
            return hostingController(rootView: view)
        case .appleHealth:
            var view = AppleHealthAuthView()
            view.authorizeHealthStore = { [weak self] (completion) in
                self?.onboardingProvider.authorizeHealthStore { auth in
                    DispatchQueue.main.async {
                        completion()
                        self?.stepFinished()
                    }
                }
            }
            return hostingController(rootView: view)

        case .nightscoutChooser:
            let view = OnboardingChooserView(setupWithNightscout: setupWithNightscout, setupWithoutNightscout: setupWithoutNightscout)
            return hostingController(rootView: view)
        case .importSettings:
            let view = ImportSettingsView(settingsDate: importedTherapySettingsDate!) { [weak self] (shouldImport) in
                self?.shouldUseImportedSettings = shouldImport
                self?.stepFinished()
            }
            return hostingController(rootView: view)
        case .suspendThresholdInfo:
            let therapySettings: TherapySettings
            if let importedTherapySettings = importedTherapySettings, shouldUseImportedSettings {
                therapySettings = importedTherapySettings
            } else {
                therapySettings = initialTherapySettings
            }
            therapySettingsViewModel = constructTherapySettingsViewModel(therapySettings: therapySettings)
            let view = SuspendThresholdInformationView(onExit: { [weak self] in self?.stepFinished() })
            return hostingController(rootView: view)
        case .suspendThresholdEditor:
            let view = SuspendThresholdEditor(mode: .acceptanceFlow, therapySettingsViewModel: therapySettingsViewModel!)
            return hostingController(rootView: view)
        case .correctionRangeInfo:
            let view = CorrectionRangeInformationView(onExit: { [weak self] in self?.stepFinished() })
            return hostingController(rootView: view)
        case .correctionRangeEditor:
            // Reset any conflicting entries to allow user to set them to new, non-conflicting values
            therapySettingsViewModel?.therapySettings.resetEntriesConflictingWithSuspendThreshold()
            let view = CorrectionRangeScheduleEditor(mode: .acceptanceFlow, therapySettingsViewModel: therapySettingsViewModel!)
            return hostingController(rootView: view)
        case .correctionRangePreMealOverrideInfo:
            let view = CorrectionRangeOverrideInformationView(preset: .preMeal, onExit: { [weak self] in self?.stepFinished() })
            return hostingController(rootView: view)
        case .correctionRangePreMealOverrideEditor:
            let view = CorrectionRangeOverridesEditor(mode: .acceptanceFlow, therapySettingsViewModel: therapySettingsViewModel!, preset: .preMeal)
            return hostingController(rootView: view)
        case .basalRatesInfo:
            let view = BasalRatesInformationView(onExit: { [weak self] in self?.stepFinished() })
            return hostingController(rootView: view)
        case .basalRatesEditor:
            let view = BasalRateScheduleEditor(mode: .acceptanceFlow, therapySettingsViewModel: therapySettingsViewModel!)
            return hostingController(rootView: view)
        case .deliveryLimitsInfo:
            let view = DeliveryLimitsInformationView(onExit: { [weak self] in self?.stepFinished() })
            return hostingController(rootView: view)
        case .deliveryLimitsEditor:
            let view = DeliveryLimitsEditor(mode: .acceptanceFlow, therapySettingsViewModel: therapySettingsViewModel!)
            return hostingController(rootView: view)
        case .carbRatioInfo:
            let view = CarbRatioInformationView(onExit: { [weak self] in self?.stepFinished() })
            return hostingController(rootView: view)
        case .carbRatioEditor:
            let view = CarbRatioScheduleEditor(mode: .acceptanceFlow, therapySettingsViewModel: therapySettingsViewModel!)
            return hostingController(rootView: view)
        case .insulinSensitivityInfo:
            let view = InsulinSensitivityInformationView(onExit: { [weak self] in self?.stepFinished() })
            return hostingController(rootView: view)
        case .insulinSensitivityEditor:
            let view = InsulinSensitivityScheduleEditor(mode: .acceptanceFlow, therapySettingsViewModel: therapySettingsViewModel!)
            return hostingController(rootView: view)
        case .therapySettingsRecap:
            therapySettingsViewModel?.prescription = nil
            let nextButtonString = LocalizedString("Save Settings", comment: "Therapy settings save button title")
            let actionButton = TherapySettingsView.ActionButton(localizedString: nextButtonString) { [weak self] in
                if let self = self {
                    self.onboarding.therapySettings = self.therapySettingsViewModel?.therapySettings
                    self.onboarding.isOnboarded = true
                    self.stepFinished()
                }
            }
            let view = TherapySettingsView(mode: .acceptanceFlow, viewModel: therapySettingsViewModel!, actionButton: actionButton)
            return hostingController(rootView: view)
        }
    }

    private func hostingController<Content: View>(rootView: Content) -> DismissibleHostingController<some View> {
        let rootView = rootView
            .environmentObject(displayGlucosePreference)
            .environment(\.appName, Bundle.main.bundleDisplayName)
        let hostingController = DismissibleHostingController(content: rootView, colorPalette: colorPalette)
        return hostingController
    }

    private func stepFinished() {
        var nextScreen: OnboardingScreen?

        nextScreen = currentScreen.next()

        if nextScreen == .importSettings && importedTherapySettings == nil {
            // If the next screen is import settings, but we don't have imported settings, skip it
            nextScreen = nextScreen?.next()
        }

        if let nextScreen = nextScreen {
            navigate(to: nextScreen)
        } else {
            exitOnboarding()
        }
    }

    private func exitOnboarding() {
        LoopKitAnalytics.shared.recordAnalyticsEvent("Onboarding Finished", withProperties: nil, outOfSession: false)
        completionDelegate?.completionNotifyingDidComplete(self)
    }

    private func navigate(to screen: OnboardingScreen) {
        var viewControllers = self.viewControllers

        // Remove the Nightscout chooser from the view controller hierarchy if the Nightscout service is fully onboarded
        if currentScreen == .nightscoutChooser && service?.isOnboarded == true {
            screenStack.removeLast()
            viewControllers.removeLast()
        }

        screenStack.append(screen)
        viewControllers.append(viewControllerForScreen(screen))
        setViewControllers(viewControllers, animated: true)
    }

    private func setupWithNightscout() {
        LoopKitAnalytics.shared.recordAnalyticsEvent("Onboarding With Nightscout", withProperties: nil, outOfSession: false)
        switch onboardingProvider.onboardService(withIdentifier: OnboardingUICoordinator.serviceIdentifier) {
        case .failure(let error):
            log.debug("Failure to create and setup service with identifier '%{public}@': %{public}@", OnboardingUICoordinator.serviceIdentifier, String(describing: error))
        case .success(let success):
            switch success {
            case .userInteractionRequired(var setupViewController):
                nightscoutOnboardingViewController = setupViewController
                setupViewController.serviceOnboardingDelegate = self
                setupViewController.completionDelegate = self
                show(setupViewController, sender: self)
            case .createdAndOnboarded(let service):
                self.service = service
                checkForAvailableSettingsImport()
            }
        }
    }

    private func mockTherapySettingsAndSkipOnboarding() {
        onboarding.therapySettings = TherapySettings(
            glucoseTargetRangeSchedule: GlucoseRangeSchedule(
                unit: .milligramsPerDeciliter,
                dailyItems: [.init(startTime: 0, value: DoubleRange(minValue: 105, maxValue: 110))],
                timeZone: .currentFixed),
            correctionRangeOverrides: nil,
            overridePresets: nil,
            maximumBasalRatePerHour: 6.0,
            maximumBolus: 8.0,
            suspendThreshold: GlucoseThreshold(unit: .milligramsPerDeciliter, value: 75),
            insulinSensitivitySchedule: InsulinSensitivitySchedule(
                unit: .milligramsPerDeciliter,
                dailyItems: [.init(startTime: 0, value: 50)],
                timeZone: .currentFixed),
            carbRatioSchedule: CarbRatioSchedule(
                unit: .gram(),
                dailyItems: [.init(startTime: 0, value: 15)],
                timeZone: .currentFixed),
            basalRateSchedule: BasalRateSchedule(
                dailyItems: [.init(startTime: 0, value: 1.2)],
                timeZone: .currentFixed),
            defaultRapidActingModel: ExponentialInsulinModelPreset.rapidActingAdult
            )
        self.onboarding.isOnboarded = true
        exitOnboarding()
    }

    private func setupWithoutNightscout() {
        LoopKitAnalytics.shared.recordAnalyticsEvent("Onboarding Without Nightscout", withProperties: nil, outOfSession: false)
        stepFinished()
    }

    private func checkForAvailableSettingsImport() {
        if let nightscoutService = service as? NightscoutService {
            nightscoutService.fetchStoredTherapySettings { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success((let settings, let date)):
                        self.importedTherapySettings = settings
                        self.importedTherapySettingsDate = date
                        self.navigate(to: .importSettings)
                    case .failure:
                        // TODO: Show error? Maybe user was expecting import option and wants to know why it didn't show.
                        self.stepFinished()
                        break
                    }
                }
            }
        } else {
            stepFinished()
        }
    }


    private func constructTherapySettingsViewModel(therapySettings: TherapySettings) -> TherapySettingsViewModel? {
        return TherapySettingsViewModel(therapySettings: therapySettings, pumpSupportedIncrements: nil, sensitivityOverridesEnabled: true, prescription: nil, delegate: self)
    }
}

extension OnboardingUICoordinator: TherapySettingsViewModelDelegate {
    func syncBasalRateSchedule(items: [RepeatingScheduleValue<Double>], completion: @escaping (Result<BasalRateSchedule, Error>) -> Void) {
        // Since pump isn't set up, this syncing shouldn't do anything
        assertionFailure()
    }
    
    func syncDeliveryLimits(deliveryLimits: DeliveryLimits, completion: @escaping (Result<DeliveryLimits, Error>) -> Void) {
        // Since pump isn't set up, this syncing shouldn't do anything
        assertionFailure()
    }
    
    func saveCompletion(therapySettings: TherapySettings) {
        stepFinished()
    }
    
    func pumpSupportedIncrements() -> PumpSupportedIncrements? {
        let supportedBasalRates = (1...600).map { round(Double($0) / Double(1.0/0.05) * 100.0) / 100.0 }

        let maximumBasalScheduleEntryCount = 24

        let supportedBolusVolumes = (1...600).map { Double($0) / Double(1/0.05) }

        let supportedMaximumBolusVolumes = (1...600).map { Double($0) / Double(1/0.05) }
        
        return PumpSupportedIncrements(
            basalRates: supportedBasalRates,
            bolusVolumes: supportedBolusVolumes,
            maximumBolusVolumes: supportedMaximumBolusVolumes,
            maximumBasalScheduleEntryCount: maximumBasalScheduleEntryCount
        )
    }
}


extension OnboardingUICoordinator: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // Pop the current screen from the stack if we're navigating back
        while viewControllers.count < screenStack.count {
            screenStack.removeLast()
        }
    }
}

extension OnboardingUICoordinator: CGMManagerOnboardingDelegate {
    func cgmManagerOnboarding(didCreateCGMManager cgmManager: CGMManagerUI) {
        cgmManagerOnboardingDelegate?.cgmManagerOnboarding(didCreateCGMManager: cgmManager)
    }

    func cgmManagerOnboarding(didOnboardCGMManager cgmManager: CGMManagerUI) {
        cgmManagerOnboardingDelegate?.cgmManagerOnboarding(didOnboardCGMManager: cgmManager)
    }
}

extension OnboardingUICoordinator: PumpManagerOnboardingDelegate {
    func pumpManagerOnboarding(didCreatePumpManager pumpManager: PumpManagerUI) {
        pumpManagerOnboardingDelegate?.pumpManagerOnboarding(didCreatePumpManager: pumpManager)
    }

    func pumpManagerOnboarding(didOnboardPumpManager pumpManager: PumpManagerUI) {
        pumpManagerOnboardingDelegate?.pumpManagerOnboarding(didOnboardPumpManager: pumpManager)
    }

    func pumpManagerOnboarding(didPauseOnboarding pumpManager: PumpManagerUI) {
    }
}

extension OnboardingUICoordinator: ServiceOnboardingDelegate {
    func serviceOnboarding(didCreateService service: Service) {
        self.service = service
        serviceOnboardingDelegate?.serviceOnboarding(didCreateService: service)
    }

    func serviceOnboarding(didOnboardService service: Service) {
        serviceOnboardingDelegate?.serviceOnboarding(didOnboardService: service)
    }
}

extension OnboardingUICoordinator: CompletionDelegate {
    func completionNotifyingDidComplete(_ object: CompletionNotifying) {
        if let viewController = object as? UIViewController {
            if presentedViewController === viewController {
                dismiss(animated: true, completion: nil)
            } else {
                viewController.dismiss(animated: true, completion: nil)
            }
            if service == nil {
                stepFinished()
            }

            if service!.isOnboarded && viewController == nightscoutOnboardingViewController {
                checkForAvailableSettingsImport()
            }
        }
    }
}

extension TherapySettings {
    // This resets any target ranges that conflict with suspend threshold
    mutating func resetEntriesConflictingWithSuspendThreshold() {
        guard let suspendThreshold = suspendThreshold?.quantity.doubleValue(for: .milligramsPerDeciliter) else {
            return
        }

        if let scheduleLowerBound = glucoseTargetRangeSchedule?.minLowerBound().doubleValue(for: .milligramsPerDeciliter),
            scheduleLowerBound < suspendThreshold
        {
            glucoseTargetRangeSchedule = nil
        }

        if let premealLowerBound = correctionRangeOverrides?.preMeal?.lowerBound.doubleValue(for: .milligramsPerDeciliter),
            premealLowerBound < suspendThreshold
        {
            correctionRangeOverrides?.ranges[.preMeal] = nil
        }

        // workout mode obviated in DIY by overrides
        correctionRangeOverrides?.ranges[.workout] = nil
    }
}
