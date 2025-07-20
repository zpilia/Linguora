//
//  LocationManager.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import Foundation
import CoreLocation
import Combine

/// Gère la localisation, le pays (ISO) et la ville
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager() // CLLocationManager natif

    @Published var isoCountryCode: String?        // Code pays (ex: "FR")
    @Published var locationError: String?         // Erreur de localisation
    @Published var currentLocation: CLLocation?   // Localisation brute
    @Published var currentCity: String?           // Ville actuelle

    private var continuation: CheckedContinuation<String?, Never>? // Pour await/async

    override init() {
        super.init()
        manager.delegate = self                           // Réception des updates
        manager.desiredAccuracy = kCLLocationAccuracyBest // Précision max
    }

    /// Appelée depuis `.onAppear { Task { ... } }` pour obtenir le code pays
    func getCurrentCountryCode() async -> String? {
        manager.requestWhenInUseAuthorization() // Autorisation utilisateur
        manager.requestLocation()               // Lancer récupération
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    /// Résultat de localisation
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            locationError = "Impossible d'obtenir la localisation."
            continuation?.resume(returning: nil)
            continuation = nil
            return
        }

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

            if let isoCode = placemark.isoCountryCode {
                DispatchQueue.main.async {
                    self.isoCountryCode = isoCode
                }
                self.continuation?.resume(returning: isoCode)
            } else {
                self.locationError = "Code pays introuvable."
                self.continuation?.resume(returning: nil)
            }

            if let city = placemark.locality {
                DispatchQueue.main.async {
                    self.currentCity = city
                }
            }

            self.continuation = nil
        }
    }

    /// Gestion des erreurs de localisation
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = "Erreur de localisation : \(error.localizedDescription)"
        continuation?.resume(returning: nil)
        continuation = nil
    }
}
