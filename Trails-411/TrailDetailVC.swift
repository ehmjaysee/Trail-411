//
//  TrailDetailVC.swift
//  Trails-411
//
//  Created by Michael Chartier on 3/8/21.
//

import UIKit
import MapKit
import TORoundedButton


class TrailDetailVC: UIViewController
{
    @IBOutlet weak var O_status: UILabel!
    @IBOutlet weak var O_image: UIImageView!
    @IBOutlet weak var O_description: UITextView!
    @IBOutlet weak var O_map: MKMapView!
    @IBOutlet weak var O_directions: RoundedButton!
    @IBOutlet weak var O_updated: UILabel!
    
    
    var index: Int!     // set by presetner VC
    var trail: TrailData!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        trail = allTrails[index]

        navigationItem.title = trail.name

        O_status.text = trail.status
        O_updated.text = "Updated " + trail.howOld
        O_image.image = UIImage(named: "splash-4")
        O_description.text = trail.description
        
        // Update the map
        if let user = locationManager.lastLockedLocation, let trailhead = trail.trailheads.first {
            O_map.showsUserLocation = true
            if let annotation = PinObject(trail: trail) {
                O_map.addAnnotation(annotation)
                O_map.selectAnnotation(annotation, animated: true)
            }
            let locations = [user, trailhead]
            centerMap(locations)
            O_map.isUserInteractionEnabled = false
        }

        // Update the directions button
        O_directions.text = ""
        O_directions.tappedHandler = { self.showDirections() }
        if trail.trailheads.count == 0 {
            O_directions.isEnabled = false
        } else if let travelTime = trail.travelTime {
            let minutes = Int(travelTime / 60.0)
            let text = "Directions\n" + String(minutes) + " min"
            O_directions.attributedText = NSAttributedString(string: text)
        } else {
            O_directions.attributedText = NSAttributedString(string: "Directions")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(trailUpdate(notification:)), name: Notif_TrailUpdate, object: nil)

    }
    
    private func showDirections()
    {
        guard let dest = trail.trailheads.first else { return }
        
        // first try google maps
        if UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!) {
            //        "comgooglemaps://?daddr=48.8566,2.3522)&directionsmode=driving&zoom=14&views=traffic"
            let urlString = "comgooglemaps://dir/?api=1&daddr=" + dest.coordinate.displayString + ")&directionsmode=driving&zoom=14&views=traffic&dir_action=navigate"
            print(urlString)
            let url = URL(string: urlString)!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: dest.coordinate, addressDictionary: nil))
            mapItem.name = trail.name
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
    }
    
    
    @IBAction func A_submitPhoto(_ sender: Any) {
    }
    
    @objc func trailUpdate( notification: NSNotification ) {
        if let id = notification.object as? String, id == trail.id, let newData = allTrails.first(where: { $0.id == id }) {
            // There was an update to the trail data that we are currently displaying
            self.trail = newData

            // Check if the travelTime was updated
            if let travelTime = trail.travelTime {
                let minutes = Int(travelTime / 60.0)
                let text = "Directions\n" + String(minutes) + " min"
                O_directions.attributedText = NSAttributedString(string: text)
            }
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

    init?( trail: TrailData )
    {
        if let trailhead = trail.trailheads.first {
            coordinate = trailhead.coordinate
            title = trail.name
            subtitle = "Trailhead"
        } else {
            return nil
        }
    }
}


extension TrailDetailVC: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "PinObject"

        if annotation is PinObject {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                annotationView.annotation = annotation
                return annotationView
            } else {
                let annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier:identifier)

//                let btn = UIButton(type: .detailDisclosure)
//                btn.setTitle("Directions", for: .normal)
//                annotationView.rightCalloutAccessoryView = btn
                annotationView.canShowCallout = true
                annotationView.isEnabled = true
                return annotationView
            }
        }

        return nil
    }
/*
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let capital = view.annotation as! PinObject
        let placeName = capital.title
        let placeInfo = "testing"   //capital.info

        let ac = UIAlertController(title: placeName, message: placeInfo, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
*/
}
