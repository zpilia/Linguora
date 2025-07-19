//
//  DocumentPickerDelegateWrapper.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import UIKit
import SwiftUI

class DocumentPickerDelegateWrapper: NSObject, UIDocumentPickerDelegate {
    private let handler: (URL) -> Void

    init(handler: @escaping (URL) -> Void) {
        self.handler = handler
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        _ = url.startAccessingSecurityScopedResource()
        handler(url)
        url.stopAccessingSecurityScopedResource()
    }
}
