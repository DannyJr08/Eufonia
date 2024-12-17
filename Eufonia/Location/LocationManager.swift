//
//  LocationManager.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 16.12.2024.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var currentLocationName: String = "Grabación Desconocida"
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func getAddress(from location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Error al obtener la dirección: \(error)")
                self.currentLocationName = "Ubicación Desconocida"
                return
            }
            if let placemark = placemarks?.first {
                let street = placemark.thoroughfare ?? "Calle"
                let number = placemark.subThoroughfare ?? ""
                let city = placemark.locality ?? "Ciudad"
                self.currentLocationName = "\(street) \(number), \(city)"
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            getAddress(from: location)
            locationManager.stopUpdatingLocation() // Detener actualizaciones
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener la ubicación: \(error.localizedDescription)")
        self.currentLocationName = "Ubicación Desconocida"
    }
}
