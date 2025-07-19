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
    @State private var selectedLangCode: String?
    @State private var isShareSheetPresented = false

    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if languages.isEmpty {
                        ProgressView("Chargement des langues…")
                    } else {
                        // 🌐 Sélection des langues
                        HStack(spacing: 12) {
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

                        // 📝 Texte à traduire
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

                        // 🔘 Bouton Traduire
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

                        // 📷🎤📄📋🔁🔗 Boutons fonctionnels
                        HStack(spacing: 20) {
                            Group {
                                NavigationLink(destination: ImageTranslationView()) {
                                    Image(systemName: "camera")
                                }

                                NavigationLink(destination: VoiceTranslationView()) {
                                    Image(systemName: "mic.fill")
                                }

                                NavigationLink(destination: DocumentTranslationView()) {
                                    Image(systemName: "doc.text.fill")
                                }

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

                                Button(action: {
                                    if !translatedText.isEmpty {
                                        isShareSheetPresented = true
                                    }
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                .disabled(translatedText.isEmpty)
                                .opacity(translatedText.isEmpty ? 0.3 : 1)

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

                        // 🧾 Zone de traduction
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

                        // 🌍 Liens vers les vues des pays
                        HStack(spacing: 12) {
                            NavigationLink(value: selectedLangCode ?? "") {
                                Text("Pays cible 🌍")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(translatedText.isEmpty ? Color.gray : Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(translatedText.isEmpty)

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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    }
                }
            }
            .onAppear {
                DeepLService.fetchTargetLanguages { langs in
                    self.languages = langs
                }
            }
            .navigationDestination(for: String.self) { langCode in
                CountryDetailView(langCode: langCode)
            }
            .sheet(isPresented: $isShareSheetPresented) {
                ShareSheet(activityItems: [translatedText])
            }
            .toast(isPresented: $showToast, message: toastMessage)
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }

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
