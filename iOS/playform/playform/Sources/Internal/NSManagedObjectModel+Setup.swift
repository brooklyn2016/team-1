//
//  NSManagedObjectModel+Setup.swift
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


// MARK: - NSManagedObjectModel

internal extension NSManagedObjectModel {
    
    // MARK: Internal
    
    @nonobjc
    internal static func fromBundle(_ bundle: Bundle, modelName: String, modelVersionHints: Set<String> = []) -> NSManagedObjectModel {
        
        guard let modelFilePath = bundle.path(forResource: modelName, ofType: "momd") else {
            
            // For users migrating from very old Xcode versions: Old xcdatamodel files are not contained inside xcdatamodeld (with a "d"), and will thus fail this check. If that was the case, create a new xcdatamodeld file and copy all contents into the new model.
            CoreStore.abort("Could not find \"\(modelName).momd\" from the bundle. \(bundle)")
        }
        
        let modelFileURL = URL(fileURLWithPath: modelFilePath)
        let versionInfoPlistURL = modelFileURL.appendingPathComponent("VersionInfo.plist", isDirectory: false)
        
        guard let versionInfo = NSDictionary(contentsOf: versionInfoPlistURL),
            let versionHashes = versionInfo["NSManagedObjectModel_VersionHashes"] as? [String: AnyObject] else {
                
                CoreStore.abort("Could not load \(cs_typeName(NSManagedObjectModel.self)) metadata from path \"\(versionInfoPlistURL)\".")
        }
        
        let modelVersions = Set(versionHashes.keys)
        let currentModelVersion: String
        if let plistModelVersion = versionInfo["NSManagedObjectModel_CurrentVersionName"] as? String,
            modelVersionHints.isEmpty || modelVersionHints.contains(plistModelVersion) {
            
            currentModelVersion = plistModelVersion
        }
        else if let resolvedVersion = modelVersions.intersection(modelVersionHints).first {
            
            CoreStore.log(
                .warning,
                message: "The MigrationChain leaf versions do not include the model file's current version. Resolving to version \"\(resolvedVersion)\"."
            )
            currentModelVersion = resolvedVersion
        }
        else if let resolvedVersion = modelVersions.first ?? modelVersionHints.first {
            
            if !modelVersionHints.isEmpty {
                
                CoreStore.log(
                    .warning,
                    message: "The MigrationChain leaf versions do not include any of the model file's embedded versions. Resolving to version \"\(resolvedVersion)\"."
                )
            }
            currentModelVersion = resolvedVersion
        }
        else {
            
            CoreStore.abort("No model files were found in URL \"\(modelFileURL)\".")
        }
        
        var modelVersionFileURL: URL?
        for modelVersion in modelVersions {
            
            let fileURL = modelFileURL.appendingPathComponent("\(modelVersion).mom", isDirectory: false)
            
            if modelVersion == currentModelVersion {
                
                modelVersionFileURL = fileURL
                continue
            }
            
            precondition(
                NSManagedObjectModel(contentsOf: fileURL) != nil,
                "Could not find the \"\(modelVersion).mom\" version file for the model at URL \"\(modelFileURL)\"."
            )
        }
        
        if let modelVersionFileURL = modelVersionFileURL,
            let rootModel = NSManagedObjectModel(contentsOf: modelVersionFileURL) {
                
                rootModel.modelVersionFileURL = modelVersionFileURL
                rootModel.modelVersions = modelVersions
                rootModel.currentModelVersion = currentModelVersion
                return rootModel
        }
        
        CoreStore.abort("Could not create an \(cs_typeName(NSManagedObjectModel.self)) from the model at URL \"\(modelFileURL)\".")
    }
    
    @nonobjc
    internal private(set) var currentModelVersion: String? {
        
        get {
            
            let value: NSString? = cs_getAssociatedObjectForKey(
                &PropertyKeys.currentModelVersion,
                inObject: self
            )
            return value as? String
        }
        set {
            
            cs_setAssociatedCopiedObject(
                newValue == nil ? nil : (newValue! as NSString),
                forKey: &PropertyKeys.currentModelVersion,
                inObject: self
            )
        }
    }
    
    @nonobjc
    internal private(set) var modelVersions: Set<String>? {
        
        get {
            
            let value: NSSet? = cs_getAssociatedObjectForKey(
                &PropertyKeys.modelVersions,
                inObject: self
            )
            return value as? Set<String>
        }
        set {
            
            cs_setAssociatedCopiedObject(
                newValue == nil ? nil : (newValue! as NSSet),
                forKey: &PropertyKeys.modelVersions,
                inObject: self
            )
        }
    }
    
    @nonobjc
    internal func entityNameForClass(_ entityClass: AnyClass) -> String {
        
        return self.entityNameMapping[NSStringFromClass(entityClass)]!
    }
    
    @nonobjc
    internal func entityTypesMapping() -> [String: NSManagedObject.Type] {
        
        var mapping = [String: NSManagedObject.Type]()
        self.entityNameMapping.forEach { (className, entityName) in
            
            mapping[entityName] = (NSClassFromString(className)! as! NSManagedObject.Type)
        }
        return mapping
    }
    
    @nonobjc
    internal func mergedModels() -> [NSManagedObjectModel] {
        
        return self.modelVersions?.map { self[$0] }.flatMap { $0 == nil ? [] : [$0!] } ?? [self]
    }
    
    @nonobjc
    internal subscript(modelVersion: String) -> NSManagedObjectModel? {
        
        if modelVersion == self.currentModelVersion {
            
            return self
        }
        
        guard let modelFileURL = self.modelFileURL,
            let modelVersions = self.modelVersions,
            modelVersions.contains(modelVersion) else {
                
                return nil
        }
        
        let versionModelFileURL = modelFileURL.appendingPathComponent("\(modelVersion).mom", isDirectory: false)
        guard let model = NSManagedObjectModel(contentsOf: versionModelFileURL) else {
            
            return nil
        }
        
        model.currentModelVersion = modelVersion
        model.modelVersionFileURL = versionModelFileURL
        model.modelVersions = modelVersions
        return model
    }
    
    @nonobjc
    internal subscript(metadata: [String: Any]) -> NSManagedObjectModel? {
        
        guard let modelHashes = metadata[NSStoreModelVersionHashesKey] as? [String : Data] else {
            
            return nil
        }
        for modelVersion in self.modelVersions ?? [] {
            
            if let versionModel = self[modelVersion], modelHashes == versionModel.entityVersionHashesByName {
                
                return versionModel
            }
        }
        return nil
    }
    
    
    // MARK: Private
    
    @nonobjc
    private var modelFileURL: URL? {
        
        get {
            
            return self.modelVersionFileURL?.deletingLastPathComponent()
        }
    }
    
    @nonobjc
    private var modelVersionFileURL: URL? {
        
        get {
            
            let value: NSURL? = cs_getAssociatedObjectForKey(
                &PropertyKeys.modelVersionFileURL,
                inObject: self
            )
            return value as URL?
        }
        set {
            
            cs_setAssociatedCopiedObject(
                newValue as NSURL?,
                forKey: &PropertyKeys.modelVersionFileURL,
                inObject: self
            )
        }
    }
    
    @nonobjc
    private var entityNameMapping: [String: String] {
        
        get {
            
            if let mapping: NSDictionary = cs_getAssociatedObjectForKey(&PropertyKeys.entityNameMapping, inObject: self) {
                
                return mapping as! [String: String]
            }
            
            var mapping = [String: String]()
            self.entities.forEach {
                
                guard let entityName = $0.name else {
                    
                    return
                }
                
                let className = $0.managedObjectClassName
                mapping[className!] = entityName
            }
            cs_setAssociatedCopiedObject(
                mapping as NSDictionary,
                forKey: &PropertyKeys.entityNameMapping,
                inObject: self
            )
            return mapping
        }
    }
    
    private struct PropertyKeys {
        
        static var entityNameMapping: Void?
        
        static var modelVersionFileURL: Void?
        static var modelVersions: Void?
        static var currentModelVersion: Void?
    }
}
