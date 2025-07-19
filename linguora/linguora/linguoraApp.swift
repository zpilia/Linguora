//
//  linguoraApp.swift
//  linguora
//
//  Created by Zoé Pilia on 17/07/2025.
//

import SwiftUI

@main
struct linguoraApp: App {
    @AppStorage("selectedTheme") private var selectedTheme: String = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .preferredColorScheme(resolveColorScheme())
        }
    }

    private func resolveColorScheme() -> ColorScheme? {
        AppTheme(rawValue: selectedTheme)?.colorScheme
    }
}
