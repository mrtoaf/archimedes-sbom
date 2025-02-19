//
//  MixpanelService.swift
//  MixpanelServiceKit
//
//  Created by Cameron Ingham on 5/29/23.
//

import Mixpanel
import LoopKit

public final class MixpanelService: Service {

    public static let pluginIdentifier = "MixpanelService"

    public static let localizedTitle = LocalizedString("Mixpanel", comment: "The title of the Mixpanel service")

    public weak var serviceDelegate: ServiceDelegate?

    public weak var stateDelegate: StatefulPluggableDelegate?

    public var token: String?

    private var client: MixpanelInstance?

    public init() {}

    public init?(rawState: RawStateValue) {
        self.token = try? KeychainManager().getMixpanelToken()
        createClient()
    }

    public var rawState: RawStateValue {
        return [:]
    }

    public let isOnboarded = true   // No distinction between created and onboarded

    public var hasConfiguration: Bool { return token?.isEmpty == false }

    public func completeCreate() {
        try! KeychainManager().setMixpanelToken(token)
        createClient()
    }

    public func completeUpdate() {
        try! KeychainManager().setMixpanelToken(token)
        createClient()
        stateDelegate?.pluginDidUpdateState(self)
    }

    public func completeDelete() {
        try! KeychainManager().setMixpanelToken()
        stateDelegate?.pluginWantsDeletion(self)
    }

    private func createClient() {
        if let token = token {
            let mixpanel = Mixpanel.initialize(token: token, trackAutomaticEvents: true)
            client = mixpanel
        } else {
            client = nil
        }
    }

}

extension MixpanelService: AnalyticsService {
    public func recordAnalyticsEvent(_ name: String, withProperties properties: [AnyHashable: Any]?, outOfSession: Bool) {
        client?.track(event: name, properties: mappedProperties(from: properties))
    }

    public func recordIdentify(_ property: String, value: String) {
        client?.people.set(property: property, to: value)
    }
    
    public func recordIdentify(_ property: String, array: [String]) {
        client?.people.set(property: property, to: array)
    }
}

extension KeychainManager {

    func setMixpanelToken(_ mixpanelToken: String? = nil) throws {
        try replaceGenericPassword(mixpanelToken, forService: MixpanelTokenService)
    }

    func getMixpanelToken() throws -> String {
        return try getGenericPasswordForService(MixpanelTokenService)
    }

}

fileprivate let MixpanelTokenService = "MixpanelToken"

private extension MixpanelService {
    func mappedProperties(from properties: [AnyHashable: Any]?) -> [String: MixpanelType] {
        guard let properties else { return [:] }
        var mappedProperties: [String: MixpanelType] = [:]
        
        for (key, value) in properties {
            if let key = key as? String, let value = value as? MixpanelType {
                mappedProperties[key] = value
            }
        }
        
        return mappedProperties
    }
}
