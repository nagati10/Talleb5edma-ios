//
//  SignUpView.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import SwiftUI

/// Vue d'inscription inspirée du design Toktok
/// Avec la palette de couleurs de Taleb 5edma
struct SignUpView: View {
    // Le même ViewModel pilote à la fois l'écran de connexion et l'inscription
    @ObservedObject var viewModel: LoginViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background avec gradient rouge bordeaux
            AppColors.redGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header avec logo et texte d'introduction
                    VStack(spacing: 15) {
                        AuthHeaderView(
                            title: "Taleb 5edma",
                            subtitle: nil,
                            logoSize: 120
                        )
                        .padding(.top, 20)
                        
                        // Texte d'introduction
                        HStack(spacing: 4) {
                            Text("If you already have an account register")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.system(size: 14))
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("You can Login here!")
                                    .foregroundColor(AppColors.white)
                                    .font(.system(size: 14, weight: .semibold))
                                    .underline()
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 30)
                    
                    // Carte blanche avec le formulaire
                    AuthCardView {
                        VStack(spacing: 25) {
                            // Champs de saisie
                            VStack(spacing: 20) {
                                CustomTextField(
                                    placeholder: "Enter Email",
                                    text: $viewModel.signUpEmail,
                                    isPasswordVisible: .constant(false),
                                    keyboardType: .emailAddress
                                )
                                
                                CustomTextField(
                                    placeholder: "Create Username",
                                    text: $viewModel.signUpUsername,
                                    isPasswordVisible: .constant(false)
                                )
                                
                                CustomTextField(
                                    placeholder: "Contact Number",
                                    text: $viewModel.signUpContactNumber,
                                    isPasswordVisible: .constant(false),
                                    keyboardType: .phonePad
                                )
                                
                                CustomTextField(
                                    placeholder: "Password",
                                    text: $viewModel.signUpPassword,
                                    isPasswordVisible: $viewModel.isSignUpPasswordVisible,
                                    isSecure: true,
                                    showPasswordToggle: true
                                )
                                
                                CustomTextField(
                                    placeholder: "Confirm Password",
                                    text: $viewModel.signUpConfirmPassword,
                                    isPasswordVisible: $viewModel.isSignUpConfirmPasswordVisible,
                                    isSecure: true,
                                    showPasswordToggle: true
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 30)
                            
                            // Bouton Sign Up avec gradient
                            GradientButton(
                                title: "Sign Up",
                                action: {
                                    Task {
                                        await viewModel.signUp()
                                    }
                                },
                                isLoading: viewModel.isLoading
                            )
                            .padding(.horizontal, 24)
                            .padding(.top, 10)
                            
                            // Séparateur "OR"
                            SeparatorView()
                            
                            // Bouton Google Sign-In
                            SocialLoginButton(
                                icon: "globe",
                                title: "Continue with Google",
                                iconColor: AppColors.darkGray,
                                action: {
                                    // Action Google Sign-In
                                }
                            )
                            .padding(.horizontal, 24)
                            .disabled(viewModel.isLoading)
                            .padding(.bottom, 30)
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
        // ⚠️ Note: L'inscription connecte automatiquement l'utilisateur
        // Plus besoin de rediriger vers VerificationView
    }
}

#Preview {
    SignUpView(viewModel: LoginViewModel())
}

