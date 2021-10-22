//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by Jimmy  on 10/16/21.
//

import UIKit
import CoreLocation
import CoreData

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

  var managedObjectContext: NSManagedObjectContext!
  var date = Date()


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

    //now uses new property instead of creating date on the fly
    //dateLabel.text = format(date: Date())
    dateLabel.text = format(date: date)

    
    //hide keyboard
    let gestureRecognizer = UITapGestureRecognizer(
      target: self,
      //call hidekeyboard message
      action: #selector(hideKeyboard))
    gestureRecognizer.cancelsTouchesInView = false
    tableView.addGestureRecognizer(gestureRecognizer)

    
  }
  
  //whenever the user taps somewhere in the table view, the gesture recognizer calls this method
  @objc func hideKeyboard(
    _ gestureRecognizer: UIGestureRecognizer
  ) {
    let point = gestureRecognizer.location(in: tableView)
    let indexPath = tableView.indexPathForRow(at: point)

    //if tap is on section o, row o, which is the cell with the text view then return,
    if indexPath != nil && indexPath!.section == 0 &&
    indexPath!.row == 0 {
      return
    }
    //otherwise hide keyboard
    descriptionTextView.resignFirstResponder()
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
    //navigationController?.popViewController(animated: true)
    guard let mainView = navigationController?.parent?.view
      else { return }
      let hudView = HudView.hud(inView: mainView, animated: true)
      hudView.text = "Tagged"
      // 1
      let location = Location(context: managedObjectContext)
      // 2
      location.locationDescription = descriptionTextView.text
      location.category = categoryName
      location.latitude = coordinate.latitude
      location.longitude = coordinate.longitude
      location.date = date
      location.placemark = placemark
      // 3 - save the context
      do {
        try managedObjectContext.save()
        afterDelay(0.6) {
          hudView.hide()
          self.navigationController?.popViewController(
            animated: true)
        }
      } catch {
        // 4 - if there is an error during save - error will be outputted
        //fatalError("Error: \(error)")
        
        //new error code that will popup for user - in Functions.swift file
        fatalCoreDataError(error)
      }
    
    //delays the closing of the screen when done is pressed so screen doesnt close before the hud is done displaying
    //close Tag Locationn screen after 0.6 seconds
    /*
    let delayInSeconds = 0.6
    DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
      hudView.hide()
      self.navigationController?.popViewController(animated: true)
    } */

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
  
  // MARK: - Table View Delegates
  //these methods allow the user to tap anywhere inside the first cell and the text view will activate
  override func tableView(
    _ tableView: UITableView,
    willSelectRowAt indexPath: IndexPath
  ) -> IndexPath? {
    if indexPath.section == 0 || indexPath.section == 1 {
      return indexPath
    } else {
      return nil
    }
  }

  override func tableView(
    _ tableView: UITableView,
    didSelectRowAt indexPath: IndexPath
  ) {
    if indexPath.section == 0 && indexPath.row == 0 {
      descriptionTextView.becomeFirstResponder()
    }
  }



}

