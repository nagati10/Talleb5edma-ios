
//  LoginView.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import SwiftUI

/// Vue de connexion inspirée du design Toktok
/// Avec la palette de couleurs de Taleb 5edma
struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: LoginViewModel
    // Présente la feuille d'inscription lorsqu'il passe à true
    @State private var showSignUp = false
    // Présente l'écran de réinitialisation de mot de passe
    @State private var showForgotPassword = false
    
    var body: some View {
        ZStack {
            // Background avec gradient rouge bordeaux
            AppColors.redGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header avec logo
                    AuthHeaderView()
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                    
                    // Carte blanche avec le formulaire
                    AuthCardView {
                        VStack(spacing: 30) {
                            // Champs de saisie
                            VStack(spacing: 25) {
                                CustomTextField(
                                    placeholder: "Enter email or user name",
                                    text: $viewModel.email,
                                    isPasswordVisible: $viewModel.isPasswordVisible
                                )
                                
                                CustomTextField(
                                    placeholder: "Password",
                                    text: $viewModel.password,
                                    isPasswordVisible: $viewModel.isPasswordVisible,
                                    isSecure: true,
                                    showPasswordToggle: true
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 30)
                            
                            // Lien "Forgot Password"
                            HStack {
                                Spacer()
                                Button(action: {
                                    showForgotPassword = true
                                }) {
                                    Text("Forgot Password ?")
                                        .foregroundColor(AppColors.primaryRed)
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Bouton Login avec gradient
                            GradientButton(
                                title: "Login",
                                action: {
                                    Task {
                                        await viewModel.login()
                                    }
                                },
                                isLoading: viewModel.isLoading
                            )
                            .padding(.horizontal, 24)
                            
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
                            
                            // Lien vers l'inscription
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(AppColors.black)
                                    .font(.system(size: 14))
                                
                                Button(action: {
                                    showSignUp = true
                                }) {
                                    Text("Register here!")
                                        .foregroundColor(AppColors.primaryRed)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .padding(.top, 10)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView(viewModel: viewModel)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordFlowView(authService: viewModel.authService)
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue")
        }
    }
}


#Preview {
    LoginView(viewModel: LoginViewModel())
}
