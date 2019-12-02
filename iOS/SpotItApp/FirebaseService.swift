//
//  FirebaseService.swift
//  SpotItApp
//
//  Created by Natasha Rao on 11/28/19.
//  Copyright © 2019 Natasha Rao. All rights reserved.
//
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import Foundation
import FirebaseFirestoreSwift

//notiofications for our app data
extension Notification.Name {
    static let LocationDataChanged = Notification.Name("LocationDataChanged")
    static let FavoriteDataChanged = Notification.Name("FavoriteDataChanged")
}

struct SpotitLocation {
    var locId : String
    var locationName : String
    var maxOccupancy : Int
    var currentOccupancy : Int
    var geoPoint: GeoPoint
    var address: String
    var imageURL: String
    
    static func createEmptyLocation() -> SpotitLocation {
        return SpotitLocation(locId: "", locationName: "", maxOccupancy: 0, currentOccupancy: 0, geoPoint: GeoPoint(latitude: 0.0, longitude: 0.0), address: "", imageURL: "")
    }
}

struct CheckInSummary {
   var uid: String
   var summaryItems : [String: Int]
   var topStudyLocation : String
   var currentStudylocation : String
    
   init(uid: String) {
        self.uid = uid
        self.summaryItems = [:]
        self.topStudyLocation = ""
        self.currentStudylocation = ""
   }
}


class FirebaseService {
    
    lazy var storage = Storage.storage()
    lazy var storageRef = storage.reference() //storing images
    static var instance = FirebaseService()
    lazy var db = Firestore.firestore() //database data
    
    
    init() {
        self.watchForCheckInUpdatesAndFireNotifications()
        self.watchForFavoriteUpdatesAndFireNotifications()
    }
    
    func uploadProfileImage(image: UIImage, user: User,  completionBlock: @escaping (_ url: URL?) -> Void ) {
        
        let userId = user.uid
        let imagesRef = storageRef.child("images")
        let imageRef =  imagesRef.child("images/\(userId).jpeg" )
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            return
        }
        
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"

        imageRef.putData(imageData, metadata: metaData) { metaData,error in
            if let _ = error {
                // Uh-oh, an error occurred!
                completionBlock(nil)
                return
            }
           
            imageRef.downloadURL { (url, error) in
              guard let downloadURL = url else {
                // Uh-oh, an error occurred!
                completionBlock(nil)
                return
              }
              //Success we have url
              completionBlock(downloadURL)
            }
        }
    }
    
    
    func downloadProfileImage(user: User,  completionBlock: @escaping (_ image: UIImage?) -> Void ) {
        let userId = user.uid
        let imagesRef = storageRef.child("images")
        let imageRef =  imagesRef.child("images/\(userId).jpeg" )
        imageRef.downloadURL { (url, error) in
          guard let downloadURL = url else {
            // Uh-oh, an error occurred!
            completionBlock(nil)
            return
          }
            
          //Success we have url
          do {
                 let data = try Data(contentsOf: downloadURL)
                 let image = UIImage(data: data)
                completionBlock(image)
          } catch {
                completionBlock(nil)
          }
        }
    }
    
    func downloadLocationImage(locationPictureName: String, completionBlock: @escaping (_ image: UIImage?) -> Void) {
               let imagesRef = storageRef.child("locationimages")
               let imageRef =  imagesRef.child("\(locationPictureName)")
               imageRef.downloadURL { (url, error) in
                 guard let downloadURL = url else {
                   // Uh-oh, an error occurred!
                   completionBlock(nil)
                   return
                 }
                   
                 //Success we have url
                 do {
                        let data = try Data(contentsOf: downloadURL)
                        let image = UIImage(data: data)
                       completionBlock(image)
                 } catch {
                       completionBlock(nil)
                 }
               }
    }
    
    func fetchSpotItLocations(user: User, completionBlock: @escaping (_ locations: [SpotitLocation]?) -> Void ) {
        let docRef = db.collection("SpotItLocations")
        
        docRef.getDocuments { (snap, error) in
            guard let snapshot = snap else {
                completionBlock(nil)
                return
            }
            var spotItlocations: [SpotitLocation] = []
            
            for document in snapshot.documents {
                print("\(document.documentID) => \(document.data())")
                let dictionary = document.data()
                let address = dictionary["address"] as! String
                let imageURL = dictionary["imageURL"] as! String
                let locationName = dictionary["locationName"] as! String
                let maxOccupancy = dictionary["maxOccupancy"] as! Int
                let currentOccupancy = dictionary["currentOccupancy"] as! Int
                let point =  dictionary["location"] as! GeoPoint
                let locId = document.documentID
                let spotItLocation = SpotitLocation(locId: locId, locationName: locationName, maxOccupancy: maxOccupancy, currentOccupancy: currentOccupancy, geoPoint: point, address: address, imageURL: imageURL)
                spotItlocations.append(spotItLocation)
            }
            completionBlock(spotItlocations)
        }
        
    }
    
    
    func fetchSpotItLocation(locationId: String, completionBlock: @escaping (_ locations: SpotitLocation?) -> Void ) {
        let docRef = db.collection("SpotItLocations")
        docRef.document(locationId).getDocument { (snap, error) in
            guard let snapshot = snap, let dictionary = snapshot.data()  else {
                completionBlock(nil) //did not find location
                return
            }
            let locationName = dictionary["locationName"] as! String
            let maxOccupancy = dictionary["maxOccupancy"] as! Int
            let imageURL = dictionary["imageURL"] as! String
            let address = dictionary["address"] as! String
            let currentOccupancy = dictionary["currentOccupancy"] as! Int
            let point =  dictionary["location"] as! GeoPoint
            let locId = snapshot.documentID
            let spotItLocation = SpotitLocation(locId: locId, locationName: locationName, maxOccupancy: maxOccupancy, currentOccupancy: currentOccupancy, geoPoint: point, address: address, imageURL: imageURL)
            completionBlock(spotItLocation)
        }
        
    }
    
    func checkInToLocation(user: User, location: SpotitLocation,  completionBlock: @escaping () -> Void ) {
        
        let locationsRef = db.collection("SpotItLocations")
        let checkInsRef = db.collection("UserCheckInLocations")
        
        //update current occupancy in SpotItLocation table
        let userCheckInDoc = checkInsRef.document(user.uid)
        let userCheckInLocations = userCheckInDoc.collection("checkInSummaryItems")
         
        userCheckInDoc.getDocument { (snap, error) in
            
            var prevLocation: String?
            if snap != nil {
                if let checkInData = snap?.data() {
                    prevLocation = checkInData["currentCheckInLocation"] as? String
                }
            }
            
            //Update increment count for  new location check in only if its not already checked in currently
            if prevLocation == location.locId {
                print("User has already checked-in to this location")
                return
            }
            
            locationsRef.document(location.locId).updateData([
                "currentOccupancy": FieldValue.increment(Int64(1))
            ])
                
            //Add/update users occupancy in user list of check in locations
            let userCheckInLocation = userCheckInLocations.document(location.locId)
            //update the currentCheckIn Now & then also the check in summary
            userCheckInDoc.setData(["currentCheckInLocation": location.locId],merge: true)
            userCheckInLocation.setData([
                "count": FieldValue.increment(Int64(1)),
                "locationName": location.locationName
            ], merge: true)
            
              //Update decrement count for previous location check in
            if let previousCheckInLocation = prevLocation {
                if previousCheckInLocation.count > 0 {
                    locationsRef.document(previousCheckInLocation).updateData([
                        "currentOccupancy": FieldValue.increment(Int64(-1))
                    ])
                }
            }
            completionBlock()
        }
      
    }
    
    func checkOut(user: User, location: SpotitLocation, completionBlock: @escaping (Bool)->Void ) {
        let locationsRef = db.collection("SpotItLocations")
        let checkInsRef = db.collection("UserCheckInLocations")
        checkInsRef.document(user.uid).setData(["currentCheckInLocation": ""],merge: true)
        
        locationsRef.document(location.locId).updateData([
            "currentOccupancy": FieldValue.increment(Int64(-1))
        ])
        
        completionBlock(true)
    }
    
    
    func fetchCheckInLocations(user: User, completionBlock: @escaping (CheckInSummary?) -> Void ) {
        //let locationsRef = db.collection("SpotItLocations")
        let checkInsRef = db.collection("UserCheckInLocations")
        
        checkInsRef.document(user.uid).getDocument { (snap, error) in
            guard let snapshot = snap, let dataDict = snapshot.data() else {
                completionBlock(nil)
                return
            }
            var summary = CheckInSummary(uid: user.uid)
            summary.currentStudylocation = dataDict["currentCheckInLocation"] as? String ?? ""
            
            let userCheckInLocations = checkInsRef.document(user.uid).collection("checkInSummaryItems")
            userCheckInLocations.getDocuments { (snap, error) in
                guard let snapshot = snap else {
                    completionBlock(nil) //error case
                    return
                }
                //success retrieving favorite locations
                var popularLocationCount = 0
                var nameCountDictionary: [String: Int] = [:]
    
                for document in snapshot.documents {
                    let dictionary = document.data()
                    print("\(document.documentID) => \(document.data())")
                    let locationName = dictionary["locationName"] as! String
                    let locationCount = dictionary["count"] as! Int
                    if popularLocationCount < locationCount {
                        summary.topStudyLocation = locationName
                        popularLocationCount = locationCount
                    }
                    nameCountDictionary[locationName] = locationCount
                }
                summary.summaryItems = nameCountDictionary
                completionBlock(summary)
            }
        }
        
  
    }
    
    //notify our app of any changes
    func watchForCheckInUpdatesAndFireNotifications() {
        let locationsRef = db.collection("SpotItLocations")
        locationsRef.addSnapshotListener(includeMetadataChanges: true) { documentSnapshot, error in
            NotificationCenter.default.post(name: Notification.Name.LocationDataChanged, object: nil)
        }
    }
    
    func watchForFavoriteUpdatesAndFireNotifications() {
       let locationsRef = db.collection("UserCheckInLocations")
       locationsRef.addSnapshotListener(includeMetadataChanges: true) { documentSnapshot, error in
           NotificationCenter.default.post(name: Notification.Name.FavoriteDataChanged, object: nil)
       }
   }
    
    
}
