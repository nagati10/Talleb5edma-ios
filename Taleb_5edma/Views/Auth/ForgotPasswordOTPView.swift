//
//  ForgotPasswordOTPView.swift
//  Taleb_5edma
//
//  Created by ChatGPT on 13/11/2025.
//

import SwiftUI

/// Écran 2 : saisie du code de vérification reçu par email.
struct ForgotPasswordOTPView: View {
    @ObservedObject var viewModel: OTPVerificationViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            header
            form
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(AppColors.backgroundGray.ignoresSafeArea())
        .navigationTitle("Code de vérification")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue.")
        }
    }
    
    /// Explique ce qu'il faut faire à cette étape.
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vérifie ta boite mail")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppColors.primaryRed)
            
            Text("Nous avons envoyé un code à \(viewModel.email). Saisis-le ci-dessous pour continuer.")
                .font(.system(size: 15))
                .foregroundColor(AppColors.mediumGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Champ code + bouton validation + option de renvoi.
    private var form: some View {
        VStack(spacing: 24) {
            CustomTextField(
                placeholder: "Code à 6 chiffres",
                text: $viewModel.code,
                isPasswordVisible: .constant(true),
                keyboardType: .numberPad
            )
            
            GradientButton(
                title: viewModel.isLoading ? "Vérification..." : "Valider le code",
                action: {
                    Task {
                        await viewModel.verifyCode()
                    }
                },
                isLoading: viewModel.isLoading
            )
            
            VStack(spacing: 8) {
                Text("Tu n'as rien reçu ?")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.mediumGray)
                
                Button(action: {
                    Task {
                        await viewModel.resendCode()
                    }
                }) {
                    Text(viewModel.canResend ? "Renvoyer le code" : "Nouveau code dans \(viewModel.countdownText)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.primaryRed)
                }
                .disabled(!viewModel.canResend || viewModel.isLoading)
            }
        }
        .padding(24)
        .background(AppColors.white)
        .cornerRadius(20)
        .shadow(color: AppColors.primaryRed.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    ForgotPasswordOTPView(
        viewModel: OTPVerificationViewModel(
            email: "demo@taleb5edma.tn",
            otpService: OTPService()
        )
    )
}

