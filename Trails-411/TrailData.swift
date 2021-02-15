//
//  TrailData.swift
//  Trails 411
//
//  Created by Michael Chartier on 12/31/20.
//

import Foundation
import CoreLocation


var allTrails = [TrailData]()

struct TrailData
{
    var id: String
    var name: String
    var status: String
    var distance: Double
    var trailheads: [CLLocation]
    
    var isOpen: Bool {
        return status.caseInsensitiveCompare("open") == .orderedSame
    }

}

