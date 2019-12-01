//
//  CheckInViewController.swift
//  SpotItApp
//
//  Created by Natasha Rao on 10/29/19.
//  Copyright © 2019 Natasha Rao. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
class CheckInViewController: UIViewController {
    
    var locationName = ""
    var capacity = ""
    
    
    @IBOutlet weak var numberOfPeopleField: UILabel!
    @IBOutlet weak var locationAddressField: UILabel!
    @IBOutlet weak var locationNameField: UILabel!
    
    var checkInlocation: SpotitLocation = SpotitLocation.createEmptyLocation()
    var checkInSummary: CheckInSummary?

    @IBOutlet weak var checkInButton: RoundButton!
    @IBOutlet weak var circleImage: UIImageView!
    
    @IBAction func checkedIn(_ sender: UIButton) {
        let user = Auth.auth().currentUser!
        let buttonLabel = sender.titleLabel?.text
        if buttonLabel == "CHECK IN" {
            FirebaseService.instance.checkInToLocation(user: user, location: self.checkInlocation) { () in
                 DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        } else  {
            print("Attempted to Check Out")
            FirebaseService.instance.checkOut(user: Auth.auth().currentUser!, location: checkInlocation) { (result) in
                if result == true {
                    DispatchQueue.main.async {
                         self.navigationController?.popViewController(animated: true)
                    }
                }
             }
        }
    }
    
    func fetchCheckInSummary() {
        FirebaseService.instance.fetchCheckInLocations(user: Auth.auth().currentUser!) { (summary) in
            if let checkInSum = summary {
                self.checkInSummary = checkInSum
                if self.checkInSummary?.currentStudylocation == self.checkInlocation.locId {
                    DispatchQueue.main.async {
                        self.checkInButton.setTitle("CHECK OUT", for: .normal)
                    }
                }
            }
        }
    }
    
    func setCheckInLocation(location: SpotitLocation) {
        checkInlocation = location
        self.setNeedsFocusUpdate()
        self.fetchCheckInSummary()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(locationName)
        print(capacity)
        locationNameField.text = "\(checkInlocation.locationName) (\(checkInlocation.maxOccupancy))"
        numberOfPeopleField.text = "\(checkInlocation.currentOccupancy) number of people checked in"
        circleImage.addShadow()
    }
        // Do any additional setup after loading the view.
}
    
extension UIView {

    func addShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 5
        clipsToBounds = false
    }
}
  

