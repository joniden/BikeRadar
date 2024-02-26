//
//  LocationsHandler.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-24.
//

import Foundation
import MapKit
import AppTrackingTransparency

@MainActor class LocationsHandler: ObservableObject {
    
    static let shared = LocationsHandler()
    public let manager: CLLocationManager
    
    init() {
        self.manager = CLLocationManager()
        if self.manager.authorizationStatus == .notDetermined {
            self.manager.requestWhenInUseAuthorization()
        }
    }
    
    // This is a workaround to get locations permission to work - known bug in Xcode 15 see https://developer.apple.com/forums/thread/740598
    func requestATTPermission() {
        ATTrackingManager.requestTrackingAuthorization { status in
            // Handle the result of the permission request
            switch status {
            case .authorized:
                print("Permission granted")
            case .denied:
                print("Permission denied")
            case .notDetermined:
                print("Permission not determined")
            case .restricted:
                print("Permission restricted")
            @unknown default:
                break
            }
        }
    }
}
