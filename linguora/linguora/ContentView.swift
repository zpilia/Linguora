//
//  ContentView.swift
//  linguora
//
//  Created by Zoé Pilia on 17/07/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var sourceLang = ""
    @State private var targetLang = ""
    @State private var languages: [Language] = []

    @State private var isTranslating = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    if languages.isEmpty {
                        ProgressView("Chargement des langues...")
                    } else {
                        // 🔤 Langue source
                        Text("Langue source")
                            .font(.headline)
                        Picker("Langue source", selection: $sourceLang) {
                            Text("Sélectionner une langue").tag("")
                            ForEach(languages, id: \.language) { lang in
                                Text(lang.name).tag(lang.language)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        // 📝 Zone de texte
                        Text("Texte à traduire")
                            .font(.headline)
                        TextEditor(text: $inputText)
                            .frame(minHeight: 120)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.4))
                            )

                        // 🌍 Langue cible
                        Text("Langue cible")
                            .font(.headline)
                        Picker("Langue cible", selection: $targetLang) {
                            Text("Sélectionner une langue").tag("")
                            ForEach(languages, id: \.language) { lang in
                                Text(lang.name).tag(lang.language)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        // 🔘 Bouton Traduire
                        Button(action: {
                            translate()
                        }) {
                            HStack {
                                if isTranslating {
                                    ProgressView()
                                }
                                Text("Traduire")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        // 🧾 Résultat
                        if !translatedText.isEmpty {
                            Text("Traduction :")
                                .font(.headline)
                            Text(translatedText)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Linguora")
            .onAppear {
                DeepLService.fetchTargetLanguages { langs in
                    self.languages = langs
                    // Aucune valeur par défaut — l'utilisateur choisit
                }
            }
        }
    }

    private func translate() {
        let cleanedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedText.isEmpty else {
            translatedText = "❗️Entrez un texte à traduire."
            return
        }

        guard !targetLang.isEmpty else {
            translatedText = "❗️Veuillez choisir une langue cible."
            return
        }

        isTranslating = true
        DeepLService.translate(text: cleanedText, to: targetLang) { result in
            isTranslating = false
            translatedText = result ?? "❌ Erreur de traduction."
        }
    }
}

#Preview {
    ContentView()
}
