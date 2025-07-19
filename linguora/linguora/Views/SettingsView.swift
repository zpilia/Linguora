//
//  SettingsView.swift
//  linguora
//
//  Created by Zoé Pilia on 20/07/2025.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "Système"
        case .light: return "Clair"
        case .dark: return "Sombre"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme: String = AppTheme.system.rawValue

    var body: some View {
        Form {
            Section(header: Text("Apparence")) {
                Picker("Thème", selection: $selectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Paramètres")
        .background(Color(UIColor.systemBackground))
    }
}


#Preview {
    SettingsView()
}
