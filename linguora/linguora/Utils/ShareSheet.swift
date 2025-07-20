//
//  ShareSheet.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import SwiftUI
import UIKit

/// Représente une feuille de partage (UIActivityViewController) intégrée à SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    /// Éléments à partager (texte, image, URL, etc.)
    let activityItems: [Any]

    /// 🛠️ Crée et configure le contrôleur UIKit pour le partage
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // UIActivityViewController permet à l’utilisateur de partager les éléments (AirDrop, Messages, Mail, etc.)
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    /// Méthode obligatoire (même si vide ici) pour les mises à jour du contrôleur
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {
        // Rien à faire ici car la feuille de partage ne nécessite pas de mise à jour dynamique
    }
}
