//
//  SocialLoginButton.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import SwiftUI

/// Bouton de connexion sociale pour Google, Facebook, etc.
struct SocialLoginButton: View {
    // Nom SF Symbols ou ressource d'icône affiché à gauche du titre
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .foregroundColor(AppColors.black)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppColors.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.lightGray, lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack(spacing: 15) {
        
        SocialLoginButton(
            icon: "globe",
            title: "Continue with Google",
            iconColor: .blue,
            action: {}
        )
    }
    .padding()
}

