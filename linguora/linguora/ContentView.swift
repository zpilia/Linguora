//
//  ContentView.swift
//  linguora
//
//  Created by Zoé Pilia on 17/07/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var inputText = "Hello!"
    @State private var translatedText = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("Texte à traduire", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Traduire en français") {
                DeepLService.translate(text: inputText, to: "FR") { result in
                    if let translation = result {
                        translatedText = translation
                    } else {
                        translatedText = "❌ Erreur lors de la traduction"
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            Text(translatedText)
                .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
