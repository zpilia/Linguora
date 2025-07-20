//
//  TranslationService.swift
//  linguora
//
//  Created by Zoé Pilia on 18/07/2025.
//

import Foundation

/// Service centralisé pour gérer la traduction d’un texte avec vérification préalable
class TranslationService {

    /// Traduit un texte donné vers une langue cible avec gestion d’erreurs de saisie
    /// - Parameters:
    ///   - text: Le texte à traduire
    ///   - targetLang: Le code langue cible (ex: "EN", "FR")
    ///   - completion: Fermeture (callback) appelée avec le texte traduit ou un message d’erreur
    static func translate(_ text: String, to targetLang: String, completion: @escaping (String?) -> Void) {
        
        // On nettoie le texte en supprimant les espaces inutiles au début et à la fin
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Si le texte est vide après nettoyage, on retourne un message d’erreur
        guard !cleanedText.isEmpty else {
            completion("❗️Entrez un texte à traduire.")
            return
        }
        
        // Si aucune langue cible n’est définie, on retourne un message d’erreur
        guard !targetLang.isEmpty else {
            completion("❗️Veuillez choisir une langue cible.")
            return
        }

        // Appel réel à DeepLService pour traduire le texte
        DeepLService.translate(text: cleanedText, to: targetLang) { result in
            // On transmet la traduction obtenue ou un message d’erreur par défaut
            completion(result ?? "❌ Erreur de traduction.")
        }
    }
}

