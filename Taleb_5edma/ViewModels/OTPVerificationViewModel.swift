//
//  OTPVerificationViewModel.swift
//  Taleb_5edma
//
//  Created by ChatGPT on 13/11/2025.
//

import Foundation
import Combine

// MARK: - OTPVerificationViewModel

/// ViewModel pour gérer la saisie et la validation du code OTP envoyé par email
/// Suit le pattern MVVM : sépare la logique métier de la vue de vérification
///
/// **Responsabilités:**
/// - Validation du code OTP à 6 chiffres
/// - Gestion du compte à rebours pour le renvoi de code
/// - Appels au service OTP pour vérifier et renvoyer les codes
/// - Gestion des états de chargement et d'erreur
///
/// **Fonctionnalités:**
/// - Compte à rebours de 60 secondes avant de pouvoir renvoyer un code
/// - Validation stricte : exactement 6 chiffres
/// - Callback de succès pour navigation après vérification réussie
@MainActor
final class OTPVerificationViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Code OTP saisi par l'utilisateur (6 chiffres)
    @Published var code: String = ""
    
    /// Indicateur de chargement pendant la vérification ou le renvoi de code
    @Published var isLoading: Bool = false
    
    /// Message d'erreur à afficher à l'utilisateur
    @Published var errorMessage: String?
    
    /// Indique si une alerte d'erreur doit être affichée
    @Published var showError: Bool = false
    
    /// Texte du compte à rebours affiché à l'utilisateur (ex: "01:00", "00:45")
    @Published var countdownText: String = ""
    
    /// Indique si l'utilisateur peut renvoyer un nouveau code (après le compte à rebours)
    @Published var canResend: Bool = false
    
    // MARK: - Properties
    
    /// Service OTP pour valider et renvoyer les codes
    private let otpService: OTPService
    
    /// Email de l'utilisateur pour lequel le code OTP a été envoyé
    let email: String
    
    /// Durée du compte à rebours avant de pouvoir renvoyer un code (60 secondes)
    private let timerDuration: TimeInterval = 60
    
    /// Tâche asynchrone gérant le compte à rebours
    /// Annulée automatiquement lors de la destruction du ViewModel
    private var countdownTask: Task<Void, Never>?
    
    /// Callback déclenchée lorsque la validation du code est réussie
    /// Utilisée pour naviguer vers l'écran suivant après vérification
    var onSuccess: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Initialise le ViewModel avec l'email et le service OTP
    /// Démarre automatiquement le compte à rebours
    /// - Parameters:
    ///   - email: L'email de l'utilisateur pour lequel le code a été envoyé
    ///   - otpService: Le service OTP à utiliser pour la validation
    init(email: String, otpService: OTPService) {
        self.email = email
        self.otpService = otpService
        self.countdownText = Self.formatDuration(timerDuration)
        startCountdown()
    }
    
    deinit {
        countdownTask?.cancel()
    }
    
    // MARK: - Public API
    
    /// Vérifie le code OTP saisi par l'utilisateur
    /// Valide que le code contient exactement 6 chiffres, puis appelle le service OTP
    /// Déclenche `onSuccess` si la validation est réussie
    /// - Note: Gère automatiquement les erreurs et met à jour `errorMessage`
    func verifyCode() async {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validate(code: trimmedCode) else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await otpService.validateOTP(trimmedCode, for: email)
            onSuccess?()
        } catch let otpError as OTPService.OTPError {
            errorMessage = otpError.localizedDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    /// Renvoie un nouveau code OTP à l'utilisateur
    /// Nécessite que `canResend` soit `true` (compte à rebours terminé)
    /// Réinitialise le compte à rebours après l'envoi réussi
    /// - Note: Gère automatiquement les erreurs et met à jour `errorMessage`
    func resendCode() async {
        guard canResend else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await otpService.requestOTP(for: email)
            resetCountdown()
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
    
    private func validate(code: String) -> Bool {
        guard !code.isEmpty else {
            presentValidationError("Veuillez saisir le code reçu par email.")
            return false
        }
        
        guard code.count == 6, code.allSatisfy({ $0.isNumber }) else {
            presentValidationError("Le code doit contenir exactement 6 chiffres.")
            return false
        }
        
        return true
    }
    
    private func presentValidationError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Countdown Management
    
    /// Démarre le compte à rebours de 60 secondes
    /// Met à jour `countdownText` chaque seconde et active `canResend` à la fin
    /// Annule toute tâche de compte à rebours existante avant de démarrer
    private func startCountdown() {
        canResend = false
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            guard let self else { return }
            var remaining = timerDuration
            while remaining > 0 && !Task.isCancelled {
                await MainActor.run {
                    self.countdownText = Self.formatDuration(remaining)
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                remaining -= 1
            }
            await MainActor.run {
                self.countdownText = "00:00"
                self.canResend = true
            }
        }
    }
    
    private func resetCountdown() {
        countdownText = Self.formatDuration(timerDuration)
        startCountdown()
    }
    
    private static func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

