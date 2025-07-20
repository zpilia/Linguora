//
//  DocumentPickerDelegateWrapper.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import UIKit
import SwiftUI

/// Wrapper délégué pour la sélection de documents avec UIDocumentPicker
class DocumentPickerDelegateWrapper: NSObject, UIDocumentPickerDelegate {
    
    /// Handler exécuté après sélection d’un document (retourne un `URL`)
    private let handler: (URL) -> Void

    /// Initialisation avec une closure à appeler lors de la sélection d’un document
    init(handler: @escaping (URL) -> Void) {
        self.handler = handler
    }

    /// Méthode appelée après la sélection d’un ou plusieurs documents
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // On ne garde que le premier document sélectionné
        guard let url = urls.first else { return }

        // On accède au fichier de manière sécurisée (sandboxed access)
        _ = url.startAccessingSecurityScopedResource()

        // On exécute le handler avec l'URL sélectionné
        handler(url)

        // On termine l'accès sécurisé au fichier
        url.stopAccessingSecurityScopedResource()
    }
}
