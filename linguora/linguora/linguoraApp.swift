//
//  linguoraApp.swift
//  linguora
//
//  Created by Zoé Pilia on 17/07/2025.
//

import SwiftUI

// Point d'entrée principal de l'application SwiftUI
@main
struct linguoraApp: App {
    // Lecture du thème sélectionné dans les préférences utilisateur (UserDefaults)
    @AppStorage("selectedTheme") private var selectedTheme: String = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            // Conteneur de navigation principal de l'app
            NavigationStack {
                ContentView() // Vue principale (accueil ou dashboard)
            }
            // Application du thème clair/sombre en fonction du choix utilisateur
            .preferredColorScheme(resolveColorScheme())
        }
    }

    // Fonction qui convertit la chaîne sauvegardée en `AppTheme`, puis retourne le bon `ColorScheme`
    private func resolveColorScheme() -> ColorScheme? {
        AppTheme(rawValue: selectedTheme)?.colorScheme
    }
}
