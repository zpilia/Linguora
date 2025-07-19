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
                        // 🌐 Langues source et cible
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

                        // 📝 Zone de texte à traduire
                        Text("Texte à traduire").font(.headline)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $inputText)
                                .padding(4)
                                .background(Color.clear)
                            if inputText.isEmpty {
                                Text("Entrez votre texte ici...")
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
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        // 📷🎤📄 Boutons image, micro, document
                        HStack(spacing: 30) {
                            NavigationLink(destination: ImageTranslationView()) {
                                Image(systemName: "camera")
                                    .font(.title2)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Traduire depuis une image")

                            NavigationLink(destination: VoiceTranslationView()) {
                                Image(systemName: "mic.fill")
                                    .font(.title2)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Traduire avec la voix")

                            NavigationLink(destination: DocumentTranslationView()) {
                                Image(systemName: "doc.text.fill")
                                    .font(.title2)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Traduire un document")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                        .frame(maxWidth: .infinity, alignment: .center)

                        // 🧾 Zone de traduction
                        Text("Traduction :").font(.headline)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: .constant(translatedText))
                                .padding(4)
                                .background(Color.clear)
                                .disabled(true)
                            if translatedText.isEmpty {
                                Text("La traduction apparaîtra ici...")
                                    .foregroundColor(.gray)
                                    .padding(12)
                            }
                        }
                        .frame(minHeight: 120)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                    }
                }
                .padding()
            }
            .navigationTitle("Linguora")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                DeepLService.fetchTargetLanguages { langs in
                    self.languages = langs
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
