//
//  ViewController.swift
//  SpotItApp
//
//  Created by Natasha Rao on 10/28/19.
//  Copyright © 2019 Natasha Rao. All rights reserved.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {
    
    var loginSuccess = false
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var passwordLabel: UILabel!
    
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if let ident = identifier {
            if ident == "SignIn" {
                if loginSuccess != true {
                    return false
                }
            }
        }
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.statusLabel.textColor = UIColor.white
        // if user is already logged in push the signin segue instead
        if let _ = Auth.auth().currentUser {
            DispatchQueue.main.async {
               self.performSegue(withIdentifier: "SignIn", sender: self)
                
            }
           
        }
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func signInButton(_ sender: Any) {
        let email = emailInput.text!
        let password = passwordInput.text!
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
          guard let strongSelf = self else { return }
            if (error != nil) {
                strongSelf.statusLabel.text = "Error: Please check username and password."
                self!.statusLabel.textColor = UIColor.red
                print(error)
                self?.loginSuccess = false
                return
            }
            strongSelf.statusLabel.text = ""
            self?.loginSuccess = true
        }
    }
    
    
    
}

