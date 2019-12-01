//
//  SignUpViewController.swift
//  SpotItApp
//
//  Created by Natasha Rao on 10/29/19.
//  Copyright © 2019 Natasha Rao. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseAnalytics

class SignUpViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var txtFirstName: UITextField!
    @IBOutlet weak var txtLastName: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var profilePictureButton: RoundButton!
    
    var image: UIImage!
    
    var imagePicker = UIImagePickerController()
    var createUserSuccess = false
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if let ident = identifier {
            if ident == "ProfilePage" {
                if createUserSuccess != true {
                    return false
                }
            }
        }
        return true
    }

    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "ProfilePage" )
        {
            let profilePage = segue.destination as! ProfileViewController
            profilePage.profilePicture = image

        }

    }
    
    @IBAction func addProfilePicture(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            print("Button capture")

            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .savedPhotosAlbum
            self.imagePicker.allowsEditing = true
            

            self.present(self.imagePicker, animated: true, completion: nil)
            
        }
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func signUpButton(_ sender: Any) {
        let email = txtEmail.text!
        let password = txtPassword.text!
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let err = error {
                self.statusLabel.text = "Error"
                print(err)
                self.createUserSuccess = false
                return
            }
            
            self.createUserSuccess = true
            
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            
            changeRequest?.displayName = self.txtFirstName.text! + " " + self.txtLastName.text!
            self.statusLabel.text = "Account Successfully Created!"
            if let img  = self.image {
                FirebaseService.instance.uploadProfileImage(image: img, user: Auth.auth().currentUser!) { (url) in
                    print(url?.absoluteURL ?? "Nil url")
                    if let murl = url {
                        changeRequest?.photoURL = murl
                        changeRequest?.commitChanges(completion: nil)
                        return
                    }
                }
            }
            changeRequest?.commitChanges(completion: nil)
        }
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        image = info[.editedImage] as! UIImage
        
        
        self.dismiss(animated: true, completion: { () -> Void in

        })
        profilePictureButton.setBackgroundImage(image, for: .normal)
        profilePictureButton.layer.cornerRadius = (profilePictureButton.frame.size.height)/2
        profilePictureButton.clipsToBounds = true
        profilePictureButton.setTitle( "" , for: .normal)
    }
    
    
}
