//
//  Secrets.swift
//  linguora
//
//  Created by Zoé Pilia on 17/07/2025.
//
import Foundation

/// Enum utilitaire pour accéder aux clés secrètes stockées localement
enum Secrets {

    /// Récupère la clé API DeepL à partir du fichier Secrets.plist
    static var deeplAPIKey: String {
        // Étape 1 : On récupère l’URL du fichier Secrets.plist depuis le bundle principal
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            
            // Étape 2 : On lit le contenu du fichier sous forme de données
            let data = try? Data(contentsOf: url),
            
            // Étape 3 : On convertit ces données en dictionnaire clé/valeur
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            
            // Étape 4 : On extrait la valeur associée à la clé "DEEPL_API_KEY"
            let key = dict["DEEPL_API_KEY"] as? String
        else {
            // Si l'une des étapes échoue, on arrête l’exécution avec une erreur explicite
            fatalError("❌ Clé API DeepL introuvable dans Secrets.plist")
        }

        // On retourne la clé API valide
        return key
    }
}
