//
//  ViewController.swift
//  Bric
//
//  Created by Dawood Khan on 10/28/16.
//  Copyright © 2016 Dawood Khan. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore
import FacebookShare
import Google
import GoogleSignIn

class ViewController: UIViewController, GIDSignInUIDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        
        //Facebook login
        let loginButton = LoginButton(readPermissions: [ .publicProfile ])
        loginButton.center = view.center
        
        view.addSubview(loginButton)
        
        print(AccessToken.current)
        
        if AccessToken.current != nil {
            // User is logged in, use 'accessToken' here.
            let vc = MainViewController()
            self.present(vc, animated: true, completion: nil)
        }
    
        //Google Sign in
        GIDSignIn.sharedInstance().uiDelegate = self
        
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            //User is logged in, use 'accessToken' here.
            let vc = MainViewController()
            self.present(vc, animated: true, completion: nil)
        }
        
        
        // Uncomment to automatically sign in the user.
        //GIDSignIn.sharedInstance().signInSilently()
        
        // TODO(developer) Configure the sign-in button look/feel
        // ...
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

