//
//  TrailData.swift
//  Trails 411
//
//  Created by Michael Chartier on 12/31/20.
//

import Foundation
import CoreLocation
import MapKit



var allTrails = [TrailData]()

class TrailData
{
    var id: String
    var name: String
    var status: String
    var description: String
    var distance: Double?
    var travelTime: TimeInterval?
    var lastUpdate: Date
    var trailheads: [CLLocation]
    
    // COMPUTED PROPERTIES
    private var subKey: String {
        let key = id + "sub"
        return key
    }
    var subscriptionId: String? {
        get { return appDefaults.string(forKey: subKey) }
        set {
            if newValue == nil {
                appDefaults.removeObject(forKey: subKey)
            } else {
                appDefaults.setValue(newValue, forKey: subKey)
            }
        }
    }
    var isSubscribed: Bool { return (subscriptionId != nil )}
    var editSubscription = false
    var isOpen: Bool {
        return status.caseInsensitiveCompare("open") == .orderedSame
    }
    var howOld: String {
        let diff = Calendar.current.dateComponents([.day, .hour], from: lastUpdate, to: Date())
        if let days = diff.day, days > 1 {
            return String(days) + " days ago"
        } else if let hours = diff.hour {
            return String(hours) + " hours ago"
        } else {
            let shortDate = DateFormatter()
            shortDate.dateStyle = .medium
            return shortDate.string(from: lastUpdate)
        }
    }

    init( id: String, name: String, status: String, description: String, lastUpdate: Date, trailhead: CLLocation ) {
        self.id = id
        self.name = name
        self.status = status
        self.description = description
        self.lastUpdate = lastUpdate
        self.trailheads = [trailhead]
        self.estimateTravelDistanceToRider()
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdate(notification:)), name: Notif_LocationUpdate, object: nil)
    }
    
    private func estimateTravelDistanceToRider()
    {
        guard let myLocation = locationManager.lastLockedLocation else { return }
        guard let trailhead = trailheads.first else { return }
        
        // Get the travel time estimate from Apple MapKit
        //todo: Use MapBox for better estimates
        let request         = MKDirections.Request()
        let source          = MKPlacemark(coordinate: myLocation.coordinate)
        let destination     = MKPlacemark(coordinate: trailhead.coordinate)
        request.source      = MKMapItem(placemark: source)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = MKDirectionsTransportType.automobile;
        request.requestsAlternateRoutes = false
        let directions = MKDirections(request: request)
        directions.calculateETA { (response, error) in
            if let error = error {
                print("ETA \(error)")
            } else if let response = response {
                print("ETA \(response.expectedTravelTime)s \(response.distance)m")
                self.travelTime = response.expectedTravelTime
                self.distance = response.distance
                NotificationCenter.default.post(name: Notif_TrailUpdate, object: self.id)
            }
        }
    }

    @objc func locationUpdate( notification: NSNotification )
    {
        // We get this notification when our location is determined for first time -AND- when it changes significantly
        self.estimateTravelDistanceToRider()
    }
}

