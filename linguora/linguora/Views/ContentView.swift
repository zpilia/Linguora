//
//  ContentView.swift
//  linguora
//
//  Created by Zoé Pilia on 17/07/2025.
//

import SwiftUI

struct ContentView: View {
    // États liés à la traduction
    @State private var inputText = ""                 // Texte à traduire (champ utilisateur)
    @State private var translatedText = ""            // Résultat de la traduction
    @State private var sourceLang = ""                // Code langue source sélectionnée
    @State private var targetLang = ""                // Code langue cible sélectionnée
    @State private var languages: [Language] = []     // Liste des langues disponibles
    @State private var isTranslating = false          // Indicateur de chargement pendant traduction
    @State private var selectedLangCode: String?      // Langue utilisée pour consulter un pays cible
    @State private var isShareSheetPresented = false  // Contrôle de l'affichage de la feuille de partage

    // Gestion des toasts (notifications temporaires)
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Affichage du chargement si les langues ne sont pas encore prêtes
                    if languages.isEmpty {
                        ProgressView("Chargement des langues…")
                    } else {
                        
                        // Sélection des langues source et cible
                        HStack(spacing: 12) {
                            // Picker langue source
                            VStack(alignment: .leading) {
                                Text("Langue source").font(.subheadline)
                                Picker("", selection: $sourceLang) {
                                    Text("🌐").tag("")
                                    ForEach(languages, id: \.language) { lang in
                                        Text("\(flag(for: lang.language)) \(lang.name)").tag(lang.language)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            .frame(maxWidth: .infinity)

                            // Bouton d'inversion des langues
                            Button(action: {
                                let temp = sourceLang
                                sourceLang = targetLang
                                targetLang = temp
                            }) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .padding(8)
                                    .background(Color.gray.opacity(0.15))
                                    .clipShape(Circle())
                            }

                            // Picker langue cible
                            VStack(alignment: .leading) {
                                Text("Langue cible").font(.subheadline)
                                Picker("", selection: $targetLang) {
                                    Text("🌐").tag("")
                                    ForEach(languages, id: \.language) { lang in
                                        Text("\(flag(for: lang.language)) \(lang.name)").tag(lang.language)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // Zone de saisie du texte à traduire
                        Text("Texte à traduire").font(.headline)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $inputText)
                                .padding(4)
                                .background(Color(UIColor.systemBackground))
                            if inputText.isEmpty {
                                Text("Entrez votre texte ici…")
                                    .foregroundColor(.gray)
                                    .padding(12)
                            }
                        }
                        .frame(minHeight: 120)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))

                        // Bouton pour lancer la traduction
                        Button(action: {
                            isTranslating = true
                            TranslationService.translate(inputText, to: targetLang) { result in
                                translatedText = result ?? ""
                                isTranslating = false
                                selectedLangCode = targetLang
                            }
                        }) {
                            HStack {
                                if isTranslating {
                                    ProgressView()
                                }
                                Text("Traduire").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        // Boutons fonctionnels
                        HStack(spacing: 20) {
                            Group {
                                // Navigation vers la traduction par image
                                NavigationLink(destination: ImageTranslationView()) {
                                    Image(systemName: "camera")
                                }

                                // Navigation vers la traduction vocale
                                NavigationLink(destination: VoiceTranslationView()) {
                                    Image(systemName: "mic.fill")
                                }

                                // Navigation vers la traduction de document
                                NavigationLink(destination: DocumentTranslationView()) {
                                    Image(systemName: "doc.text.fill")
                                }

                                // Copier le texte traduit
                                Button(action: {
                                    if !translatedText.isEmpty {
                                        UIPasteboard.general.string = translatedText
                                        showToast("✅ Copié dans le presse-papiers")
                                    }
                                }) {
                                    Image(systemName: "doc.on.doc")
                                }
                                .disabled(translatedText.isEmpty)
                                .opacity(translatedText.isEmpty ? 0.3 : 1)

                                // Partager le texte traduit
                                Button(action: {
                                    if !translatedText.isEmpty {
                                        isShareSheetPresented = true
                                    }
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                .disabled(translatedText.isEmpty)
                                .opacity(translatedText.isEmpty ? 0.3 : 1)

                                // Réinitialiser tous les champs
                                Button(action: {
                                    inputText = ""
                                    translatedText = ""
                                    sourceLang = ""
                                    targetLang = ""
                                    showToast("🔄 Champs réinitialisés")
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                }
                            }
                            .font(.title2)
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                            .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)

                        // Zone d'affichage de la traduction
                        Text("Traduction :").font(.headline)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: .constant(translatedText))
                                .padding(4)
                                .background(Color(UIColor.systemBackground))
                                .disabled(true)
                            if translatedText.isEmpty {
                                Text("La traduction apparaîtra ici…")
                                    .foregroundColor(.gray)
                                    .padding(12)
                            }
                        }
                        .frame(minHeight: 120)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))

                        // Navigation vers les informations des pays
                        HStack(spacing: 12) {
                            // Pays cible en fonction de la langue cible traduite
                            NavigationLink(value: selectedLangCode ?? "") {
                                Text("Pays cible 🌍")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(translatedText.isEmpty ? Color.gray : Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(translatedText.isEmpty)

                            // Pays actuel basé sur la géolocalisation
                            NavigationLink(destination: CurrentLocationCountryView()) {
                                Text("Pays actuel 📍")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Linguora")
            .navigationBarTitleDisplayMode(.inline)

            // Accès aux paramètres
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    }
                }
            }

            // Chargement des langues DeepL
            .onAppear {
                DeepLService.fetchTargetLanguages { langs in
                    self.languages = langs
                }
            }

            // Navigation dynamique vers la vue pays en fonction du code langue
            .navigationDestination(for: String.self) { langCode in
                CountryDetailView(langCode: langCode)
            }

            // Feuille de partage iOS
            .sheet(isPresented: $isShareSheetPresented) {
                ShareSheet(activityItems: [translatedText])
            }

            // Toast de feedback
            .toast(isPresented: $showToast, message: toastMessage)
        }
    }

    // Affichage d’un toast temporaire
    private func showToast(_ message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }

    // Génère le drapeau emoji d’un code langue
    private func flag(for code: String) -> String {
        let base: UInt32 = 127397
        let uppercased = code.prefix(2).uppercased()
        var scalarView = String.UnicodeScalarView()
        for scalar in uppercased.unicodeScalars {
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                scalarView.append(flagScalar)
            }
        }
        return String(scalarView)
    }
}

#Preview {
    ContentView()
}
