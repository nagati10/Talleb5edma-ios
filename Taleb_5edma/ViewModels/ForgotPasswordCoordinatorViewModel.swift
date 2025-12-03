//
//  ForgotPasswordCoordinatorViewModel.swift
//  Taleb_5edma
//
//  Created by ChatGPT on 13/11/2025.
//

import Foundation
import Combine

/// ViewModel principal qui orchestre les trois étapes du flux "mot de passe oublié".
@MainActor
final class ForgotPasswordCoordinatorViewModel: ObservableObject {
    
    /// Représente les différentes étapes du parcours.
    enum Step: Hashable {
        case email
        case otp
        case newPassword
        case success
    }
    
    // MARK: - Published state
    @Published var currentStep: Step = .email
    @Published var email: String = ""
    
    // MARK: - Child view models
    let emailViewModel: ForgotPasswordEmailViewModel
    private(set) var otpViewModel: OTPVerificationViewModel?
    private(set) var passwordViewModel: PasswordResetViewModel?
    
    // MARK: - Dependencies
    let authService: AuthService
    let otpService: OTPService
    
    // MARK: - Initialisation
    init(authService: AuthService) {
        self.authService = authService
        self.otpService = OTPService()
        self.emailViewModel = ForgotPasswordEmailViewModel(otpService: otpService)
        configureCallbacks()
    }
    
    /// Réinitialise la progression (utile si on ferme la feuille et qu'on la rouvre)
    func reset() {
        currentStep = .email
        email = ""
        emailViewModel.email = ""
        otpViewModel = nil
        passwordViewModel = nil
    }
    
    // MARK: - Private helpers
    
    private func configureCallbacks() {
        emailViewModel.onSuccess = { [weak self] email in
            guard let self else { return }
            self.email = email
            self.prepareOTPViewModel(for: email)
            self.currentStep = .otp
        }
    }
    
    private func prepareOTPViewModel(for email: String) {
        let otpVM = OTPVerificationViewModel(email: email, otpService: otpService)
        otpVM.onSuccess = { [weak self] in
            guard let self else { return }
            self.preparePasswordViewModel(for: email)
            self.currentStep = .newPassword
        }
        otpViewModel = otpVM
    }
    
    private func preparePasswordViewModel(for email: String) {
        let passwordVM = PasswordResetViewModel(
            authService: authService,
            mode: .forgotPassword,
            email: email,
            lockEmailField: true
        )
        passwordVM.didSucceed = false
        passwordViewModel = passwordVM
    }
}

