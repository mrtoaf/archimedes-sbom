//
//  ObjectIdCache.swift
//  NightscoutServiceKit
//
//  Created by Pete Schwamb on 9/7/20.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import Foundation

public struct ObjectIDMapping: RawRepresentable, Equatable {
    public typealias RawValue = [String: Any]
    
    var loopSyncIdentifier: String
    var nightscoutObjectId: String
    var createdAt: Date
    
    public init(loopSyncIdentifier: String, nightscoutObjectId: String) {
        self.loopSyncIdentifier = loopSyncIdentifier
        self.nightscoutObjectId = nightscoutObjectId
        self.createdAt = Date()
    }
    
    public init?(rawValue: RawValue) {
        guard let loopSyncIdentifier = rawValue["loopSyncIdentifier"] as? String,
            let nightscoutObjectId = rawValue["nightscoutObjectId"] as? String,
            let createdAt = rawValue["createdAt"] as? Date
        else {
            return nil
        }
        
        self.loopSyncIdentifier = loopSyncIdentifier
        self.nightscoutObjectId = nightscoutObjectId
        self.createdAt = createdAt
    }
        
    public var rawValue: RawValue {
        return [
            "loopSyncIdentifier": loopSyncIdentifier,
            "nightscoutObjectId": nightscoutObjectId,
            "createdAt": createdAt
        ]
    }

}

public struct ObjectIdCache: RawRepresentable, Equatable {
    public typealias RawValue = [String: Any]

    var storageBySyncIdentifier: [String:ObjectIDMapping]

    public init() {
        storageBySyncIdentifier = [:]
    }
        
    mutating func add(syncIdentifier: String, objectId: String) {
        let mapping = ObjectIDMapping(loopSyncIdentifier: syncIdentifier, nightscoutObjectId: objectId)
        storageBySyncIdentifier[syncIdentifier] = mapping
    }
    
    mutating func purge(before date: Date) {
        storageBySyncIdentifier = storageBySyncIdentifier.filter { $0.value.createdAt >= date }
    }
    
    func findObjectIdBySyncIdentifier(_ syncIdentifier: String) -> String? {
        return storageBySyncIdentifier[syncIdentifier]?.nightscoutObjectId
    }
    
    // RawRepresentable
    public init?(rawValue: RawValue) {
        storageBySyncIdentifier = [:]
        
        guard let rawMappings = rawValue["mappings"] as? [ObjectIDMapping.RawValue] else {
            return nil
        }
        
        for rawMapping in rawMappings {
            if let mapping = ObjectIDMapping(rawValue: rawMapping) {
                storageBySyncIdentifier[mapping.loopSyncIdentifier] = mapping
            }
        }
    }
        
    public var rawValue: RawValue {
        return ["mappings": storageBySyncIdentifier.values.map { $0.rawValue }]
    }
}
