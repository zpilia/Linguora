//
//  PhotoPicker.swift
//  linguora
//
//  Created by Zoé Pilia on 18/07/2025.
//

import SwiftUI
import PhotosUI

/// Composant SwiftUI pour sélectionner une image depuis la photothèque (iOS 14+)
struct PhotoPicker: UIViewControllerRepresentable {
    /// Image sélectionnée, liée à la vue SwiftUI
    @Binding var image: UIImage?

    /// Création du contrôleur PHPickerViewController (UI côté UIKit)
    func makeUIViewController(context: Context) -> PHPickerViewController {
        // Configuration du picker : seulement les images, une seule sélection
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1

        // Création du picker avec configuration
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator // lien avec le coordinateur SwiftUI
        return picker
    }

    /// Mise à jour du contrôleur (inutile ici)
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    /// Création du coordinateur (pont entre SwiftUI et UIKit)
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Coordinateur qui gère la sélection d’image
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        /// Référence vers le parent `PhotoPicker` pour modifier l’image liée
        let parent: PhotoPicker

        /// Initialisation avec le parent
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        /// Méthode appelée quand une image est sélectionnée (ou le picker est annulé)
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true) // fermer le picker

            // Vérifie qu’un fournisseur d’image est disponible et qu’il peut fournir une UIImage
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            // Charge l’image de façon asynchrone
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    // Assigne l’image sélectionnée à la propriété liée
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}
