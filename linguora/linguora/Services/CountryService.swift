//
//  CountryService.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//
import Foundation

// MARK: - Modèles

struct Country: Decodable {
    let name: CountryName
    let capital: [String]?
    let region: String?
    let subregion: String?
    let languages: [String: String]?
    let currencies: [String: Currency]?
    let flags: Flag?
    let cca2: String?
    let cca3: String?
    let cioc: String?
    let capitalInfo: CapitalInfo?
}

struct CountryName: Decodable {
    let common: String
    let official: String
}

struct Currency: Decodable {
    let name: String
    let symbol: String?
}

struct Flag: Decodable {
    let png: String?
    let svg: String?
}

struct CapitalInfo: Decodable {
    let latlng: [Double]?
}

// MARK: - Service

class CountryService {
    private static let baseURL = "https://restcountries.com/v3.1"
    
    private static func fetchCountries(from endpoint: String, fields: [String] = [], completion: @escaping ([Country]) -> Void) {
        var urlString = "\(baseURL)/\(endpoint)"
        if !fields.isEmpty {
            let joined = fields.joined(separator: ",")
            urlString += "?fields=\(joined)"
        }

        guard let url = URL(string: urlString) else {
            print("❌ URL invalide : \(urlString)")
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Erreur réseau :", error)
                completion([])
                return
            }
            guard let data = data else {
                print("❌ Pas de données")
                completion([])
                return
            }

            do {
                let countries = try JSONDecoder().decode([Country].self, from: data)
                DispatchQueue.main.async { completion(countries) }
            } catch {
                print("❌ Erreur décodage :", error)
                completion([])
            }
        }.resume()
    }

    // MARK: - Requêtes principales
    static func fetchAll(fields: [String] = [], completion: @escaping ([Country]) -> Void) {
        fetchCountries(from: "all", fields: fields, completion: completion)
    }

    static func fetchByName(_ name: String, fullText: Bool = false, fields: [String] = [], completion: @escaping ([Country]) -> Void) {
        let query = fullText ? "name/\(name)?fullText=true" : "name/\(name)"
        fetchCountries(from: query, fields: fields, completion: completion)
    }

    static func fetchByCode(_ code: String, completion: @escaping ([Country]) -> Void) {
        fetchCountries(from: "alpha/\(code)", completion: completion)
    }

    static func fetchByCodes(_ codes: [String], completion: @escaping ([Country]) -> Void) {
        let joined = codes.joined(separator: ",")
        fetchCountries(from: "alpha?codes=\(joined)", completion: completion)
    }

    static func fetchByCurrency(_ currency: String, fields: [String] = [], completion: @escaping ([Country]) -> Void) {
        fetchCountries(from: "currency/\(currency)", fields: fields, completion: completion)
    }

    static func fetchByDemonym(_ demonym: String, fields: [String] = [], completion: @escaping ([Country]) -> Void) {
        fetchCountries(from: "demonym/\(demonym)", fields: fields, completion: completion)
    }

    static func fetchByLanguage(_ language: String, fields: [String] = [], completion: @escaping ([Country]) -> Void) {
        fetchCountries(from: "lang/\(language)", fields: fields, completion: completion)
    }

    static func fetchByCapital(_ capital: String, fields: [String] = [], completion: @escaping ([Country]) -> Void) {
        fetchCountries(from: "capital/\(capital)", fields: fields, completion: completion)
    }

    static func fetchByRegion(_ region: String, fields: [String] = [], completion: @escaping ([Country]) -> Void) {
        fetchCountries(from: "region/\(region)", fields: fields, completion: completion)
    }

    static func fetchBySubregion(_ subregion: String, fields: [String] = [], completion: @escaping ([Country]) -> Void) {
        fetchCountries(from: "subregion/\(subregion)", fields: fields, completion: completion)
    }

    static func fetchByTranslation(_ translation: String, fields: [String] = [], completion: @escaping ([Country]) -> Void) {
        fetchCountries(from: "translation/\(translation)", fields: fields, completion: completion)
    }

    // MARK: - Détection automatique via code langue
    static func fetchFromLanguageCode(_ langCode: String, completion: @escaping (Country?) -> Void) {
        fetchByLanguage(langCode) { countries in
            if countries.isEmpty {
                print("❌ Aucun pays trouvé pour le code langue '\(langCode)'")
                completion(nil)
            } else {
                completion(countries.first)
            }
        }
    }
}
