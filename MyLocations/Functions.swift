//
//  Functions.swift
//  MyLocations
//
//  Created by Jimmy  on 10/18/21.
//  Copyright © 2021 Razeware. All rights reserved.
//

import Foundation

//free function, can eb used anywhere in your code
func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(
    deadline: .now() + seconds,
    execute: run)
}

