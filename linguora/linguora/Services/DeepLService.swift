//
//  ContentView.swift
//  linguora
//
//  Created by Zoé Pilia on 17/07/2025.
//

import Foundation

/// Représente une langue disponible
struct Language: Decodable {
    let language: String   // Code langue (ex: "FR")
    let name: String       // Nom lisible (ex: "French")
}

/// Service pour gérer les langues, traductions et documents.
enum DeepLService {
    static let apiKey = Secrets.deeplAPIKey
    static let baseURL = "https://api-free.deepl.com/v2"

    // MARK: - Langues disponibles

    /// Récupère la liste des langues cibles supportées.
    /// - Parameter completion: Callback avec tableau de `Language`.
    static func fetchTargetLanguages(completion: @escaping ([Language]) -> Void) {
        guard let url = URL(string: "\(baseURL)/languages?type=target") else {
            print("❌ URL invalide")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Erreur réseau :", error)
                return
            }

            guard let data = data else {
                print("❌ Pas de données")
                return
            }

            do {
                let languages = try JSONDecoder().decode([Language].self, from: data)
                DispatchQueue.main.async { completion(languages) }
            } catch {
                print("❌ Erreur décodage :", error)
            }
        }.resume()
    }

    // MARK: - Traduction texte
    /// Traduit une chaîne de texte vers une langue cible.
    /// - Parameters:
    ///   - text: Texte à traduire.
    ///   - targetLang: Code langue cible (ex: "FR").
    ///   - completion: Callback avec le texte traduit ou `nil`.
    static func translate(text: String, to targetLang: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/translate") else {
            print("❌ URL invalide")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")

        let bodyParams = "text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&target_lang=\(targetLang)"
        request.httpBody = bodyParams.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Erreur :", error)
                completion(nil)
                return
            }

            guard let data = data else {
                print("❌ Pas de données")
                completion(nil)
                return
            }

            do {
                let result = try JSONDecoder().decode(DeepLTranslationResponse.self, from: data)
                completion(result.translations.first?.text)
            } catch {
                print("❌ Erreur décodage :", error)
                completion(nil)
            }
        }.resume()
    }

    // MARK: - Upload document
    /// Envoie un document à traduire vers DeepL.
    /// - Parameters:
    ///   - fileURL: URL locale du fichier.
    ///   - targetLang: Langue cible (optionnelle).
    ///   - sourceLang: Langue source (optionnelle).
    ///   - formality: Niveau de formalité ("default", "less", "more").
    ///   - completion: Retourne l'ID et la clé du document.
    static func uploadDocument(
        fileURL: URL,
        targetLang: String? = nil,
        sourceLang: String? = nil,
        formality: String = "default",
        completion: @escaping (String?, String?) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/document") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()

        func appendFormField(_ name: String, value: String) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)\r\n".data(using: .utf8)!)
        }

        // Champs principaux (uniquement si renseignés)
        if let targetLang = targetLang, !targetLang.isEmpty {
            appendFormField("target_lang", value: targetLang)
        }

        appendFormField("formality", value: formality)

        if let sourceLang = sourceLang, !sourceLang.isEmpty {
            appendFormField("source_lang", value: sourceLang)
        }

        // Nom du fichier
        appendFormField("filename", value: fileURL.lastPathComponent)

        // Format de sortie si reconnu
        let ext = fileURL.pathExtension.lowercased()
        let knownFormats = ["pdf", "docx", "pptx", "html", "txt"]
        if knownFormats.contains(ext) {
            appendFormField("output_format", value: ext)
        }

        // Partie fichier
        if let fileData = try? Data(contentsOf: fileURL) {
            let filename = fileURL.lastPathComponent
            let mimeType = mimeTypeForExtension(ext)

            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            data.append("\r\n".data(using: .utf8)!)
        }

        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = data

        // Lancer la requête
        URLSession.shared.dataTask(with: request) { responseData, _, error in
            if let error = error {
                print("❌ Erreur upload :", error)
                completion(nil, nil)
                return
            }

            guard let responseData = responseData else {
                print("❌ Pas de réponse")
                completion(nil, nil)
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let documentId = json["document_id"] as? String,
               let documentKey = json["document_key"] as? String {
                print("✅ Document envoyé : ID = \(documentId), Clé = \(documentKey)")
                completion(documentId, documentKey)
            } else {
                print("❌ Erreur parsing upload :", String(data: responseData, encoding: .utf8) ?? "aucune donnée lisible")
                completion(nil, nil)
            }
        }.resume()
    }


    // MARK: - Déterminer le type MIME selon l’extension
    
    /// Déduit le type MIME à partir d'une extension.
    /// - Parameter ext: Extension de fichier (ex: "pdf", "docx").
    /// - Returns: Type MIME correspondant.
    private static func mimeTypeForExtension(_ ext: String) -> String {
        switch ext {
        case "pdf": return "application/pdf"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "txt": return "text/plain"
        case "rtf": return "application/rtf"
        case "html": return "text/html"
        case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        default: return "application/octet-stream"
        }
    }

    // MARK: - Statut du document
    
    /// Vérifie l'état de la traduction d’un document.
    /// - Parameters:
    ///   - documentId: ID retourné lors de l’upload.
    ///   - documentKey: Clé retournée lors de l’upload.
    ///   - completion: Statut actuel du document (ex: "done", "translating", etc.).
    static func checkDocumentStatus(documentId: String, documentKey: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/document/\(documentId)?document_key=\(documentKey)") else {
            print("❌ URL statut invalide")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Erreur statut :", error)
                completion(nil)
                return
            }

            guard let data = data else {
                print("❌ Pas de réponse statut")
                completion(nil)
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                print("📥 Statut reçu : \(status)")
                completion(status)
            } else {
                print("❌ Erreur parsing statut :", String(data: data, encoding: .utf8) ?? "")
                completion(nil)
            }
        }.resume()
    }

    // MARK: - Télécharger fichier traduit
    
    /// Télécharge le fichier traduit depuis DeepL.
    /// - Parameters:
    ///   - documentId: ID du document.
    ///   - documentKey: Clé de sécurité.
    ///   - completion: Contenu binaire du fichier (`Data?`).
    static func downloadTranslatedDocument(documentId: String, documentKey: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: "\(baseURL)/document/\(documentId)/result?document_key=\(documentKey)") else {
            print("❌ URL téléchargement invalide")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Erreur téléchargement :", error)
                completion(nil)
                return
            }

            guard let data = data else {
                print("❌ Pas de données téléchargées")
                completion(nil)
                return
            }

            print("✅ Fichier traduit téléchargé (\(data.count) octets)")
            completion(data)
        }.resume()
    }
}

// MARK: - Modèle réponse texte
/// Représente la réponse JSON retournée par l’API DeepL pour une traduction de texte.
struct DeepLTranslationResponse: Decodable {
    struct Translation: Decodable {
        let text: String // Texte traduit
    }

    let translations: [Translation]
}
