//
//  ForgotPasswordEmailViewModel.swift
//  Taleb_5edma
//
//  Created by ChatGPT on 13/11/2025.
//

import Foundation
import Combine

/// Première étape du flux « mot de passe oublié »
/// Responsable de valider l'email saisi et de déclencher l'envoi de l'OTP.
@MainActor
final class ForgotPasswordEmailViewModel: ObservableObject {
    
    // MARK: - Published state
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var didSendOTP: Bool = false
    
    // MARK: - Properties
    private let otpService: OTPService
    /// Callback exécutée après l'envoi réussi du code (permet de passer à l'écran suivant).
    var onSuccess: ((String) -> Void)?
    
    // MARK: - Initialisation
    init(otpService: OTPService) {
        self.otpService = otpService
    }
    
    // MARK: - Public API
    
    /// Valide le champ email puis demande au service OTP d'envoyer un code.
    func submit() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validate(email: trimmedEmail) else { return }
        
        isLoading = true
        errorMessage = nil
        didSendOTP = false
        
        do {
            try await otpService.requestOTP(for: trimmedEmail)
            didSendOTP = true
            onSuccess?(trimmedEmail)
        } catch let otpError as OTPService.OTPError {
            errorMessage = otpError.localizedDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Validation helpers
    
    private func validate(email: String) -> Bool {
        guard !email.isEmpty else {
            presentValidationError("Veuillez saisir votre adresse email.")
            return false
        }
        
        guard email.contains("@"), email.contains(".") else {
            presentValidationError("Le format de l'email est invalide.")
            return false
        }
        
        return true
    }
    
    private func presentValidationError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

