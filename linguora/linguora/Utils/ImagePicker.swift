//
//  ImagePicker.swift
//  linguora
//
//  Created by Zoé Pilia on 18/07/2025.
//

import SwiftUI
import UIKit

/// Composant SwiftUI pour utiliser le sélecteur d'image natif UIKit (caméra ou galerie)
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType         // Source : .camera ou .photoLibrary
    @Binding var selectedImage: UIImage?                       // Image sélectionnée (binding)

    // Création du coordinateur pour gérer les délégués UIKit
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Création du UIImagePickerController
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator       // délégué géré par SwiftUI
        picker.sourceType = sourceType              // caméra ou galerie
        return picker
    }

    // Pas de mise à jour nécessaire ici
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    /// Classe de coordination (liaison UIKit -> SwiftUI)
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker // référence vers le parent SwiftUI

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        // Méthode appelée après sélection d’une image
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image    // mise à jour de l’image liée
            }
            picker.dismiss(animated: true)     // fermeture du picker
        }

        // Annulation sans sélection
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
