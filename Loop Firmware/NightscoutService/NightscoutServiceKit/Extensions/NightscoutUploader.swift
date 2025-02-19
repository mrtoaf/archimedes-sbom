//
//  NightscoutClient.swift
//  NightscoutServiceKit
//
//  Created by Darin Krauss on 6/20/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import LoopKit
import NightscoutKit

extension NightscoutClient {

    func createCarbData(_ data: [SyncCarbObject], completion: @escaping (Result<[String], Error>) -> Void) {
        guard !data.isEmpty else {
            completion(.success([]))
            return
        }

        upload(data.compactMap { $0.carbCorrectionNightscoutTreatment() }) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let objectIds):
                completion(.success(objectIds))
            }
        }
    }

    func updateCarbData(_ data: [SyncCarbObject], usingObjectIdCache objectIdCache: ObjectIdCache, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard !data.isEmpty else {
            completion(.success(false))
            return
        }
        
        let treatments = data.compactMap { (carbEntry) -> CarbCorrectionNightscoutTreatment? in
            if let syncIdentifier = carbEntry.syncIdentifier, let objectId = objectIdCache.findObjectIdBySyncIdentifier(syncIdentifier) {
                return carbEntry.carbCorrectionNightscoutTreatment(withObjectId: objectId)
            }
            return nil
        }

        modifyTreatments(treatments) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }

    func deleteCarbData(_ data: [SyncCarbObject], usingObjectIdCache objectIdCache: ObjectIdCache, completion: @escaping (Result<Bool, Error>) -> Void) {

        let objectIds = data.compactMap { (carbEntry) -> String? in
            if let syncIdentifier = carbEntry.syncIdentifier {
                return objectIdCache.findObjectIdBySyncIdentifier(syncIdentifier)
            }
            return nil
        }

        guard !objectIds.isEmpty else {
            completion(.success(false))
            return
        }

        deleteTreatmentsByObjectId(objectIds) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }

}

extension NightscoutClient {

    func uploadGlucoseSamples(_ samples: [StoredGlucoseSample], completion: @escaping (Result<Bool, Error>) -> Void) {
        guard !samples.isEmpty else {
            completion(.success(false))
            return
        }

        uploadEntries(samples.compactMap { $0.glucoseEntry }) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(true))
            }
        }
    }

    func uploadCgmEvents(_ data: [PersistedCgmEvent], completion: @escaping (Result<Bool, Error>) -> Void) {
        guard !data.isEmpty else {
            completion(.success(false))
            return
        }

        let source = "loop://\(UIDevice.current.name)"

        let treatments = data.compactMap { (event) -> NightscoutTreatment? in
            return event.treatment(enteredBy: source)
        }

        self.upload(treatments) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(true))
            }
        }
    }
}

extension NightscoutClient {

    func createDoses(_ data: [DoseEntry], usingObjectIdCache objectIdCache: ObjectIdCache, completion: @escaping (Result<[String], Error>) -> Void) {
        guard !data.isEmpty else {
            completion(.success([]))
            return
        }

        let source = "loop://\(UIDevice.current.name)"
        
        let treatments = data.compactMap { (dose) -> NightscoutTreatment? in
            var objectId: String? = nil
            
            if let syncIdentifier = dose.syncIdentifier {
                objectId = objectIdCache.findObjectIdBySyncIdentifier(syncIdentifier)
            }
            
            return dose.treatment(enteredBy: source, withObjectId: objectId)
        }
        
        
        self.upload(treatments) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let objectIds):
                completion(.success(objectIds))
            }
        }
    }

    func deleteDoses(_ data: [DoseEntry], usingObjectIdCache objectIdCache: ObjectIdCache, completion: @escaping (Result<Bool, Error>) -> Void) {

        let objectIds = data.compactMap { (doseEntry) -> String? in
            if let syncIdentifier = doseEntry.syncIdentifier {
                return objectIdCache.findObjectIdBySyncIdentifier(syncIdentifier)
            }
            return nil
        }

        guard !objectIds.isEmpty else {
            completion(.success(false))
            return
        }

        deleteTreatmentsByObjectId(objectIds) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }

}

