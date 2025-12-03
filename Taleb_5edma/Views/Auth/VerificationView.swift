//
//  VerificationView.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import SwiftUI

/// Vue de vérification inspirée du design Toktok
/// Avec la palette de couleurs de Taleb 5edma
struct VerificationView: View {
    // ViewModel partagé avec le flux d'inscription
    @ObservedObject var viewModel: LoginViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background avec gradient rouge foncé
            AppColors.redGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header avec logo et titre de vérification
                    VStack(spacing: 15) {
                        AuthHeaderView(
                            title: "Taleb 5edma",
                            subtitle: nil,
                            logoSize: 120
                        )
                        .padding(.top, 40)
                        
                        Text("Verification")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.primaryRed)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .padding(.bottom, 20)
                    
                    // Carte blanche avec le formulaire
                    AuthCardView {
                        VStack(spacing: 25) {
                            // Texte d'instruction
                            VStack(spacing: 8) {
                                Text("We have sent the verification code to")
                                    .foregroundColor(AppColors.black)
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 4) {
                                    Text(viewModel.maskedPhoneNumber)
                                        .foregroundColor(AppColors.black)
                                        .font(.system(size: 14))
                                    
                                    Button(action: {
                                        // TODO: Permettre de changer le numéro
                                    }) {
                                        Text("You can Change here!")
                                            .foregroundColor(AppColors.primaryRed)
                                            .font(.system(size: 14, weight: .semibold))
                                            .underline()
                                    }
                                }
                            }
                            .padding(.top, 30)
                            .padding(.horizontal, 24)
                            
                            // Champ de code de vérification
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Verification Code")
                                    .foregroundColor(AppColors.black)
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.horizontal, 24)
                                
                                HStack {
                                    VerificationCodeField(code: $viewModel.verificationCode)
                                    
                                    // Bouton Re-send Code
                                    Button(action: {
                                        Task {
                                            await viewModel.sendVerificationCode()
                                        }
                                    }) {
                                        Text("Re-send Code")
                                            .foregroundColor(AppColors.primaryRed)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .padding(.top, 20)
                            
                            // Bouton Continue avec gradient
                            GradientButton(
                                title: "Continue",
                                action: {
                                    Task {
                                        await viewModel.verifyCode()
                                    }
                                },
                                isLoading: viewModel.isLoading
                            )
                            .padding(.horizontal, 24)
                            .padding(.top, 30)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue")
        }
    }
}

#Preview {
    VerificationView(viewModel: LoginViewModel())
}

