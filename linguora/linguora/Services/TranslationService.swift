//
//  TranslationService.swift
//  linguora
//
//  Created by Zoé Pilia on 18/07/2025.
//

import Foundation

class TranslationService {
    static func translate(_ text: String, to targetLang: String, completion: @escaping (String?) -> Void) {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedText.isEmpty else {
            completion("❗️Entrez un texte à traduire.")
            return
        }
        
        guard !targetLang.isEmpty else {
            completion("❗️Veuillez choisir une langue cible.")
            return
        }

        DeepLService.translate(text: cleanedText, to: targetLang) { result in
            completion(result ?? "❌ Erreur de traduction.")
        }
    }
}
