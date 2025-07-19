//
//  ToastModifier.swift
//  linguora
//
//  Created by Zoé Pilia on 20/07/2025.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.subheadline)
                        .padding()
                        .background(.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: isPresented)
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        self.modifier(ToastModifier(isPresented: isPresented, message: message))
    }
}
