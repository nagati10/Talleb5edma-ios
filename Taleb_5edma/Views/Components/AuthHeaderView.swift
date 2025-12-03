//
//  AuthHeaderView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Header réutilisable pour les vues d'authentification
/// Affiche le logo et le titre de l'application avec un style cohérent
struct AuthHeaderView: View {
    let title: String
    let subtitle: String?
    let logoSize: CGFloat
    
    init(
        title: String = "Taleb 5edma",
        subtitle: String? = nil,
        logoSize: CGFloat = 150
    ) {
        self.title = title
        self.subtitle = subtitle
        self.logoSize = logoSize
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo de l'application
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // Titre de l'application
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
            
            // Sous-titre optionnel
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

#Preview {
    ZStack {
        AppColors.redGradient.ignoresSafeArea()
        AuthHeaderView()
    }
}

