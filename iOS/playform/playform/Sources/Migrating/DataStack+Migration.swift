//
//  DataStack+Migration.swift
//  CoreStore
//
//  Copyright © 2015 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import CoreData


// MARK: - DataStack

public extension DataStack {
    
    /**
     Asynchronously adds a `StorageInterface` with default settings to the stack. Migrations are also initiated by default.
     ```
     dataStack.addStorage(
         InMemoryStore.self,
         completion: { result in
             switch result {
             case .success(let storage): // ...
             case .failure(let error): // ...
             }
         }
     )
     ```
     - parameter storeType: the storage type
     - parameter completion: the closure to be executed on the main queue when the process completes, either due to success or failure. The closure's `SetupResult` argument indicates the result. Note that the `StorageInterface` associated to the `SetupResult.success` may not always be the same instance as the parameter argument if a previous `StorageInterface` was already added at the same URL and with the same configuration.
     */
    public func addStorage<T: StorageInterface>(_ storeType: T.Type, completion: @escaping (SetupResult<T>) -> Void) where T: DefaultInitializableStore {
        
        self.addStorage(storeType.init(), completion: completion)
    }
    
    /**
     Asynchronously adds a `StorageInterface` to the stack. Migrations are also initiated by default.
     ```
     dataStack.addStorage(
         InMemoryStore(configuration: "Config1"),
         completion: { result in
             switch result {
             case .success(let storage): // ...
             case .failure(let error): // ...
             }
         }
     )
     ```
     - parameter storage: the storage
     - parameter completion: the closure to be executed on the main queue when the process completes, either due to success or failure. The closure's `SetupResult` argument indicates the result. Note that the `StorageInterface` associated to the `SetupResult.success` may not always be the same instance as the parameter argument if a previous `StorageInterface` was already added at the same URL and with the same configuration.
     */
    public func addStorage<T: StorageInterface>(_ storage: T, completion: @escaping (SetupResult<T>) -> Void) {
        
        self.coordinator.performAsynchronously {
            
            if let _ = self.persistentStoreForStorage(storage) {
                
                DispatchQueue.main.async {
                    
                    completion(SetupResult(storage))
                }
                return
            }
            
            do {
                
                _ = try self.createPersistentStoreFromStorage(
                    storage,
                    finalURL: nil,
                    finalStoreOptions: storage.storeOptions
                )
                
                DispatchQueue.main.async {
                    
                    completion(SetupResult(storage))
                }
            }
            catch {
                
                let storeError = CoreStoreError(error)
                CoreStore.log(
                    storeError,
                    "Failed to add \(cs_typeName(storage)) to the stack."
                )
                DispatchQueue.main.async {
                    
                    completion(SetupResult(storeError))
                }
            }
        }
    }
    
    /**
     Asynchronously adds a `LocalStorage` with default settings to the stack. Migrations are also initiated by default.
     ```
     let migrationProgress = dataStack.addStorage(
         SQLiteStore.self,
         completion: { result in
             switch result {
             case .success(let storage): // ...
             case .failure(let error): // ...
             }
         }
     )
     ```
     - parameter storeType: the local storage type
     - parameter completion: the closure to be executed on the main queue when the process completes, either due to success or failure. The closure's `SetupResult` argument indicates the result. Note that the `LocalStorage` associated to the `SetupResult.success` may not always be the same instance as the parameter argument if a previous `LocalStorage` was already added at the same URL and with the same configuration.
     - returns: an `NSProgress` instance if a migration has started, or `nil` if either no migrations are required or if a failure occured.
     */
    public func addStorage<T: LocalStorage>(_ storeType: T.Type, completion: @escaping (SetupResult<T>) -> Void) -> Progress? where T: DefaultInitializableStore {
        
        return self.addStorage(storeType.init() as! T.Type, completion: completion)
    }
    
    /**
     Asynchronously adds a `LocalStorage` to the stack. Migrations are also initiated by default.
     ```
     let migrationProgress = dataStack.addStorage(
         SQLiteStore(fileName: "core_data.sqlite", configuration: "Config1"),
         completion: { result in
             switch result {
             case .success(let storage): // ...
             case .failure(let error): // ...
             }
         }
     )
     ```
     - parameter storage: the local storage
     - parameter completion: the closure to be executed on the main queue when the process completes, either due to success or failure. The closure's `SetupResult` argument indicates the result. Note that the `LocalStorage` associated to the `SetupResult.success` may not always be the same instance as the parameter argument if a previous `LocalStorage` was already added at the same URL and with the same configuration.
     - returns: an `NSProgress` instance if a migration has started, or `nil` if either no migrations are required or if a failure occured.
     */
    public func addStorage<T: LocalStorage>(_ storage: T, completion: @escaping (SetupResult<T>) -> Void) -> Progress? {
        
        let fileURL = storage.fileURL
        CoreStore.assert(
            fileURL.isFileURL,
            "The specified URL for the \(cs_typeName(storage)) is invalid: \"\(fileURL)\""
        )
        
        return self.coordinator.performSynchronously {
            
            if let _ = self.persistentStoreForStorage(storage) {
                
                DispatchQueue.main.async {
                    
                    completion(SetupResult(storage))
                }
                return nil
            }
            
            if let persistentStore = self.coordinator.persistentStore(for: fileURL as URL) {
                
                if let existingStorage = persistentStore.storageInterface as? T,
                    storage.matchesPersistentStore(persistentStore) {
                    
                    DispatchQueue.main.async {
                        
                        completion(SetupResult(existingStorage))
                    }
                    return nil
                }
                
                let error = CoreStoreError.differentStorageExistsAtURL(existingPersistentStoreURL: fileURL)
                CoreStore.log(
                    error,
                    "Failed to add \(cs_typeName(storage)) at \"\(fileURL)\" because a different \(cs_typeName(NSPersistentStore.self)) at that URL already exists."
                )
                DispatchQueue.main.async {
                    
                    completion(SetupResult(error))
                }
                return nil
            }
            
            do {
                
                try FileManager.default.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                
                let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                    ofType: type(of: storage).storeType,
                    at: fileURL as URL,
                    options: storage.storeOptions
                )
                
                return self.upgradeStorageIfNeeded(
                    storage,
                    metadata: metadata,
                    completion: { (result) -> Void in
                        
                        if case .failure(.internalError(let error)) = result {
                            
                            if storage.localStorageOptions.contains(.recreateStoreOnModelMismatch) && error.isCoreDataMigrationError {
                                
                                do {
                                    
                                    _ = try self.model[metadata].flatMap(storage.eraseStorageAndWait)
                                    _ = try self.addStorageAndWait(storage)
                                    
                                    DispatchQueue.main.async {
                                        
                                        completion(SetupResult(storage))
                                    }
                                }
                                catch {
                                    
                                    completion(SetupResult(error))
                                }
                                return
                            }
                            
                            completion(SetupResult(error))
                            return
                        }
                        
                        do {
                            
                            _ = try self.addStorageAndWait(storage)
                            
                            completion(SetupResult(storage))
                        }
                        catch {
                            
                            completion(SetupResult(error))
                        }
                    }
                )
            }
            catch let error as NSError
                where error.code == NSFileReadNoSuchFileError && error.domain == NSCocoaErrorDomain {
                    
                    do {
                        
                        _ = try self.addStorageAndWait(storage)
                        
                        DispatchQueue.main.async {
                            
                            completion(SetupResult(storage))
                        }
                    }
                    catch {
                        
                        DispatchQueue.main.async {
                            
                            completion(SetupResult(error))
                        }
                    }
                    return nil
            }
            catch {
                
                let storeError = CoreStoreError(error)
                CoreStore.log(
                    storeError,
                    "Failed to load SQLite \(cs_typeName(NSPersistentStore.self)) metadata."
                )
                DispatchQueue.main.async {
                    
                    completion(SetupResult(storeError))
                }
                return nil
            }
        }
    }
    
    /**
     Asynchronously adds a `CloudStorage` to the stack. Migrations are also initiated by default.
     ```
     guard let storage = ICloudStore(
         ubiquitousContentName: "MyAppCloudData",
         ubiquitousContentTransactionLogsSubdirectory: "logs/config1",
         ubiquitousContainerID: "iCloud.com.mycompany.myapp.containername",
         ubiquitousPeerToken: "9614d658014f4151a95d8048fb717cf0",
         configuration: "Config1",
         cloudStorageOptions: .recreateLocalStoreOnModelMismatch
     ) else {
         // iCloud is not available on the device
         return
     }
     dataStack.addStorage(
         storage,
         completion: { result in
             switch result {
             case .success(let storage): // ...
             case .failure(let error): // ...
             }
         }
     )
     ```
     - parameter storage: the cloud storage
     - parameter completion: the closure to be executed on the main queue when the process completes, either due to success or failure. The closure's `SetupResult` argument indicates the result. Note that the `CloudStorage` associated to the `SetupResult.success` may not always be the same instance as the parameter argument if a previous `CloudStorage` was already added at the same URL and with the same configuration.
     */
    public func addStorage<T: CloudStorage>(_ storage: T, completion: @escaping (SetupResult<T>) -> Void)  {
        
        let cacheFileURL = storage.cacheFileURL
        self.coordinator.performSynchronously {
            
            if let _ = self.persistentStoreForStorage(storage) {
                
                DispatchQueue.main.async {
                    
                    completion(SetupResult(storage))
                }
                return
            }
            
            if let persistentStore = self.coordinator.persistentStore(for: cacheFileURL as URL) {
                
                if let existingStorage = persistentStore.storageInterface as? T,
                    storage.matchesPersistentStore(persistentStore) {
                    
                    DispatchQueue.main.async {
                        
                        completion(SetupResult(existingStorage))
                    }
                    return
                }
                
                let error = CoreStoreError.differentStorageExistsAtURL(existingPersistentStoreURL: cacheFileURL)
                CoreStore.log(
                    error,
                    "Failed to add \(cs_typeName(storage)) at \"\(cacheFileURL)\" because a different \(cs_typeName(NSPersistentStore.self)) at that URL already exists."
                )
                DispatchQueue.main.async {
                    
                    completion(SetupResult(error))
                }
                return
            }
            
            do {
                
                var cloudStorageOptions = storage.cloudStorageOptions
                cloudStorageOptions.remove(.recreateLocalStoreOnModelMismatch)
                
                let storeOptions = storage.dictionary(forOptions: cloudStorageOptions)
                do {
                    
                    try FileManager.default.createDirectory(
                        at: cacheFileURL.deletingLastPathComponent(),
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    _ = try self.createPersistentStoreFromStorage(
                        storage,
                        finalURL: cacheFileURL,
                        finalStoreOptions: storeOptions
                    )
                    DispatchQueue.main.async {
                        
                        completion(SetupResult(storage))
                    }
                }
                catch let error as NSError where storage.cloudStorageOptions.contains(.recreateLocalStoreOnModelMismatch) && error.isCoreDataMigrationError {
                    
                    let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                        ofType: type(of: storage).storeType,
                        at: cacheFileURL,
                        options: storeOptions
                    )
                    _ = try self.model[metadata].flatMap(storage.eraseStorageAndWait)
                    _ = try self.createPersistentStoreFromStorage(
                        storage,
                        finalURL: cacheFileURL,
                        finalStoreOptions: storeOptions
                    )
                }
            }
            catch let error as NSError
                where error.code == NSFileReadNoSuchFileError && error.domain == NSCocoaErrorDomain {
                    
                    do {
                        
                        _ = try self.addStorageAndWait(storage)
                        
                        DispatchQueue.main.async {
                            
                            completion(SetupResult(storage))
                        }
                    }
                    catch {
                        
                        DispatchQueue.main.async {
                            
                            completion(SetupResult(error))
                        }
                    }
            }
            catch {
                
                let storeError = CoreStoreError(error)
                CoreStore.log(
                    storeError,
                    "Failed to load \(cs_typeName(NSPersistentStore.self)) metadata."
                )
                DispatchQueue.main.async {
                    
                    completion(SetupResult(storeError))
                }
            }
        }
    }
    
    /**
     Migrates a local storage to match the `DataStack`'s managed object model version. This method does NOT add the migrated store to the data stack.
     
     - parameter storage: the local storage
     - parameter completion: the closure to be executed on the main queue when the migration completes, either due to success or failure. The closure's `MigrationResult` argument indicates the result.
     - throws: a `CoreStoreError` value indicating the failure
     - returns: an `NSProgress` instance if a migration has started, or `nil` is no migrations are required
     */
    public func upgradeStorageIfNeeded<T: LocalStorage>(_ storage: T, completion: @escaping (MigrationResult) -> Void) throws -> Progress? {
        
        return try self.coordinator.performSynchronously {
            
            let fileURL = storage.fileURL
            do {
                
                CoreStore.assert(
                    self.persistentStoreForStorage(storage) == nil,
                    "Attempted to migrate an already added \(cs_typeName(storage)) at URL \"\(fileURL)\""
                )
                
                let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                    ofType: type(of: storage).storeType,
                    at: fileURL as URL,
                    options: storage.storeOptions
                )
                return self.upgradeStorageIfNeeded(
                    storage,
                    metadata: metadata,
                    completion: completion
                )
            }
            catch {
                
                let metadataError = CoreStoreError(error)
                CoreStore.log(
                    metadataError,
                    "Failed to load \(cs_typeName(storage)) metadata from URL \"\(fileURL)\"."
                )
                throw metadataError
            }
        }
    }
    
    /**
     Checks the migration steps required for the storage to match the `DataStack`'s managed object model version.
     
     - parameter storage: the local storage
     - throws: a `CoreStoreError` value indicating the failure
     - returns: a `MigrationType` array indicating the migration steps required for the store, or an empty array if the file does not exist yet. Otherwise, an error is thrown if either inspection of the store failed, or if no mapping model was found/inferred.
     */
    public func requiredMigrationsForStorage<T: LocalStorage>(_ storage: T) throws -> [MigrationType] {
        
        return try self.coordinator.performSynchronously {
            
            let fileURL = storage.fileURL
            
            CoreStore.assert(
                self.persistentStoreForStorage(storage) == nil,
                "Attempted to query required migrations for an already added \(cs_typeName(storage)) at URL \"\(fileURL)\""
            )
            do {
                
                let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                    ofType: type(of: storage).storeType,
                    at: fileURL as URL,
                    options: storage.storeOptions
                )
                
                guard let migrationSteps = self.computeMigrationFromStorage(storage, metadata: metadata) else {
                    
                    let error = CoreStoreError.mappingModelNotFound(
                        localStoreURL: fileURL,
                        targetModel: self.model,
                        targetModelVersion: self.modelVersion
                    )
                    CoreStore.log(
                        error,
                        "Failed to find migration steps from the \(cs_typeName(storage)) at URL \"\(fileURL)\" to version model \"\(self.modelVersion)\"."
                    )
                    throw error
                }
                
                if migrationSteps.count > 1 && storage.localStorageOptions.contains(.preventProgressiveMigration) {
                    
                    let error = CoreStoreError.progressiveMigrationRequired(localStoreURL: fileURL)
                    CoreStore.log(
                        error,
                        "Failed to find migration mapping from the \(cs_typeName(storage)) at URL \"\(fileURL)\" to version model \"\(self.modelVersion)\" without requiring progessive migrations."
                    )
                    throw error
                }
                
                return migrationSteps.map { $0.migrationType }
            }
            catch let error as NSError
                where error.code == NSFileReadNoSuchFileError && error.domain == NSCocoaErrorDomain {
                    
                    return []
            }
            catch {
                
                let metadataError = CoreStoreError(error)
                CoreStore.log(
                    metadataError,
                    "Failed to load \(cs_typeName(storage)) metadata from URL \"\(fileURL)\"."
                )
                throw metadataError
            }
        }
    }
    
    
    // MARK: Private
    
    private func upgradeStorageIfNeeded<T: LocalStorage>(_ storage: T, metadata: [String: Any], completion: @escaping (MigrationResult) -> Void) -> Progress? {
        
        guard let migrationSteps = self.computeMigrationFromStorage(storage, metadata: metadata) else {
            
            let error = CoreStoreError.mappingModelNotFound(
                localStoreURL: storage.fileURL,
                targetModel: self.model,
                targetModelVersion: self.modelVersion
            )
            CoreStore.log(
                error,
                "Failed to find migration steps from \(cs_typeName(storage)) at URL \"\(storage.fileURL)\" to version model \"\(self.model)\"."
            )
            
            DispatchQueue.main.async {
                
                completion(MigrationResult(error))
            }
            return nil
        }
        
        let numberOfMigrations: Int64 = Int64(migrationSteps.count)
        if numberOfMigrations == 0 {
            
            DispatchQueue.main.async {
                
                completion(MigrationResult([]))
                return
            }
            return nil
        }
        else if numberOfMigrations > 1 && storage.localStorageOptions.contains(.preventProgressiveMigration) {
            
            let error = CoreStoreError.progressiveMigrationRequired(localStoreURL: storage.fileURL)
            CoreStore.log(
                error,
                "Failed to find migration mapping from the \(cs_typeName(storage)) at URL \"\(storage.fileURL)\" to version model \"\(self.modelVersion)\" without requiring progessive migrations."
            )
            DispatchQueue.main.async {
                
                completion(MigrationResult(error))
            }
            return nil
        }
        
        let migrationTypes = migrationSteps.map { $0.migrationType }
        var migrationResult: MigrationResult?
        var operations = [Operation]()
        var cancelled = false
        
        let progress = Progress(parent: nil, userInfo: nil)
        progress.totalUnitCount = numberOfMigrations
        
        for (sourceModel, destinationModel, mappingModel, _) in migrationSteps {
            
            progress.becomeCurrent(withPendingUnitCount: 1)
            
            let childProgress = Progress(parent: progress, userInfo: nil)
            childProgress.totalUnitCount = 100
            
            operations.append(
                BlockOperation { [weak self] in
                    
                    guard let `self` = self, !cancelled else {
                        
                        return
                    }
                    
                    autoreleasepool {
                        
                        do {
                            
                            try self.startMigrationForStorage(
                                storage,
                                sourceModel: sourceModel,
                                destinationModel: destinationModel,
                                mappingModel: mappingModel,
                                progress: childProgress
                            )
                        }
                        catch {
                            
                            migrationResult = MigrationResult(error)
                            cancelled = true
                        }
                    }
                    
                    DispatchQueue.main.async {
                        
                        _ = withExtendedLifetime(childProgress) { (_: Progress) -> Void in }
                    }
                }
            )
            
            progress.resignCurrent()
        }
        
        let migrationOperation = BlockOperation()
        migrationOperation.qualityOfService = .utility
        operations.forEach { migrationOperation.addDependency($0) }
        migrationOperation.addExecutionBlock { () -> Void in
            
            DispatchQueue.main.async {
                
                progress.setProgressHandler(nil)
                completion(migrationResult ?? MigrationResult(migrationTypes))
                return
            }
        }
        
        operations.append(migrationOperation)
        
        self.migrationQueue.addOperations(operations, waitUntilFinished: false)
        
        return progress
    }
    
    private func computeMigrationFromStorage<T: LocalStorage>(_ storage: T, metadata: [String: Any]) -> [(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel, mappingModel: NSMappingModel, migrationType: MigrationType)]? {
        
        let model = self.model
        if model.isConfiguration(withName: storage.configuration, compatibleWithStoreMetadata: metadata) {
            
            return []
        }
        
        guard let initialModel = model[metadata],
            var currentVersion = initialModel.currentModelVersion else {
                
                return nil
        }
        
        let migrationChain: MigrationChain = self.migrationChain.empty
            ? [currentVersion: model.currentModelVersion!]
            : self.migrationChain
        
        var migrationSteps = [(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel, mappingModel: NSMappingModel, migrationType: MigrationType)]()
        
        while let nextVersion = migrationChain.nextVersionFrom(currentVersion),
            let sourceModel = model[currentVersion],
            sourceModel != model,
            let destinationModel = model[nextVersion] {
                
                if let mappingModel = NSMappingModel(
                    from: storage.mappingModelBundles,
                    forSourceModel: sourceModel,
                    destinationModel: destinationModel) {
                    
                    migrationSteps.append(
                        (
                            sourceModel: sourceModel,
                            destinationModel: destinationModel,
                            mappingModel: mappingModel,
                            migrationType: .heavyweight(
                                sourceVersion: currentVersion,
                                destinationVersion: nextVersion
                            )
                        )
                    )
                }
                else {
                    
                    do {
                        
                        let mappingModel = try NSMappingModel.inferredMappingModel(
                            forSourceModel: sourceModel,
                            destinationModel: destinationModel
                        )
                        
                        migrationSteps.append(
                            (
                                sourceModel: sourceModel,
                                destinationModel: destinationModel,
                                mappingModel: mappingModel,
                                migrationType: .lightweight(
                                    sourceVersion: currentVersion,
                                    destinationVersion: nextVersion
                                )
                            )
                        )
                    }
                    catch {
                        
                        return nil
                    }
                }
                currentVersion = nextVersion
        }
        
        if migrationSteps.last?.destinationModel == model {
            
            return migrationSteps
        }
        
        return nil
    }
    
    private func startMigrationForStorage<T: LocalStorage>(_ storage: T, sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel, mappingModel: NSMappingModel, progress: Progress) throws {
        
        let fileURL = storage.fileURL
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.CoreStore.DataStack")
            .appendingPathComponent(ProcessInfo().globallyUniqueString)
        
        let fileManager = FileManager.default
        try! fileManager.createDirectory(
            at: temporaryDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(
            fileURL.lastPathComponent,
            isDirectory: false
        )
        
        let migrationManager = MigrationManager(
            sourceModel: sourceModel,
            destinationModel: destinationModel,
            progress: progress
        )
        
        do {
            
            try migrationManager.migrateStore(
                from: fileURL,
                sourceType: type(of: storage).storeType,
                options: nil,
                with: mappingModel,
                toDestinationURL: temporaryFileURL,
                destinationType: type(of: storage).storeType,
                destinationOptions: nil
            )
        }
        catch {
            
            do {
                
                try fileManager.removeItem(at: temporaryFileURL)
            }
            catch _ { }
            
            let sourceVersion = migrationManager.sourceModel.currentModelVersion ?? "???"
            let destinationVersion = migrationManager.destinationModel.currentModelVersion ?? "???"
            let migrationError = CoreStoreError(error)
            CoreStore.log(
                migrationError,
                "Failed to migrate from version model \"\(sourceVersion)\" to version model \"\(destinationVersion)\"."
            )
            
            throw migrationError
        }
        
        do {
            
            try fileManager.replaceItem(
                at: fileURL as URL,
                withItemAt: temporaryFileURL,
                backupItemName: nil,
                options: [],
                resultingItemURL: nil
            )
            
            progress.completedUnitCount = progress.totalUnitCount
        }
        catch {
            
            do {
                
                try fileManager.removeItem(at: temporaryFileURL)
            }
            catch _ { }
            
            let sourceVersion = migrationManager.sourceModel.currentModelVersion ?? "???"
            let destinationVersion = migrationManager.destinationModel.currentModelVersion ?? "???"
            let fileError = CoreStoreError(error)
            CoreStore.log(
                fileError,
                "Failed to save store after migrating from version model \"\(sourceVersion)\" to version model \"\(destinationVersion)\"."
            )
            
            throw fileError
        }
    }
}
