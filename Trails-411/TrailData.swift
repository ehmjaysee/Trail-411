//
//  TrailData.swift
//  Trails 411
//
//  Created by Michael Chartier on 12/31/20.
//

import Foundation
import CoreLocation
import MapKit


let Notification_Estimate = Notification.Name("estimate")


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

    init( id: String, name: String, status: String, description: String, lastUpdate: Date, trailhead: CLLocation ) {
        self.id = id
        self.name = name
        self.status = status
        self.description = description
        self.lastUpdate = lastUpdate
        self.trailheads = [trailhead]
        self.estimateTravelDistanceToRider()
        NotificationCenter.default.addObserver(self, selector: #selector(locationStateChanged(notification:)), name: Notif_LocationState, object: nil)
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
                NotificationCenter.default.post(name: Notification_Estimate, object: self.id)
            }
        }
    }

    @objc func locationStateChanged( notification: NSNotification )
    {
        if locationManager.locationState == .locked {
            self.estimateTravelDistanceToRider()
        }
    }
}

