//
//  CurrentLocationCountryView.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct CurrentLocationCountryView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var country: Country?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )

    var body: some View {
        ScrollView {
            if let country = country {
                VStack(spacing: 20) {

                    if let location = locationManager.currentLocation {
                        Map(initialPosition: .region(region)) {
                            UserAnnotation() // ✅ Point bleu natif

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
                            region.center = location.coordinate
                        }
                    }

                    // 🇫🇷 Nom & Drapeau
                    VStack(spacing: 12) {
                        Text(country.name.common)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.primary)

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

                    // 🧾 Carte d'infos
                    VStack(spacing: 16) {
                        InfoCard(icon: "building.columns.fill", label: "Capitale", value: country.capital?.first ?? "-")
                        InfoCard(icon: "creditcard.fill", label: "Monnaie", value: currencyList(from: country.currencies))
                        InfoCard(icon: "globe", label: "Langues officielles", value: languageList(from: country.languages))
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding()
            } else {
                ProgressView("Détection de votre pays…")
                    .padding()
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("Mon pays")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                }
            }
        }
        .onAppear {
            Task {
                if let isoCode = await locationManager.getCurrentCountryCode() {
                    CountryService.fetchByCode(isoCode) { result in
                        self.country = result.first
                    }

                    if let location = locationManager.currentLocation {
                        region.center = location.coordinate
                    }
                }
            }
        }
    }

    private func currencyList(from currencies: [String: Currency]?) -> String {
        guard let currencies = currencies else { return "-" }
        return currencies.map { "\($0.value.name ?? "-") (\($0.key))" }.joined(separator: ", ")
    }

    private func languageList(from languages: [String: String]?) -> String {
        guard let languages = languages else { return "-" }
        return languages.map { $0.value }.joined(separator: ", ")
    }
}
