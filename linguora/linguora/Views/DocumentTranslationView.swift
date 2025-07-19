//
//  DocumentTranslationView.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentTranslationView: View {
    @State private var selectedFileName: String = ""
    @State private var translationStatus: String = ""
    @State private var isTranslating = false
    @State private var showShareSheet = false
    @State private var translatedFileURL: URL?
    
    @State private var documentPickerDelegate: DocumentPickerDelegateWrapper?
    
    @State private var targetLang: String? = nil
    @State private var sourceLang: String? = nil
    @State private var languages: [Language] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Traduction de document")
                .font(.title2)
                .bold()
            
            if languages.isEmpty {
                ProgressView("Chargement des langues...")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Langue source (optionnelle)").font(.subheadline)
                    Picker("", selection: $sourceLang) {
                        Text("🌐 Détection automatique").tag(String?.none)
                        ForEach(languages, id: \.language) { lang in
                            Text("\(flag(for: lang.language)) \(lang.name)").tag(Optional(lang.language))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Text("Langue cible").font(.subheadline)
                    Picker("", selection: $targetLang) {
                        Text("🌐 Choisir une langue").tag(String?.none)
                        ForEach(languages, id: \.language) { lang in
                            Text("\(flag(for: lang.language)) \(lang.name)").tag(Optional(lang.language))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            
            Button(action: importDocument) {
                Label("Importer et traduire un document", systemImage: "arrow.down.doc")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background((targetLang?.isEmpty ?? true) ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(targetLang?.isEmpty ?? true)
            
            if !selectedFileName.isEmpty {
                Text("Fichier sélectionné : **\(selectedFileName)**")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if isTranslating {
                ProgressView("Traduction en cours…")
            }
            
            if !translationStatus.isEmpty {
                Text("Statut : \(translationStatus)")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if let fileURL = translatedFileURL {
                Button("Partager le fichier traduit") {
                    showShareSheet = true
                }
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(activityItems: [fileURL])
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Document")
        .onAppear {
            DeepLService.fetchTargetLanguages { langs in
                self.languages = langs.sorted { $0.name < $1.name }
                self.targetLang = nil
                self.sourceLang = nil
            }
        }
    }
    
    private func importDocument() {
        guard let targetLang = targetLang, !targetLang.isEmpty else {
            translationStatus = "❗️Veuillez sélectionner une langue cible."
            return
        }
        
        let types: [UTType] = [
            .pdf, .plainText, .rtf, .text,
            UTType(filenameExtension: "docx")!,
            UTType(filenameExtension: "doc")!
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = false
        
        let delegate = DocumentPickerDelegateWrapper { url in
            selectedFileName = url.lastPathComponent
            isTranslating = true
            translationStatus = "📤 Téléversement du document…"
            
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
