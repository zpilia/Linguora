//
//  ImageTranslationView.swift
//  linguora
//
//  Created by Zoé Pilia on 18/07/2025.
//
import SwiftUI

struct ImageTranslationView: View {
    var body: some View {
        VStack {
            Text("Traduction par image")
                .font(.largeTitle)
                .bold()
        }
        .navigationTitle("Par Image")
    }
}

#Preview {
    ImageTranslationView()
}
