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
    @State private var showImagePicker = false
    @State private var showSourceDialog = false
    @State private var selectedImage: UIImage?
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    @State private var extractedText = ""
    @State private var translatedText = ""
    @State private var isTranslating = false

    @State private var targetLang = ""
    @State private var languages: [Language] = []
    @State private var showShareSheet = false

    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Traduction par image")
                .font(.largeTitle)
                .bold()

            // 📸 Image affichée
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 150)
                        .overlay(Text("Aucune image sélectionnée").foregroundColor(.gray))
                }
            }

            // 📷 Bouton source image
            Button {
                showSourceDialog = true
            } label: {
                HStack {
                    Image(systemName: "camera")
                    Text("Prendre ou choisir une photo")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .confirmationDialog("Choisir une source", isPresented: $showSourceDialog, titleVisibility: .visible) {
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

            // 🧾 Texte extrait
            VStack(alignment: .leading) {
                Text("Texte extrait :").font(.headline)
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
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
            }

            // 🌍 Langue + bouton Traduire
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
                    .frame(width: 150)

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

            // 💬 Traduction affichée
            VStack(alignment: .leading) {
                Text("Traduction :").font(.headline)
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
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
            }

            // ➕ Boutons : Copier, Partager, Réinitialiser
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

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSource, selectedImage: $selectedImage)
                .onDisappear {
                    if let image = selectedImage {
                        extractText(from: image)
                    }
                }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [translatedText])
        }
        .onAppear {
            DeepLService.fetchTargetLanguages { langs in
                self.languages = langs
            }
        }
        .toast(isPresented: $showToast, message: toastMessage)
    }

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

    private func translateText() {
        isTranslating = true
        DeepLService.translate(text: extractedText, to: targetLang) { result in
            DispatchQueue.main.async {
                isTranslating = false
                translatedText = result ?? "❌ Erreur de traduction"
            }
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
