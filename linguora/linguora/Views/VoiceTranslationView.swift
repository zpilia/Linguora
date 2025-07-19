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

    @StateObject private var speechRecognizer = SpeechRecognizer()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if languages.isEmpty {
                    ProgressView("Chargement des langues...")
                } else {
                    // 🌐 Langue source / cible
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

                    // 🎤 Zone texte reconnue
                    Text("Texte reconnu").font(.headline)
                    TextEditor(text: $recognizedText)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                        .disabled(true)

                    // 🔘 Bouton micro
                    Button(action: {
                        isListening.toggle()
                        if isListening {
                            speechRecognizer.startRecognition { text in
                                recognizedText = text
                                
                                // 🌐 Traduction automatique dès que texte est détecté
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

                    // 🧾 Texte traduit
                    Text("Traduction").font(.headline)
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: .constant(translatedText))
                            .frame(height: 100)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                            .disabled(true)
                        if translatedText.isEmpty {
                            Text(isTranslating ? "Traduction en cours..." : "La traduction apparaîtra ici...")
                                .foregroundColor(.gray)
                                .padding(12)
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                speechRecognizer.requestAuthorization()
                DeepLService.fetchTargetLanguages { langs in
                    self.languages = langs
                }
            }
        }
        .navigationTitle("Traduction vocale")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    VoiceTranslationView()
}
