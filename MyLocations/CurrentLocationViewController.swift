//
//  ViewController.swift
//  MyLocations
//
//  Created by Jimmy  on 10/7/21.
//

import UIKit
import CoreLocation
import CoreData

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var latitudeLabel: UILabel!
  @IBOutlet var longitudeLabel: UILabel!
  @IBOutlet var addressLabel: UILabel!
  @IBOutlet var tagButton: UIButton!
  @IBOutlet var getButton: UIButton!
  
  var managedObjectContext: NSManagedObjectContext!

  

  //CLLocationManager object will give the GPS coordinates. We are putting the reference to this object in the constant locationManager
  let locationManager = CLLocationManager()
  //store the user's most recent current location
  //needs to be optional because it is possible to not a location, for example when you are in the middle of no where.
  var location: CLLocation?
  
  var updatingLocation = false
  var lastLocationError: Error?
  
  
  //reverse geocoding properties
  //CLGeocoder is the object that will perform the geocoding
  let geocoder = CLGeocoder()
  //contains the address results. needs to be optional because it will have no value when there is no location yet
  var placemark: CLPlacemark?
  //set this to true when a geocoding operating is taking place
  var performingReverseGeocoding = false
  //will contain error object if something goes wrong
  var lastGeocodingError: Error?
  
  var timer: Timer?

  override func viewDidLoad() {
    super.viewDidLoad()
    updateLabels()
  }

  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    //hide navigation  bar when this view is about to appear
    //however this does it for the all views displayed by the navigation controller
    navigationController?.isNavigationBarHidden = true
  }
  
  //make nagivation bar appear again once this view disappears
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.isNavigationBarHidden = false
  }


  // MARK: - Actions
  
  //this method is hooked up to the Get My Location button
  @IBAction func getLocation() {
    //checks current authorization status.
    let authStatus = locationManager.authorizationStatus
    //if app has not asked for permission yet
    if authStatus == .notDetermined {
      //app will request "When In Use" authorization
      locationManager.requestWhenInUseAuthorization()
      return
    }
    
    //show the alert from showLocationServicesDeniedAlert() if authorization is denied or restricted
    if authStatus == .denied || authStatus == .restricted {
      showLocationServicesDeniedAlert()
      return
    }
    
    /*
    //tells location manager that the view controller is its delegate
    locationManager.delegate = self
    //and that you want to receive locations with an accuracy of up to 10 meters
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    //start the location manager. CLLocationManager object will send location updates to its delecate(the view controller)
    locationManager.startUpdatingLocation()
 
    */
    //using the updatingLocation flag to determine what state the app is in
    if updatingLocation {
      stopLocationManager()
    }else {
      location = nil
      lastLocationError = nil
      placemark = nil
      lastGeocodingError = nil
      startLocationManager()
    }
    updateLabels()
  }

  // MARK: - Navigation
  
  //passing values to Tag Location screen
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "TagLocation" {
      let controller = segue.destination as! LocationDetailsViewController
      controller.coordinate = location!.coordinate
      controller.placemark = placemark
      
      controller.managedObjectContext = managedObjectContext
    }
  }

  // MARK: - Helper Methods
  
  //pops up an alert with a helpful hint
  func showLocationServicesDeniedAlert() {
    let alert = UIAlertController(
      title: "Location Services Disabled",
      message: "Please enable location services for this app in Settings.",
      preferredStyle: .alert)

    let okAction = UIAlertAction(
      title: "OK",
      style: .default,
      handler: nil)
    alert.addAction(okAction)

    present(alert, animated: true, completion: nil)
  }

  func updateLabels() {
    //since location instance variable is an optional, you have to use if let
    if let location = location {
      //if there is a valid location opject, convert the lats and longs from Doubles to strings and put them into the labels
      latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
      longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
      tagButton.isHidden = false
      messageLabel.text = ""
      //display the address
      if let placemark = placemark {
        addressLabel.text = string(from: placemark)
      } else if performingReverseGeocoding {
        addressLabel.text = "Searching for Address..."
      } else if lastGeocodingError != nil {
        addressLabel.text = "Error Finding Address"
      } else {
        addressLabel.text = "No Address Found"
      }
    } else {
      latitudeLabel.text = ""
      longitudeLabel.text = ""
      addressLabel.text = ""
      tagButton.isHidden = true
     
      let statusMessage: String
      if let error = lastLocationError as NSError? {
        if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
          statusMessage = "Location Services Disabled"
        } else {
          statusMessage = "Error Getting Location"
        }
      } else if !CLLocationManager.locationServicesEnabled() {
        statusMessage = "Location Services Disabled"
      } else if updatingLocation {
        statusMessage = "Searching..."
      } else {
        statusMessage = "Tap 'Get My Location' to Start"
      }
      messageLabel.text = statusMessage
    }
    configureGetButton()
  }
  
  
  func startLocationManager() {
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.startUpdatingLocation()
      updatingLocation = true
      
      timer = Timer.scheduledTimer(
        timeInterval: 60,
        target: self,
        selector: #selector(didTimeOut),
        userInfo: nil,
        repeats: false)
    }
  }
  
  func stopLocationManager() {
    if updatingLocation {
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      updatingLocation = false
      
      if let timer = timer {
        timer.invalidate()
      }
    }
  }
  
  func string(from placemark: CLPlacemark) -> String {
    var line1 = ""
    if let tmp = placemark.subThoroughfare {
      line1 += tmp + " "
    }
    if let tmp = placemark.thoroughfare {
      line1 += tmp
    }
    var line2 = ""
    if let tmp = placemark.locality {
      line2 += tmp + " "
    }
    if let tmp = placemark.administrativeArea {
      line2 += tmp + " "
    }
    if let tmp = placemark.postalCode {
      line2 += tmp
    }
    return line1 + "\n" + line2
  }
  
  @objc func didTimeOut() {
    print("*** Time out")
    if location == nil {
      stopLocationManager()
      lastLocationError = NSError(
        domain: "MyLocationsErrorDomain",
        code: 1,
        userInfo: nil)
      updateLabels()
    }
  }

  
  func configureGetButton() {
    //if app is currently updating location, button's title becomes Stop,
    if updatingLocation {
      getButton.setTitle("Stop", for: .normal)
    } else {//else it becomes Get My Location
      getButton.setTitle("Get My Location", for: .normal)
    }
  }

  // MARK: - CLLocationManagerDelegate
  //delegate methods for the location manager
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("didFailWithError \(error.localizedDescription)")
    
    //CLError.locationUnknown error means the location manager was unable to obtain a location atm- either keep trying and wait or receive a different error
    if (error as NSError).code == CLError.locationUnknown.rawValue {
      return
      //in the case of a more serious error, you store the error in lastLocationError
    }
    lastLocationError = error
    stopLocationManager()
    updateLabels()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //you take the last CLLocation object from the array because it is the most recent update
    let newLocation = locations.last!
    print("didUpdateLocations \(newLocation)")
    
    
    //read textbook chap 23
    if newLocation.timestamp.timeIntervalSinceNow < -5 {
      return
    }
    
    //if horizontalAccuracy is less than 0, the measurements are invalid and should be ignored
    if newLocation.horizontalAccuracy < 0 {
      return
    }
    
    var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
    if let location = location {
      distance = newLocation.distance(from: location)
    }
    
    
    
    //this is where you determine if new reading is more useful than old reading
    //larger accuracy value = less accurate
    //previous reading = location!.horrizontalAccuracy
    //if location == nil, this is the very first location update you are receiving
    //if this is very first location reading or new location is more accurate then...
    if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
      //clears out old error state
      lastLocationError = nil
      //store the newLocation(most recent location) into location
      location = newLocation
      
      //if new location's accuracy is equal to or better than the desired accuracy(10 meters) we stop
      if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
        print("*** We're done!")
        stopLocationManager()
        
        
        if distance > 0 {
          performingReverseGeocoding = false
        }
      }
      updateLabels()
      
      if !performingReverseGeocoding {
        print ("*** Going to geocode")
        
        performingReverseGeocoding = true
        geocoder.reverseGeocodeLocation(newLocation) {placemarks, error in
          self.lastGeocodingError = error
          if error == nil, let places = placemarks, !places.isEmpty {
            self.placemark = places.last!
          } else {
            self.placemark = nil
          }

          self.performingReverseGeocoding = false
          self.updateLabels()
        }
      }
      
    } else if distance < 1 {
      let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
      if timeInterval > 10 {
        print("*** Force done!")
        stopLocationManager()
        updateLabels()
      }
    }
  }
}
