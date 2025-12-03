//
//  ForgotPasswordSuccessView.swift
//  Taleb_5edma
//
//  Created by ChatGPT on 13/11/2025.
//

import SwiftUI

/// Dernière étape : confirmation que le mot de passe a été modifié.
struct ForgotPasswordSuccessView: View {
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(AppColors.primaryRed)
                .padding(.top, 40)
            
            Text("Mot de passe mis à jour")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppColors.black)
            
            Text("Tu peux maintenant te connecter avec ton nouveau mot de passe. Pense à le garder secret et unique.")
                .font(.system(size: 15))
                .foregroundColor(AppColors.mediumGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            GradientButton(
                title: "Revenir à la connexion",
                action: onClose,
                isLoading: false
            )
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(AppColors.backgroundGray.ignoresSafeArea())
    }
}

#Preview {
    ForgotPasswordSuccessView(onClose: {})
}

