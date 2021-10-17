//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by Jimmy  on 10/16/21.
//

import UIKit
import CoreLocation

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .short
  return formatter
}()


class LocationDetailsViewController: UITableViewController {
  @IBOutlet var descriptionTextView: UITextView!
  @IBOutlet var categoryLabel: UILabel!
  @IBOutlet var latitudeLabel: UILabel!
  @IBOutlet var longitudeLabel: UILabel!
  @IBOutlet var addressLabel: UILabel!
  @IBOutlet var dateLabel: UILabel!
  
  //not optional so it must be given an initial value
  var coordinate = CLLocationCoordinate2D(
    latitude: 0,
    longitude: 0)
  
  // contains address information such as street name, city name, etc from reverse geocoding.
  // Optional because there is no guarantee that the geocoder finds an address for the given coords
  var placemark: CLPlacemark?
  
  //temporarily store chosen category
  var categoryName = "No Category"

  override func viewDidLoad() {
    super.viewDidLoad()

    descriptionTextView.text = ""
    categoryLabel.text = categoryName

    latitudeLabel.text = String(
      format: "%.8f",
      coordinate.latitude)
    longitudeLabel.text = String(
      format: "%.8f",
      coordinate.longitude)
    if let placemark = placemark {
      addressLabel.text = string(from: placemark)
    } else {
      addressLabel.text = "No Address Found"
    }

    dateLabel.text = format(date: Date())
  }

  // MARK: - Navigation
  //sets the catefory as categoryName when going to the PickCategory screen
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "PickCategory" {
      let controller = segue.destination as! CategoryPickerViewController
      controller.selectedCategoryName = categoryName
    }
  }
  
  //must add this method to the destination of the unwind segue. So the unwind segue of categorypicker will go to this screen
  @IBAction func categoryPickerDidPickCategory(
    _ segue: UIStoryboardSegue
  ) {
    let controller = segue.source as! CategoryPickerViewController
    categoryName = controller.selectedCategoryName
    categoryLabel.text = categoryName
  }


  
  // MARK: - Actions
  @IBAction func done() {
    //basically close the view and go back to the previous
    navigationController?.popViewController(animated: true)
  }

  @IBAction func cancel() {
    navigationController?.popViewController(animated: true)
  }
  
  // MARK: - Helper Methods
  func string(from placemark: CLPlacemark) -> String {
    var text = ""
    if let tmp = placemark.subThoroughfare {
      text += tmp + " "
    }
    if let tmp = placemark.thoroughfare {
      text += tmp + ", "
    }
    if let tmp = placemark.locality {
      text += tmp + ", "
    }
    if let tmp = placemark.administrativeArea {
      text += tmp + " "
    }
    if let tmp = placemark.postalCode {
      text += tmp + ", "
    }
    if let tmp = placemark.country {
      text += tmp
    }
    return text
  }
  
  //asks the DateFOrmatter to turn the Date into a string and return it
  func format(date: Date) -> String {
    return dateFormatter.string(from: date)
  }


}

