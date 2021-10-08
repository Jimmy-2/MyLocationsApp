//
//  ViewController.swift
//  MyLocations
//
//  Created by Jimmy  on 10/7/21.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var latitudeLabel: UILabel!
  @IBOutlet var longitudeLabel: UILabel!
  @IBOutlet var addressLabel: UILabel!
  @IBOutlet var tagButton: UIButton!
  @IBOutlet var getButton: UIButton!

  //CLLocationManager object will give the GPS coordinates. We are putting the reference to this object in the constant locationManager
  let locationManager = CLLocationManager()
  //store the user's most recent current location
  //needs to be optional because it is possible to not a location, for example when you are in the middle of no where.
  var location: CLLocation?

  override func viewDidLoad() {
    super.viewDidLoad()
    updateLabels()
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
    
    //tells location manager that the view controller is its delegate
    locationManager.delegate = self
    //and that you want to receive locations with an accuracy of up to 10 meters
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    //start the location manager. CLLocationManager object will send location updates to its delecate(the view controller)
    locationManager.startUpdatingLocation()
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
    } else {
      latitudeLabel.text = ""
      longitudeLabel.text = ""
      addressLabel.text = ""
      tagButton.isHidden = true
      messageLabel.text = "Tap 'Get My Location' to Start"
    }
  }

  // MARK: - CLLocationManagerDelegate
  //delegate methods for the location manager
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("didFailWithError \(error.localizedDescription)")
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //you take the last CLLocation object from the array because it is the most recent update
    let newLocation = locations.last!
    print("didUpdateLocations \(newLocation)")
    //store the newLocation(most recent location) into location
    location = newLocation
    updateLabels()
  }
}
