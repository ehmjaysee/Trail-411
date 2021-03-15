//
//  TrailDetailVC.swift
//  Trails-411
//
//  Created by Michael Chartier on 3/8/21.
//

import UIKit
import MapKit


class TrailDetailVC: UIViewController
{
    @IBOutlet weak var O_status: UILabel!
    @IBOutlet weak var O_image: UIImageView!
    @IBOutlet weak var O_description: UITextView!
    @IBOutlet weak var O_map: MKMapView!
    
    
    var index: Int!     // set by presetner VC
    var trail: TrailData!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        trail = allTrails[index]

        navigationItem.title = trail.name

        let shortDate = DateFormatter()
        shortDate.dateStyle = .medium
        O_status.text = shortDate.string(from: trail.lastUpdate) + "  " + trail.status

        O_image.image = UIImage(named: "splash-4")
        O_description.text = trail.description
        
        if let user = locationManager.lastLockedLocation, let trailhead = trail.trailheads.first {
            O_map.showsUserLocation = true
            O_map.addAnnotation(PinObject(location:trailhead))
            let locations = [user, trailhead]
            centerMap(locations)
        }
        
    }
    
    private func centerMap(_ locations: [CLLocation])
    {
        var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        for annotation in locations {
            topLeftCoord.latitude = max(topLeftCoord.latitude, annotation.coordinate.latitude)
            topLeftCoord.longitude = min(topLeftCoord.longitude, annotation.coordinate.longitude)
            bottomRightCoord.latitude = min(bottomRightCoord.latitude, annotation.coordinate.latitude)
            bottomRightCoord.longitude = max(bottomRightCoord.longitude, annotation.coordinate.longitude)
        }
        let newCenter = CLLocationCoordinate2D(
            latitude: topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) / 2,
            longitude: topLeftCoord.longitude - (topLeftCoord.longitude - bottomRightCoord.longitude) / 2)
        let extraSpace = 1.4
        let span = MKCoordinateSpan(
            latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace,
            longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace)
        
        let newRegion = MKCoordinateRegion(center: newCenter, span: span)
        
        O_map.setCenter(newCenter, animated: false)
        O_map.setRegion(newRegion, animated: false)
        
    }
}


class PinObject: NSObject, MKAnnotation
{
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    @objc dynamic var subtitle: String?

    init(location: CLLocation)
    {
        coordinate = location.coordinate
        title = "Trailhead"
//        let travelTime =
//        subtitle = formatToHhMmSs(seconds: travelTime))
    }
}

