//
//  CountryDetailView.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import SwiftUI
import MapKit

// Composant réutilisable : Affiche une ligne d'information avec une icône, un label et une valeur
struct InfoCard: View {
    let icon: String       // SF Symbol (icône)
    let label: String      // Libellé (ex: "Capitale")
    let value: String      // Valeur (ex: "Paris")

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

// Vue principale pour afficher les informations d’un pays
struct CountryDetailView: View {
    let langCode: String               // Code langue (ex: "fr" pour la France)
    @State private var country: Country?  // Données du pays récupérées via l’API

    var body: some View {
        ScrollView {
            if let country = country {
                VStack(spacing: 20) {

                    // Affichage d’une carte centrée sur la capitale si coordonnées disponibles
                    if let latlng = country.capitalInfo?.latlng, latlng.count == 2 {
                        let coordinate = CLLocationCoordinate2D(latitude: latlng[0], longitude: latlng[1])

                        Map(initialPosition: .region(
                            MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
                            ))
                        ) {
                            // Annotation : nom de la capitale
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

                    // Affichage du nom du pays et de son drapeau
                    VStack(spacing: 12) {
                        Text(country.name.common)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.primary)

                        // Image du drapeau (AsyncImage depuis URL)
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

                    // Carte d'informations sur le pays
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
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding()
            } else {
                // Affiche un indicateur de chargement si les données du pays ne sont pas encore disponibles
                ProgressView("Chargement…")
                    .padding()
            }
        }
        .background(Color(UIColor.systemBackground)) // S’adapte au thème clair/sombre

        // Charge les données du pays au chargement de la vue
        .onAppear {
            CountryService.fetchByCode(langCode) { result in
                self.country = result.first
            }
        }

        // Navigation
        .navigationTitle("Détails du pays")
        .navigationBarTitleDisplayMode(.inline)

        // Icône paramètres (accès universel)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                }
            }
        }
    }

    // Formate la liste des monnaies (ex: "Euro (EUR)")
    private func currencyList(from currencies: [String: Currency]?) -> String {
        guard let currencies = currencies else { return "-" }
        return currencies.map { "\($0.value.name ?? "-") (\($0.key))" }.joined(separator: ", ")
    }

    // Formate la liste des langues officielles (ex: "Français, Anglais")
    private func languageList(from languages: [String: String]?) -> String {
        guard let languages = languages else { return "-" }
        return languages.map { $0.value }.joined(separator: ", ")
    }
}

