//
//  LocationManager.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var isoCountryCode: String?
    @Published var locationError: String?
    @Published var currentLocation: CLLocation?
    @Published var currentCity: String?
    
    private var continuation: CheckedContinuation<String?, Never>?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    /// Appelle cette fonction depuis `.onAppear` dans une `Task {}` pour obtenir le code pays
    func getCurrentCountryCode() async -> String? {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
        
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            locationError = "Impossible d'obtenir la localisation."
            continuation?.resume(returning: nil)
            continuation = nil
            return
        }

        // ✅ Stocker la localisation
        DispatchQueue.main.async {
            self.currentLocation = location
        }

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                self.locationError = "Erreur geocoding : \(error.localizedDescription)"
                self.continuation?.resume(returning: nil)
                self.continuation = nil
                return
            }

            guard let placemark = placemarks?.first else {
                self.locationError = "Données de localisation indisponibles."
                self.continuation?.resume(returning: nil)
                self.continuation = nil
                return
            }

            // ✅ Extraire le code pays
            if let isoCode = placemark.isoCountryCode {
                DispatchQueue.main.async {
                    self.isoCountryCode = isoCode
                }
                self.continuation?.resume(returning: isoCode)
            } else {
                self.locationError = "Code pays introuvable."
                self.continuation?.resume(returning: nil)
            }

            // ✅ Extraire la ville (localité)
            if let city = placemark.locality {
                DispatchQueue.main.async {
                    self.currentCity = city
                }
            }

            self.continuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = "Erreur de localisation : \(error.localizedDescription)"
        continuation?.resume(returning: nil)
        continuation = nil
    }
}
