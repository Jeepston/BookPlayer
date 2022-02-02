//
//  SpeedManager.swift
//  BookPlayer
//
//  Created by Gianni Carlo on 4/9/21.
//  Copyright © 2021 Tortuga Power. All rights reserved.
//

import BookPlayerKit
import Combine
import Foundation

public protocol SpeedManagerProtocol {
  var minimumSpeed: Double { get }
  var maximumSpeed: Double { get }

  func setSpeed(_ newValue: Float, relativePath: String?)
  func getSpeed(relativePath: String?) -> Float
}

class SpeedManager: SpeedManagerProtocol {
  private let libraryService: LibraryServiceProtocol

  let minimumSpeed: Double = 0.5
  let maximumSpeed: Double = 4.0

  public private(set) var currentSpeed = CurrentValueSubject<Float, Never>(1.0)

  public init(libraryService: LibraryServiceProtocol) {
    self.libraryService = libraryService
  }

  public func setSpeed(_ newValue: Float, relativePath: String?) {
    if let relativePath = relativePath {
      self.libraryService.updateBookSpeed(at: relativePath, speed: newValue)
    }

    // set global speed
    if UserDefaults.standard.bool(forKey: Constants.UserDefaults.globalSpeedEnabled.rawValue) {
      UserDefaults.standard.set(newValue, forKey: "global_speed")
    }

    self.currentSpeed.value = newValue
  }

  public func getSpeed(relativePath: String?) -> Float {
    let speed: Float

    if UserDefaults.standard.bool(forKey: Constants.UserDefaults.globalSpeedEnabled.rawValue) {
      speed = UserDefaults.standard.float(forKey: "global_speed")
    } else if let relativePath = relativePath {
      speed = self.libraryService.getItemSpeed(at: relativePath)
    } else {
      speed = self.currentSpeed.value
    }

    self.currentSpeed.value = speed > 0 ? speed : 1.0

    return self.currentSpeed.value
  }

  public func currentSpeedPublisher() -> AnyPublisher<Float, Never> {
    return self.currentSpeed.eraseToAnyPublisher()
  }
}
