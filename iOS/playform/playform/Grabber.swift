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
            //print(value)
            for thing in value!{
                //print(thing.key)
                if let hello = thing.value as? NSDictionary{
                    for what in hello{
                        self.recentDict?.setValue(what.value, forKey: thing.key as! String)
                        print(thing.key)
                        print(what.value)
                        print("\n\n\n\n\n\n")
                    }
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func putData(url: URL, category: String){
        let filepath = category + url.lastPathComponent
        
        self.storageRef.child(category).child(url.lastPathComponent)
            .putFile(url, metadata: nil) { (metadata, error) in
                
                
                var str = url.lastPathComponent
                
                let start = str.startIndex
                let end = str.index(str.endIndex, offsetBy: -4)
                let range = start..<end
                
                
                let post = [str.substring(with: range):metadata?.downloadURL()?.absoluteString]
                self.dbRef.child("Events").child(category).updateChildValues(post)
                
                if let error = error {
                    print("Error uploading: \(error)")
                    return
                }
        }        
    }
}
