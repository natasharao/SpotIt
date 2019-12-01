//
//  MapViewController.swift
//  SpotItApp
//
//  Created by Natasha Rao on 10/29/19.
//  Copyright © 2019 Natasha Rao. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

class MapViewController: UIViewController {
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    var studyLocations : [SpotitLocation] = []
    var selectedCheckInLocation: SpotitLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.populateStudyLocations()
        self.populateMapView()
        self.findCurrentLocation()
        
        mapView.delegate = self

        //should do this to refresh data if it changes while we view the map
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeData(_:)), name: Notification.Name.LocationDataChanged, object: nil)
     }
    
    @objc private func didChangeData(_ notification: Notification) {
        //refresh our data
        self.populateStudyLocations()
    }
    
    func populateStudyLocations() {
        let user = Auth.auth().currentUser!
        
        FirebaseService.instance.fetchSpotItLocations(user: user) { (locations) in
            DispatchQueue.main.async { // always change ui elements in main thread
                if let foundLocations = locations {
                    self.studyLocations = foundLocations
                    self.populateMapView()
                }
            }
        }
    }
    
    func findCurrentLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func populateMapView() {
        
        for location in studyLocations {
            let annotation: MKPointAnnotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2DMake(location.geoPoint.latitude , location.geoPoint.longitude)
            annotation.title = location.locationName
            annotation.subtitle = "Capacity: " + String(location.maxOccupancy)
            mapView.addAnnotation(annotation)
        }
    }
  
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0] as CLLocation
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
        
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude , longitude: userLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
        let annotation: MKPointAnnotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(userLocation.coordinate.latitude , userLocation.coordinate.longitude)
        mapView.addAnnotation(annotation)
    }
}

extension MapViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationView")
        annotationView.canShowCallout = true
        annotationView.rightCalloutAccessoryView = UIButton.init(type: UIButton.ButtonType.detailDisclosure)


        return annotationView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        guard let annotation = view.annotation,
              let locationName = annotation.title as? String else
        {
            return
        }
        
        self.selectedCheckInLocation = self.findLocationForName(locationName: locationName)
        performSegue(withIdentifier: "checkin", sender: annotation)
        
       
    }
    
    func findLocationForName(locationName: String) -> SpotitLocation {
        
        var foundLocation = self.studyLocations[0]
        
        for location in self.studyLocations {
            if location.locationName == locationName {
                foundLocation =  location
                break
            }
        }
        return foundLocation
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "checkin" {
            if let destinationVC = segue.destination as? CheckInViewController,
               let spotItLocation =  self.selectedCheckInLocation {
                destinationVC.setCheckInLocation(location: spotItLocation)
            }
        }
    }
    
}


