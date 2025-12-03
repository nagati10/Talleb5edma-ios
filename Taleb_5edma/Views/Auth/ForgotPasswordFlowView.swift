//
//  ForgotPasswordFlowView.swift
//  Taleb_5edma
//
//  Created by ChatGPT on 13/11/2025.
//

import SwiftUI

/// Conteneur qui enchaîne les différentes étapes de la récupération de mot de passe.
struct ForgotPasswordFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coordinator: ForgotPasswordCoordinatorViewModel
    
    init(authService: AuthService) {
        _coordinator = StateObject(wrappedValue: ForgotPasswordCoordinatorViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") {
                            dismiss()
                            coordinator.reset()
                        }
                    }
                }
        }
        .onDisappear {
            coordinator.reset()
        }
    }
    
    /// Sélectionne la vue correspondant à l'étape courante.
    @ViewBuilder
    private var content: some View {
        switch coordinator.currentStep {
        case .email:
            ForgotPasswordEmailView(viewModel: coordinator.emailViewModel)
        case .otp:
            if let otpVM = coordinator.otpViewModel {
                ForgotPasswordOTPView(viewModel: otpVM)
            } else {
                ProgressView().task {
                    coordinator.reset()
                }
            }
        case .newPassword:
            if let passwordVM = coordinator.passwordViewModel {
                PasswordResetView(
                    viewModel: passwordVM,
                    onSuccess: {
                        coordinator.currentStep = .success
                    },
                    dismissAction: {
                        dismiss()
                        coordinator.reset()
                    }
                )
            } else {
                ProgressView().task {
                    coordinator.reset()
                }
            }
        case .success:
            ForgotPasswordSuccessView {
                dismiss()
                coordinator.reset()
            }
        }
    }
}

#Preview {
    ForgotPasswordFlowView(authService: AuthService())
}

