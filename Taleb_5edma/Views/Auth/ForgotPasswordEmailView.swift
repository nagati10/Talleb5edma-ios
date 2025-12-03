//
//  ForgotPasswordEmailView.swift
//  Taleb_5edma
//
//  Created by ChatGPT on 13/11/2025.
//

import SwiftUI

/// Écran 1 du flux « mot de passe oublié » : saisie de l'adresse email.
struct ForgotPasswordEmailView: View {
    @ObservedObject var viewModel: ForgotPasswordEmailViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            header
            form
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(AppColors.backgroundGray.ignoresSafeArea())
        .navigationTitle("Mot de passe oublié")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue.")
        }
    }
    
    /// Bloc supérieur qui contextualise le processus pour l'utilisateur.
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Retrouver l'accès à ton compte")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppColors.primaryRed)
            
            Text("Renseigne l'adresse email associée à ton compte Taleb 5edma. Nous allons t'envoyer un code de vérification.")
                .font(.system(size: 15))
                .foregroundColor(AppColors.mediumGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Formulaire avec champ email et bouton d'envoi.
    private var form: some View {
        VStack(spacing: 20) {
            CustomTextField(
                placeholder: "Adresse email",
                text: $viewModel.email,
                isPasswordVisible: .constant(true),
                keyboardType: .emailAddress
            )
            
            GradientButton(
                title: viewModel.isLoading ? "Envoi en cours..." : "Recevoir le code",
                action: {
                    Task {
                        await viewModel.submit()
                    }
                },
                isLoading: viewModel.isLoading
            )
        }
        .padding(24)
        .background(AppColors.white)
        .cornerRadius(20)
        .shadow(color: AppColors.primaryRed.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    ForgotPasswordEmailView(
        viewModel: ForgotPasswordEmailViewModel(
            otpService: OTPService()
        )
    )
}

