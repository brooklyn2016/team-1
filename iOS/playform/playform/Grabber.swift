//
//  Grabber.swift
//  playform
//
//  Created by Rafi Rizwan on 10/29/16.
//  Copyright © 2016 vi66r. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Firebase
import FirebaseAuth
import FirebaseStorage

class Grabber: NSObject {
    var dbRef: FIRDatabaseReference!
    var storageRef: FIRStorageReference!
    var recentDict: NSDictionary?
    
    static let sharedInstance = Grabber()
    
    func start(){
        //Grabber.sharedInstance.recentDict = NSDictionary()
        dbRef = FIRDatabase.database().reference()
        storageRef = FIRStorage.storage().reference()
        Grabber.sharedInstance.grabData()
    }
    
    
    func grabData(){
        dbRef.child("Events").observeSingleEvent(of: .value, with:  { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            print(value)
            for thing in value!{
                //print(thing.key)
                //if let hello = thing.value as? NSDictionary{
                    for what in (thing.value as? NSDictionary)!{
                        self.recentDict?.setValue(what.value, forKey: thing.key as! String)
                        print(thing.key)
                        print(what.value)
                        print("\n\n\n\n\n\n")
                    }
                //}
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func putData(url: URL, category: String){
        
        var meta: FIRStorageMetadata?
        var metaURL: String?
        
        let diceRoll = String(Int(arc4random_uniform(99999999) + 1)) + ".mp4"
        
        self.storageRef.child(category).child(diceRoll)
            .putFile(url, metadata: nil) { (metadata, error) in
                
                meta = metadata
                metaURL = metadata?.downloadURL()?.absoluteString
                print(metaURL)
                
                self.syncData(metaURL: metaURL!, category: category, diceRoll: diceRoll)
                
        }
        
    }
    
    func syncData(metaURL: String, category: String, diceRoll: String){
        let str = diceRoll
        
        let start = str.startIndex
        let end = str.index(str.endIndex, offsetBy: -4)
        let range = start..<end
        
        var post: [AnyHashable : Any]?
        
        
        print(metaURL)
        print("\n\n\n\n\n\n")
        
        self.dbRef.child("Events").child(category).observeSingleEvent(of: .value, with: { (snapshot) in
            var value = snapshot.value as? [AnyHashable : Any]
            print(snapshot)
            
            value?.updateValue(metaURL, forKey: str.substring(with: range))
            
            post = value
            
            print(post)
            
            self.dbRef.child("Events").child(category).updateChildValues(post!)
        })

    }
}
