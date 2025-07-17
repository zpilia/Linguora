//
//  DeepLService.swift
//  linguora
//
//  Created by Zoé Pilia on 17/07/2025.
//
import Foundation

struct Language: Decodable {
    let language: String
    let name: String
}

enum DeepLService {
    static func fetchTargetLanguages(completion: @escaping ([Language]) -> Void) {
        let urlString = "https://api-free.deepl.com/v2/languages?type=target"

        guard let url = URL(string: urlString) else {
            print("❌ URL invalide")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("DeepL-Auth-Key \(Secrets.deeplAPIKey)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau :", error.localizedDescription)
                return
            }

            guard let data = data else {
                print("❌ Pas de données")
                return
            }

            do {
                let languages = try JSONDecoder().decode([Language].self, from: data)
                DispatchQueue.main.async {
                    completion(languages)
                }
            } catch {
                print("❌ Erreur de décodage :", error.localizedDescription)
                print(String(data: data, encoding: .utf8) ?? "Contenu brut inconnu")
            }
        }.resume()
    }
    
    static func translate(text: String, to targetLang: String, completion: @escaping (String?) -> Void) {
            guard let url = URL(string: "https://api-free.deepl.com/v2/translate") else {
                print("❌ URL invalide")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let apiKey = Secrets.deeplAPIKey
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")

            let bodyParams = "text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&target_lang=\(targetLang)"
            request.httpBody = bodyParams.data(using: .utf8)

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Erreur : \(error.localizedDescription)")
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
                    print("❌ Erreur de décodage : \(error)")
                    print(String(data: data, encoding: .utf8) ?? "")
                    completion(nil)
                }
            }.resume()
        }
}

struct DeepLTranslationResponse: Decodable {
    struct Translation: Decodable {
        let text: String
    }

    let translations: [Translation]
}
