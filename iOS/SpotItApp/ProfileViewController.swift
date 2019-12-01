//
//  ProfileViewController.swift
//  SpotItApp
//
//  Created by Natasha Rao on 11/19/19.
//  Copyright © 2019 Natasha Rao. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    
    var userName = ""
    @IBOutlet weak var favoriteLocationsField: UILabel!
    
    @IBOutlet weak var topStudyLocationField: UILabel!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    var profilePicture: UIImage!
    
    @IBOutlet weak var nameField: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let user = Auth.auth().currentUser!
        nameField.text =  user.displayName ?? "No Name Provided"
        
        FirebaseService.instance.downloadProfileImage( user: Auth.auth().currentUser!) { (image) in
            DispatchQueue.main.async { [weak self] in
                self?.profileImage.image = image
                self?.profileImage.contentMode = .scaleAspectFit
                //let frameSize = self?.profileImage.bounds.size
              //  self?.profileImage.layer.cornerRadius = (frameSize!.height)/2
               // self?.profileImage.clipsToBounds = true
            }
        }
        self.loadCheckInLocationsForUser(user: user)
        
        //lets observe for any changes that may occur
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeData(_:)), name: Notification.Name.LocationDataChanged, object: nil)
    }
    
    @objc private func didChangeData(_ notification: Notification) {
        //refresh our data
        self.loadCheckInLocationsForUser(user: Auth.auth().currentUser!)
    }
    
    func loadCheckInLocationsForUser(user : User) {
        FirebaseService.instance.fetchCheckInLocations(user: user) { (fLocations) in
            DispatchQueue.main.async {
                guard let favoriteLocations  = fLocations else {
                    // no favorites
                    return
                }
                self.topStudyLocationField.text = "Top Study Location: " + (favoriteLocations.topStudyLocation)
                
                var favoriteLocationsText = ""
                
                for (name,count) in favoriteLocations.summaryItems {
                    favoriteLocationsText = favoriteLocationsText + name + "(\(count))" + "\n"
                }
                
                self.favoriteLocationsField.text = favoriteLocationsText
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


}
