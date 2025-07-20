//
//  SettingsView.swift
//  linguora
//
//  Created by Zoé Pilia on 20/07/2025.
//

import SwiftUI

// Enumération des thèmes disponibles dans l'app
enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    // Identifiant unique pour chaque case (utilisé par SwiftUI)
    var id: String { rawValue }

    // Nom lisible du thème affiché dans le Picker
    var displayName: String {
        switch self {
        case .system: return "Système"
        case .light: return "Clair"
        case .dark: return "Sombre"
        }
    }

    // Association du thème avec ColorScheme de SwiftUI
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil         // Utilise le mode iOS par défaut
        case .light: return .light       // Force le mode clair
        case .dark: return .dark         // Force le mode sombre
        }
    }
}

struct SettingsView: View {
    // Sauvegarde du thème sélectionné dans UserDefaults avec AppStorage
    @AppStorage("selectedTheme") private var selectedTheme: String = AppTheme.system.rawValue

    var body: some View {
        Form {
            // Section permettant de choisir le thème (apparence)
            Section(header: Text("Apparence")) {
                Picker("Thème", selection: $selectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle()) // Affichage horizontal stylé
            }

            // Section affichant la version actuelle de l’app
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Paramètres") // Titre dans la barre de navigation
        .background(Color(UIColor.systemBackground)) // Respecte le thème système
    }
}

#Preview {
    SettingsView()
}
