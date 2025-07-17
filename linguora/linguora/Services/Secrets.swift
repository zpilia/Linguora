//
//  Secrets.swift
//  linguora
//
//  Created by Zoé Pilia on 17/07/2025.
//
import Foundation

enum Secrets {
    static var deeplAPIKey: String {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = dict["DEEPL_API_KEY"] as? String
        else {
            fatalError("❌ Clé API DeepL introuvable dans Secrets.plist")
        }

        return key
    }
}
