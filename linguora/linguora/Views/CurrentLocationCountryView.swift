//
//  CurrentLocationCountryView.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import SwiftUI
import MapKit
import CoreLocation

// Vue qui affiche les infos du pays correspondant à la position actuelle de l’utilisateur
struct CurrentLocationCountryView: View {
    @StateObject private var locationManager = LocationManager() // Gestion de la géolocalisation
    @State private var country: Country?                         // Données du pays détecté
    @State private var region = MKCoordinateRegion(             // Région affichée sur la carte
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522), // Paris par défaut
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )

    var body: some View {
        ScrollView {
            if let country = country {
                VStack(spacing: 20) {

                    // Carte affichant la position de l’utilisateur
                    if let location = locationManager.currentLocation {
                        Map(initialPosition: .region(region)) {
                            UserAnnotation() // Point bleu natif de l’utilisateur

                            // Affichage du nom de la ville en annotation
                            if let city = locationManager.currentCity {
                                Annotation("city-label", coordinate: location.coordinate) {
                                    Text(city)
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.gray.opacity(0.7))
                                        .cornerRadius(8)
                                        .shadow(radius: 3)
                                }
                            }
                        }
                        .frame(height: 250)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .onAppear {
                            region.center = location.coordinate // Mise à jour de la région selon la position
                        }
                    }

                    // Affichage du nom du pays + drapeau
                    VStack(spacing: 12) {
                        Text(country.name.common)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.primary)

                        // Affichage du drapeau via URL
                        if let flagUrl = country.flags?.png, let url = URL(string: flagUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150)
                                    .cornerRadius(12)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }

                    // Carte d’informations générales
                    VStack(spacing: 16) {
                        InfoCard(
                            icon: "building.columns.fill",
                            label: "Capitale",
                            value: country.capital?.first ?? "-"
                        )
                        InfoCard(
                            icon: "creditcard.fill",
                            label: "Monnaie",
                            value: currencyList(from: country.currencies)
                        )
                        InfoCard(
                            icon: "globe",
                            label: "Langues officielles",
                            value: languageList(from: country.languages)
                        )
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground)) // Adaptation au thème
                    .cornerRadius(16)
                }
                .padding()
            } else {
                // Message d’attente pendant la géolocalisation
                ProgressView("Détection de votre pays…")
                    .padding()
            }
        }
        .background(Color(UIColor.systemBackground)) // Arrière-plan adaptatif clair/sombre
        .navigationTitle("Mon pays")                // Titre dans la barre de navigation
        .navigationBarTitleDisplayMode(.inline)

        // Accès aux paramètres depuis la vue
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                }
            }
        }

        // Récupération des données du pays à l’ouverture de la vue
        .onAppear {
            Task {
                // Récupération du code pays ISO via le locationManager
                if let isoCode = await locationManager.getCurrentCountryCode() {
                    // Appel à l’API Rest Countries avec ce code
                    CountryService.fetchByCode(isoCode) { result in
                        self.country = result.first
                    }

                    // Mise à jour de la carte avec la position actuelle
                    if let location = locationManager.currentLocation {
                        region.center = location.coordinate
                    }
                }
            }
        }
    }

    // Formatage des monnaies (ex: Euro (EUR))
    private func currencyList(from currencies: [String: Currency]?) -> String {
        guard let currencies = currencies else { return "-" }
        return currencies.map { "\($0.value.name ?? "-") (\($0.key))" }.joined(separator: ", ")
    }

    // Formatage des langues officielles (ex: Français, Anglais)
    private func languageList(from languages: [String: String]?) -> String {
        guard let languages = languages else { return "-" }
        return languages.map { $0.value }.joined(separator: ", ")
    }
}
