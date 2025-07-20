//
//  ImageTranslationView.swift
//  linguora
//
//  Created by Zoé Pilia on 18/07/2025.
//

import SwiftUI
import Vision
import PhotosUI

struct ImageTranslationView: View {
    // Gère l'affichage du sélecteur d'image et la source choisie (appareil ou galerie)
    @State private var showImagePicker = false
    @State private var showSourceDialog = false
    @State private var selectedImage: UIImage?
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    // Texte détecté et texte traduit
    @State private var extractedText = ""
    @State private var translatedText = ""
    @State private var isTranslating = false

    // Langue cible + liste des langues
    @State private var targetLang = ""
    @State private var languages: [Language] = []
    @State private var showShareSheet = false

    // Toast pour retour utilisateur
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Titre de la page
                Text("Traduction par image")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)

                // Zone d'affichage ou de sélection d'image
                ZStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(10)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(height: 150)
                            .overlay(Text("Aucune image sélectionnée").foregroundColor(.gray))
                    }
                }

                // Bouton pour choisir l’image (appareil photo ou galerie)
                Button {
                    showSourceDialog = true
                } label: {
                    Label("Prendre ou choisir une photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .confirmationDialog("Choisir une source", isPresented: $showSourceDialog) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button("Appareil photo") {
                            imagePickerSource = .camera
                            showImagePicker = true
                        }
                    }
                    Button("Galerie") {
                        imagePickerSource = .photoLibrary
                        showImagePicker = true
                    }
                    Button("Annuler", role: .cancel) {}
                }

                // Zone affichant le texte extrait
                VStack(alignment: .leading) {
                    Text("Texte extrait :").font(.headline).foregroundColor(.primary)
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: .constant(extractedText))
                            .padding(4)
                            .disabled(true)
                        if extractedText.isEmpty {
                            Text("Le texte détecté apparaîtra ici...")
                                .foregroundColor(.gray)
                                .padding(12)
                        }
                    }
                    .frame(minHeight: 100)
                    .background(Color(UIColor.systemBackground))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                }

                // Sélection de la langue cible + bouton Traduire
                if languages.isEmpty {
                    ProgressView("Chargement des langues…")
                } else {
                    HStack(spacing: 12) {
                        Picker("", selection: $targetLang) {
                            Text("🌐").tag("")
                            ForEach(languages, id: \.language) { lang in
                                Text("\(flag(for: lang.language)) \(lang.name)").tag(lang.language)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 160)
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)

                        Button {
                            translateText()
                        } label: {
                            HStack {
                                if isTranslating { ProgressView() }
                                Text("Traduire")
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(extractedText.isEmpty || targetLang.isEmpty)
                    }
                }

                // Zone de texte traduit
                VStack(alignment: .leading) {
                    Text("Traduction :").font(.headline).foregroundColor(.primary)
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: .constant(translatedText))
                            .padding(4)
                            .disabled(true)
                        if translatedText.isEmpty {
                            Text("La traduction apparaîtra ici…")
                                .foregroundColor(.gray)
                                .padding(12)
                        }
                    }
                    .frame(minHeight: 100)
                    .background(Color(UIColor.systemBackground))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                }

                // Boutons d'action : copier, partager, réinitialiser
                HStack(spacing: 30) {
                    // Copier dans le presse-papier
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

                    // Partager
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

                    // Réinitialiser
                    Button {
                        selectedImage = nil
                        extractedText = ""
                        translatedText = ""
                        targetLang = ""
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
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        
        // Affiche le sélecteur d’image
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSource, selectedImage: $selectedImage)
                .onDisappear {
                    if let image = selectedImage {
                        extractText(from: image)
                    }
                }
        }

        // Feuille de partage avec le texte traduit
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [translatedText])
        }

        // Bouton pour accéder aux paramètres
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                }
            }
        }

        // Chargement des langues à l’ouverture
        .onAppear {
            DeepLService.fetchTargetLanguages { langs in
                self.languages = langs
            }
        }

        // Affichage d’un toast (message temporaire)
        .toast(isPresented: $showToast, message: toastMessage)
    }

    // Extraction OCR avec Vision
    private func extractText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest { request, _ in
            if let results = request.results as? [VNRecognizedTextObservation] {
                let text = results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                DispatchQueue.main.async {
                    self.extractedText = text
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }

    // Traduction du texte extrait via DeepL
    private func translateText() {
        isTranslating = true
        DeepLService.translate(text: extractedText, to: targetLang) { result in
            DispatchQueue.main.async {
                isTranslating = false
                translatedText = result ?? "❌ Erreur de traduction"
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
    ImageTranslationView()
}
