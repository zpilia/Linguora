//
//  ContentView.swift
//  linguora
//
//  Created by Zoé Pilia on 17/07/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var name: String = ""
    @State private var greeting: String = ""
    @State private var showError: Bool = false
    @State private var animateGreeting: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.purple, .blue]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("HelloImage")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .shadow(radius: 10)

                TextField("Entre ton prénom", text: $name)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.horizontal)

                Button(action: {
                    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        showError = true
                        greeting = ""
                    } else {
                        greeting = "👋 Bonjour \(name) !"
                        showError = false
                        withAnimation(.easeInOut(duration: 0.5)) {
                            animateGreeting = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                animateGreeting = false
                            }
                        }
                    }
                }) {
                    Text("👋 Dire bonjour")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.purple)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                if showError {
                    Text("❗️Veuillez entrer votre prénom")
                        .foregroundColor(.red)
                        .transition(.opacity)
                }

                if !greeting.isEmpty {
                    Text(greeting)
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .scaleEffect(animateGreeting ? 1.2 : 1.0)
                        .animation(.spring(), value: animateGreeting)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
