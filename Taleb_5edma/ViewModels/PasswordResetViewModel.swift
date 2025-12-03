//
//  PasswordResetViewModel.swift
//  Taleb_5edma
//
//  Created by Apple on 11/11/2025.
//

import Foundation
import Combine

/// ViewModel gérant les flux « mot de passe oublié » et « changement de mot de passe »
@MainActor
final class PasswordResetViewModel: ObservableObject {
    
    enum Mode {
        case forgotPassword
        case updatePassword
    }
    
    // MARK: - Published state
    
    // Adresse email fournie par l'utilisateur
    @Published var email: String
    // Nouveau mot de passe saisi dans le formulaire
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var isSubmitting: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String?
    @Published var didSucceed: Bool = false
    
    // MARK: - Properties
    
    private let authService: AuthService
    let mode: Mode
    let isEmailEditable: Bool
    
    // MARK: - Initialisation
    
    init(
        authService: AuthService,
        mode: Mode,
        email: String? = nil,
        lockEmailField: Bool = false
    ) {
        self.authService = authService
        self.mode = mode
        let trimmedEmail = (email ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = trimmedEmail
        // L'email est éditable uniquement si on n'a pas déjà validé l'identité.
        if lockEmailField || mode == .updatePassword {
            self.isEmailEditable = false
        } else {
            self.isEmailEditable = trimmedEmail.isEmpty
        }
    }
    
    // MARK: - Computed
    
    var title: String {
        switch mode {
        case .forgotPassword:
            return "Mot de passe oublié"
        case .updatePassword:
            return "Modifier le mot de passe"
        }
    }
    
    var subtitle: String {
        switch mode {
        case .forgotPassword:
            return "Renseigne ton email et un nouveau mot de passe pour accéder de nouveau à ton compte."
        case .updatePassword:
            return "Choisis un nouveau mot de passe pour sécuriser ton compte."
        }
    }
    
    var primaryButtonTitle: String {
        isSubmitting ? "En cours..." : "Valider"
    }
    
    // MARK: - Public Methods
    
    func submit() async {
        guard validateFields() else { return }
        
        isSubmitting = true
        alertMessage = nil
        didSucceed = false
        
        let request = ResetPasswordRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            newPassword: newPassword
        )
        
        do {
            let requiresAuth = (mode == .updatePassword)
            try await authService.resetPassword(request, requiresAuthentication: requiresAuth)
            
            didSucceed = true
            switch mode {
            case .forgotPassword:
                alertMessage = "Mot de passe réinitialisé. Tu peux maintenant te connecter avec ton nouveau mot de passe."
            case .updatePassword:
                alertMessage = "Mot de passe mis à jour avec succès."
            }
        } catch {
            if let authError = error as? AuthError {
                alertMessage = authError.localizedDescription
            } else {
                alertMessage = error.localizedDescription
            }
            didSucceed = false
        }
        
        showAlert = true
        isSubmitting = false
    }
    
    // MARK: - Validation
    
    private func validateFields() -> Bool {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return setValidationError("Veuillez entrer votre adresse email.")
        }
        
        guard email.contains("@"), email.contains(".") else {
            return setValidationError("Adresse email invalide.")
        }
        
        let trimmedPassword = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedPassword.count >= 6 else {
            return setValidationError("Le mot de passe doit contenir au moins 6 caractères.")
        }
        
        guard trimmedPassword == confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return setValidationError("Les mots de passe ne correspondent pas.")
        }
        
        return true
    }
    
    @discardableResult
    private func setValidationError(_ message: String) -> Bool {
        alertMessage = message
        showAlert = true
        didSucceed = false
        return false
    }
}


