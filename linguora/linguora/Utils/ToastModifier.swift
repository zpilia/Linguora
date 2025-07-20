//
//  ToastModifier.swift
//  linguora
//
//  Created by Zoé Pilia on 20/07/2025.
//

import SwiftUI

/// Modificateur de vue personnalisé pour afficher un toast temporaire
struct ToastModifier: ViewModifier {
    /// Binding qui contrôle l'affichage du toast (true = visible)
    @Binding var isPresented: Bool

    /// Message à afficher dans le toast
    let message: String

    /// Contenu de la vue avec le toast intégré
    func body(content: Content) -> some View {
        ZStack {
            // Vue de base (par ex. ton écran principal)
            content

            // Si le toast est activé, on l'affiche
            if isPresented {
                VStack {
                    Spacer() // pousse le toast vers le bas

                    // Affichage du message dans un encart stylisé
                    Text(message)
                        .font(.subheadline)
                        .padding()
                        .background(.black.opacity(0.8)) // fond semi-transparent
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity)) // animation d'apparition
                }
                .animation(.easeInOut, value: isPresented) // anime l'entrée/sortie du toast
            }
        }
    }
}

/// Extension pour rendre `.toast(...)` disponible sur toutes les vues SwiftUI
extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        self.modifier(ToastModifier(isPresented: isPresented, message: message))
    }
}
