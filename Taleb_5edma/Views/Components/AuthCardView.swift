//
//  AuthCardView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Carte réutilisable pour les formulaires d'authentification
/// Style cohérent avec coins arrondis en haut et fond blanc
struct AuthCardView<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    
    init(
        cornerRadius: CGFloat = 30,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(AppColors.white)
        .cornerRadius(cornerRadius, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

#Preview {
    ZStack {
        AppColors.redGradient.ignoresSafeArea()
        ScrollView {
            VStack {
                Spacer()
                AuthCardView {
                    VStack(spacing: 20) {
                        Text("Formulaire")
                            .font(.title2)
                            .padding()
                    }
                    .padding()
                }
            }
        }
    }
}

