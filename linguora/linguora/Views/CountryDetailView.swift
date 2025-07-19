//
//  CountryDetailView.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import SwiftUI
import MapKit

struct InfoCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title2)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
                    .bold()
                    .foregroundColor(.primary)
            }
        }
    }
}

struct CountryDetailView: View {
    let langCode: String
    @State private var country: Country?

    var body: some View {
        ScrollView {
            if let country = country {
                VStack(spacing: 20) {
                    
                    // 🗺️ Carte de la capitale
                    if let latlng = country.capitalInfo?.latlng, latlng.count == 2 {
                        let coordinate = CLLocationCoordinate2D(latitude: latlng[0], longitude: latlng[1])
                        
                        Map(initialPosition: .region(
                            MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
                            ))
                        ) {
                            Annotation("Capitale", coordinate: coordinate) {
                                Text(country.capital?.first ?? "Capitale")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.7))
                                    .cornerRadius(8)
                                    .shadow(radius: 3)
                            }
                        }
                        .frame(height: 250)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // 🇫🇷 Nom & Drapeau
                    VStack(spacing: 12) {
                        Text(country.name.common)
                            .font(.largeTitle)
                            .bold()

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
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                .padding()
            } else {
                ProgressView("Chargement…")
                    .padding()
            }
        }
        .onAppear {
            CountryService.fetchByCode(langCode) { result in
                self.country = result.first
            }
        }
        .navigationTitle("Détails du pays")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Formattage des monnaies
    private func currencyList(from currencies: [String: Currency]?) -> String {
        guard let currencies = currencies else { return "-" }
        return currencies.map { "\($0.value.name ?? "-") (\($0.key))" }.joined(separator: ", ")
    }

    // Formattage des langues
    private func languageList(from languages: [String: String]?) -> String {
        guard let languages = languages else { return "-" }
        return languages.map { $0.value }.joined(separator: ", ")
    }
}
