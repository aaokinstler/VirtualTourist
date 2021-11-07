//
//  Location+Extension.swift
//  VirtualTourist
//
//  Created by Anton Kinstler on 10.08.2021.
//

import MapKit

extension Location: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        let latDegrees = CLLocationDegrees(latitude)
        let longDegrees = CLLocationDegrees(longitude)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
    }
   
}
