//
//  Functions.swift
//  MyLocations
//
//  Created by Jimmy  on 10/18/21.
//

import Foundation

//free function, can eb used anywhere in your code
func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(
    deadline: .now() + seconds,
    execute: run)
}


//find the location of the core data folder
let applicationDocumentsDirectory: URL = {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  return paths[0]
}()




// MARK: - Error message for user

//first outputs error message to console
let dataSaveFailedNotification = Notification.Name(
  rawValue: "DataSaveFailedNotification")

//whenever a saving error occurs, this function will send out this notification
func fatalCoreDataError(_ error: Error) {
  print("*** Fatal error: \(error)")
  //uses NotificationCneter to post a notification
  NotificationCenter.default.post(
    name: dataSaveFailedNotification,
    object: nil)
}
