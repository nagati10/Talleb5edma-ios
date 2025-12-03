//
//  PasswordResetView.swift
//  Taleb_5edma
//
//  Created by Apple on 11/11/2025.
//

import SwiftUI

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    // ViewModel encapsulant les différentes variantes du flux mot de passe
    @StateObject private var viewModel: PasswordResetViewModel
    private let onSuccess: (() -> Void)?
    private let dismissAction: (() -> Void)?
    
    init(
        viewModel: PasswordResetViewModel,
        onSuccess: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSuccess = onSuccess
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection
                
                formSection
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .background(AppColors.backgroundGray.ignoresSafeArea())
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        if let dismissAction {
                            dismissAction()
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.didSucceed ? "Succès" : "Erreur"),
                    message: Text(viewModel.alertMessage ?? ""),
                    dismissButton: .default(Text("OK"), action: {
                        if viewModel.didSucceed {
                            if let onSuccess {
                                onSuccess()
                            } else if let dismissAction {
                                dismissAction()
                            } else {
                                dismiss()
                            }
                        } else if let dismissAction {
                            dismissAction()
                        }
                    })
                )
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.primaryRed)
            
            Text(viewModel.subtitle)
                .font(.system(size: 15))
                .foregroundColor(AppColors.mediumGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var formSection: some View {
        VStack(spacing: 20) {
            if viewModel.isEmailEditable {
                CustomTextField(
                    placeholder: "Email",
                    text: $viewModel.email,
                    isPasswordVisible: .constant(true)
                )
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(AppColors.mediumGray)
                    Text(viewModel.email)
                        .font(.body)
                        .foregroundColor(AppColors.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppColors.white)
                        .cornerRadius(12)
                }
            }
            
            CustomTextField(
                placeholder: "Nouveau mot de passe",
                text: $viewModel.newPassword,
                isPasswordVisible: .constant(false),
                isSecure: true,
                showPasswordToggle: false
            )
            
            CustomTextField(
                placeholder: "Confirmer le mot de passe",
                text: $viewModel.confirmPassword,
                isPasswordVisible: .constant(false),
                isSecure: true,
                showPasswordToggle: false
            )
            
            GradientButton(
                title: viewModel.primaryButtonTitle,
                action: {
                    Task {
                        await viewModel.submit()
                    }
                },
                isLoading: viewModel.isSubmitting
            )
        }
        .padding(24)
        .background(AppColors.white)
        .cornerRadius(20)
        .shadow(color: AppColors.primaryRed.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    PasswordResetView(
        viewModel: PasswordResetViewModel(
            authService: AuthService(),
            mode: .forgotPassword
        )
    )
}


