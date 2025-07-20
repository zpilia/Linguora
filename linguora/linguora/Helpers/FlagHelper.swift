//
//  FlagHelper.swift
//  linguora
//
//  Created by Zoé Pilia on 18/07/2025.
//

import Foundation

/// Convertit un code pays ISO 3166-1 alpha-2 (ex: "fr", "us") en 🇫🇷 emoji drapeau Unicode
func flag(for code: String) -> String {
    // Valeur de base Unicode pour les indicateurs régionaux (🇦 = U+1F1E6 = 127462)
    let base: UInt32 = 127397

    // On prend les 2 premières lettres du code et les met en majuscules
    let uppercased = code.prefix(2).uppercased()

    // Préparation d'une séquence Unicode pour construire le drapeau
    var scalarView = String.UnicodeScalarView()

    // Pour chaque lettre du code pays (ex: "F" et "R")
    for scalar in uppercased.unicodeScalars {
        // On ajoute la valeur Unicode de base (🇦 = "A" + base) pour obtenir le bon emoji drapeau
        if let flagScalar = UnicodeScalar(base + scalar.value) {
            scalarView.append(flagScalar)
        }
    }

    // Retourne la chaîne de caractères composée des deux indicateurs régionaux
    return String(scalarView)
}
