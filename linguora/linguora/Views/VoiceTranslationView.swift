//
//  VoiceTranslationView.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import SwiftUI
import Speech
import AVFoundation

struct VoiceTranslationView: View {
    @State private var recognizedText = ""
    @State private var translatedText = ""
    @State private var isListening = false
    @State private var isTranslating = false
    @State private var sourceLang = ""
    @State private var targetLang = ""
    @State private var languages: [Language] = []

    @State private var showShareSheet = false
    @State private var showToast = false
    @State private var toastMessage = ""

    @StateObject private var speechRecognizer = SpeechRecognizer()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if languages.isEmpty {
                    ProgressView("Chargement des langues...")
                } else {
                    // Langue source / cible
                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("Langue source").font(.subheadline).foregroundColor(.primary)
                            Picker("", selection: $sourceLang) {
                                Text("🌐").tag("")
                                ForEach(languages, id: \.language) { lang in
                                    Text("\(flag(for: lang.language)) \(lang.name)").tag(lang.language)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity)
                            .padding(2)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }

                        Button(action: {
                            let temp = sourceLang
                            sourceLang = targetLang
                            targetLang = temp
                        }) {
                            Image(systemName: "arrow.left.arrow.right")
                                .padding(10)
                                .background(Color.gray.opacity(0.15))
                                .clipShape(Circle())
                        }

                        VStack(alignment: .leading) {
                            Text("Langue cible").font(.subheadline).foregroundColor(.primary)
                            Picker("", selection: $targetLang) {
                                Text("🌐").tag("")
                                ForEach(languages, id: \.language) { lang in
                                    Text("\(flag(for: lang.language)) \(lang.name)").tag(lang.language)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity)
                            .padding(2)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }

                    // Zone texte reconnue
                    Text("Texte reconnu").font(.headline).foregroundColor(.primary)
                    TextEditor(text: $recognizedText)
                        .frame(height: 100)
                        .padding(4)
                        .background(Color(UIColor.systemBackground))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                        .disabled(true)

                    // Bouton micro
                    Button(action: {
                        isListening.toggle()
                        if isListening {
                            speechRecognizer.startRecognition { text in
                                recognizedText = text
                                isTranslating = true
                                TranslationService.translate(text, to: targetLang) { result in
                                    DispatchQueue.main.async {
                                        translatedText = result ?? ""
                                        isTranslating = false
                                    }
                                }
                            }
                        } else {
                            speechRecognizer.stopRecognition()
                        }
                    }) {
                        Image(systemName: isListening ? "stop.circle.fill" : "mic.circle.fill")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .foregroundColor(isListening ? .red : .blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    // Texte traduit
                    Text("Traduction").font(.headline).foregroundColor(.primary)
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: .constant(translatedText))
                            .frame(height: 100)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                            .disabled(true)

                        if translatedText.isEmpty {
                            Text(isTranslating ? "Traduction en cours..." : "La traduction apparaîtra ici…")
                                .foregroundColor(.gray)
                                .padding(12)
                        }
                    }

                    // Boutons actions
                    HStack(spacing: 30) {
                        Button {
                            if !translatedText.isEmpty {
                                UIPasteboard.general.string = translatedText
                                showToast("✅ Copié dans le presse-papiers")
                            }
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.title2)
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }

                        Button {
                            if !translatedText.isEmpty {
                                showShareSheet = true
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }

                        Button {
                            recognizedText = ""
                            translatedText = ""
                            showToast("🔄 Champs réinitialisés")
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            speechRecognizer.requestAuthorization()
            DeepLService.fetchTargetLanguages { langs in
                self.languages = langs
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [translatedText])
        }
        .toast(isPresented: $showToast, message: toastMessage)
        .navigationTitle("Traduction vocale")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                }
            }
        }
    }

    // Génère un drapeau depuis un code de langue
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

    // Affiche un toast avec un message personnalisé
    private func showToast(_ message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
}

#Preview {
    VoiceTranslationView()
}
