//
//  DocumentTranslationView.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentTranslationView: View {
    // Nom du fichier sélectionné
    @State private var selectedFileName: String = ""

    // Statut de la traduction (upload, processing, done, etc.)
    @State private var translationStatus: String = ""

    // Indique si une traduction est en cours
    @State private var isTranslating = false

    // Contrôle l’ouverture du panneau de partage
    @State private var showShareSheet = false

    // URL du fichier traduit
    @State private var translatedFileURL: URL?

    // Délégué pour le sélecteur de document
    @State private var documentPickerDelegate: DocumentPickerDelegateWrapper?

    // Langue source et cible
    @State private var targetLang: String? = nil
    @State private var sourceLang: String? = nil

    // Liste des langues DeepL
    @State private var languages: [Language] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Titre de la section
                Text("Traduction de document")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)

                // Chargement des langues depuis l’API
                if languages.isEmpty {
                    ProgressView("Chargement des langues…")
                } else {
                    // Sélecteurs de langues
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Langue source (optionnelle)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("", selection: $sourceLang) {
                            Text("🌐 Détection automatique").tag(String?.none)
                            ForEach(languages, id: \.language) { lang in
                                Text("\(flag(for: lang.language)) \(lang.name)").tag(Optional(lang.language))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)

                        Text("Langue cible")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("", selection: $targetLang) {
                            Text("🌐 Choisir une langue").tag(String?.none)
                            ForEach(languages, id: \.language) { lang in
                                Text("\(flag(for: lang.language)) \(lang.name)").tag(Optional(lang.language))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }

                // Bouton pour importer et traduire un document
                Button(action: importDocument) {
                    Label("Importer et traduire un document", systemImage: "arrow.down.doc")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((targetLang?.isEmpty ?? true) ? Color.gray : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(targetLang?.isEmpty ?? true)

                // Affichage du nom du fichier sélectionné
                if !selectedFileName.isEmpty {
                    Text("Fichier sélectionné : **\(selectedFileName)**")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary)
                }

                // Indicateur pendant la traduction
                if isTranslating {
                    ProgressView("Traduction en cours…")
                }

                // Affichage du statut de traduction
                if !translationStatus.isEmpty {
                    Text("Statut : \(translationStatus)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary)
                }

                // Bouton de partage du fichier traduit
                if let fileURL = translatedFileURL {
                    Button("Partager le fichier traduit") {
                        showShareSheet = true
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .sheet(isPresented: $showShareSheet) {
                        ShareSheet(activityItems: [fileURL])
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground)) // Fond adaptatif (clair/sombre)
        .navigationTitle("Document")

        // Icône menant à la vue des paramètres
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                }
            }
        }

        // Chargement des langues à l’apparition de la vue
        .onAppear {
            DeepLService.fetchTargetLanguages { langs in
                self.languages = langs.sorted { $0.name < $1.name }
                self.targetLang = nil
                self.sourceLang = nil
            }
        }
    }

    // Fonction pour importer un document et lancer la traduction
    private func importDocument() {
        guard let targetLang = targetLang, !targetLang.isEmpty else {
            translationStatus = "❗️Veuillez sélectionner une langue cible."
            return
        }

        // Types de fichiers autorisés
        let types: [UTType] = [
            .pdf, .plainText, .rtf, .text,
            UTType(filenameExtension: "docx")!,
            UTType(filenameExtension: "doc")!
        ]

        // Création du sélecteur de fichiers
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = false

        // Délégué pour gérer l'import et le workflow DeepL
        let delegate = DocumentPickerDelegateWrapper { url in
            selectedFileName = url.lastPathComponent
            isTranslating = true
            translationStatus = "📤 Téléversement du document…"

            // Envoi du document à DeepL
            DeepLService.uploadDocument(
                fileURL: url,
                targetLang: targetLang,
                sourceLang: sourceLang
            ) { documentId, documentKey in
                guard let documentId = documentId, let documentKey = documentKey else {
                    translationStatus = "❌ Erreur lors de l’envoi du document."
                    isTranslating = false
                    return
                }

                translationStatus = "📬 Document envoyé. Vérification du statut…"

                // Vérification périodique du statut
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                    DeepLService.checkDocumentStatus(documentId: documentId, documentKey: documentKey) { status in
                        guard let status = status else {
                            translationStatus = "❌ Erreur lors du suivi."
                            timer.invalidate()
                            isTranslating = false
                            return
                        }

                        translationStatus = "🔄 Statut : \(status.capitalized)"

                        if status.lowercased() == "done" {
                            timer.invalidate()
                            translationStatus = "📥 Téléchargement du fichier traduit…"

                            // Téléchargement du fichier traduit
                            DeepLService.downloadTranslatedDocument(documentId: documentId, documentKey: documentKey) { data in
                                guard let data = data else {
                                    translationStatus = "❌ Erreur lors du téléchargement."
                                    isTranslating = false
                                    return
                                }

                                let tempURL = FileManager.default.temporaryDirectory
                                    .appendingPathComponent("translated_\(selectedFileName)")

                                do {
                                    try data.write(to: tempURL)
                                    translatedFileURL = tempURL
                                    translationStatus = "✅ Traduction terminée"
                                } catch {
                                    translationStatus = "❌ Erreur de sauvegarde : \(error.localizedDescription)"
                                }

                                isTranslating = false
                            }
                        } else if status.lowercased() == "error" {
                            timer.invalidate()
                            translationStatus = "❌ Erreur de traduction"
                            isTranslating = false
                        }
                    }
                }
            }
        }

        self.documentPickerDelegate = delegate
        picker.delegate = delegate

        // Présentation du document picker sur la vue courante
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(picker, animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        DocumentTranslationView()
    }
}
