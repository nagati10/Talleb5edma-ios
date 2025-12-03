//
//  OTPService.swift
//  Taleb_5edma
//
//  Created by ChatGPT on 13/11/2025.
//

import Foundation

/// Service dédié à la génération et à la validation des OTP (One Time Password)
/// Cette implémentation reste 100% côté client pour que tu puisses tester le flux complet
/// avant d'intégrer un vrai fournisseur d'email / SMS (Twilio, Firebase, SendGrid, etc.).
/// ⚠️ En production, déplace impérativement la génération/validation côté serveur.
final class OTPService {
    
    // MARK: - Nested types
    
    /// Erreurs spécifiques au service OTP afin d'afficher des messages clairs à l'utilisateur.
    enum OTPError: LocalizedError {
        case emailNotFound
        case tooManyRequests
        case invalidCode
        case codeExpired
        case providerError(String)
        case networkError
        
        var errorDescription: String? {
            switch self {
            case .emailNotFound:
                return "Aucun compte n'est associé à cet email."
            case .tooManyRequests:
                return "Trop de demandes ont été effectuées. Réessaie dans quelques minutes."
            case .invalidCode:
                return "Le code saisi est incorrect."
            case .codeExpired:
                return "Le code a expiré. Demande un nouveau code."
            case .providerError(let message):
                return "Impossible d'envoyer le code: \(message)"
            case .networkError:
                return "Impossible de contacter le serveur. Vérifie ta connexion internet."
            }
        }
    }
    
    /// Structure interne qui mémorise l'OTP et son expiration pour un email donné.
    private struct OTPEntry {
        let code: String
        let expirationDate: Date
        var attempts: Int
    }
    
    /// Acteur responsable du stockage thread-safe des OTP générés localement.
    private actor OTPStore {
        private var store: [String: OTPEntry] = [:]
        
        func save(_ entry: OTPEntry, for email: String) {
            store[email.lowercased()] = entry
        }
        
        func get(for email: String) -> OTPEntry? {
            store[email.lowercased()]
        }
        
        func remove(for email: String) {
            store[email.lowercased()] = nil
        }
    }
    
    /// Protocole permettant de brancher facilement un vrai fournisseur d'envoi d'OTP.
    /// Par défaut on fournit une implémentation qui log le code dans la console.
    protocol OTPProvider {
        func send(code: String, to email: String) async throws
    }
    
    /// Implémentation de référence : elle n'envoie rien et se contente de logger le code.
    /// Très utile pour le développement local.
    struct ConsoleOTPProvider: OTPProvider {
        func send(code: String, to email: String) async throws {
            print("📩 OTP pour \(email): \(code)")
        }
    }
    
    // MARK: - Properties
    
    private let emailVerifier: EmailVerifier
    private let provider: OTPProvider
    private let otpStore = OTPStore()
    
    /// Durée de validité du code (5 minutes par défaut)
    private let codeLifetime: TimeInterval = 5 * 60
    /// Nombre maximum de tentatives avant d'invalider le code
    private let maxAttempts = 5
    /// Délai minimum entre deux envois (pour éviter le spam du même email)
    private let resendCooldown: TimeInterval = 45
    
    /// Mémorise la dernière date d'envoi afin d'appliquer le cooldown.
    private var lastSentDates: [String: Date] = [:]
    
    // MARK: - Initialisation
    
    init(
        emailVerifier: EmailVerifier = DefaultEmailVerifier(),
        provider: OTPProvider = ConsoleOTPProvider()
    ) {
        self.emailVerifier = emailVerifier
        self.provider = provider
    }
    
    // MARK: - Public API
    
    /// Vérifie que l'email existe côté backend avant d'autoriser la génération d'un OTP.
    func verifyEmailExists(_ email: String) async throws {
        do {
            let exists = try await emailVerifier.emailExists(email)
            guard exists else {
                throw OTPError.emailNotFound
            }
        } catch let error as OTPError {
            throw error
        } catch {
            throw OTPError.networkError
        }
    }
    
    /// Génère un OTP, le stocke localement avec une date d'expiration et le transmet via le provider.
    func requestOTP(for email: String) async throws {
        try await verifyEmailExists(email)
        
        // Applique le cooldown pour éviter l'abus d'envois
        if let lastSent = lastSentDates[email.lowercased()],
           Date().timeIntervalSince(lastSent) < resendCooldown {
            throw OTPError.tooManyRequests
        }
        
        let code = generateOTPCode()
        let entry = OTPEntry(
            code: code,
            expirationDate: Date().addingTimeInterval(codeLifetime),
            attempts: 0
        )
        
        await otpStore.save(entry, for: email)
        lastSentDates[email.lowercased()] = Date()
        
        do {
            try await provider.send(code: code, to: email)
        } catch {
            throw OTPError.providerError(error.localizedDescription)
        }
    }
    
    /// Valide un OTP: on vérifie sa présence, son expiration et on actualise le nombre de tentatives.
    func validateOTP(_ code: String, for email: String) async throws {
        guard var entry = await otpStore.get(for: email) else {
            throw OTPError.invalidCode
        }
        
        guard Date() < entry.expirationDate else {
            await otpStore.remove(for: email)
            throw OTPError.codeExpired
        }
        
        guard entry.attempts < maxAttempts else {
            await otpStore.remove(for: email)
            throw OTPError.tooManyRequests
        }
        
        if entry.code != code {
            entry.attempts += 1
            await otpStore.save(entry, for: email)
            throw OTPError.invalidCode
        }
        
        // Succès : on supprime le code pour éviter toute réutilisation.
        await otpStore.remove(for: email)
    }
    
    // MARK: - Helpers
    
    /// Génère un code à 6 chiffres. Ajuste la longueur si tu préfères 4 ou 8 chiffres.
    private func generateOTPCode() -> String {
        let range = 0..<1_000_000
        let randomNumber = Int.random(in: range)
        return String(format: "%06d", randomNumber)
    }
}

// MARK: - Email verification

/// Protocole pour isoler l'appel réseau qui vérifie l'existence de l'email.
protocol EmailVerifier {
    func emailExists(_ email: String) async throws -> Bool
}

/// Implémentation par défaut qui utilise le backend NestJS existant.
struct DefaultEmailVerifier: EmailVerifier {
    func emailExists(_ email: String) async throws -> Bool {
        guard let url = URL(string: APIConfig.emailExistsEndpoint(for: email)) else {
            throw OTPService.OTPError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OTPService.OTPError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                return false
            }
            throw OTPService.OTPError.networkError
        }
        
        // Le backend peut renvoyer différents formats, on tente plusieurs décodages.
        if let structured = try? JSONDecoder().decode(EmailExistsResponse.self, from: data) {
            if let exists = structured.exists ?? structured.data {
                return exists
            }
        }
        
        // Plan B: l'API peut renvoyer un simple booléen ("true"/"false")
        if let stringValue = String(data: data, encoding: .utf8) {
            return (stringValue as NSString).boolValue
        }
        
        return false
    }
    
    /// Modèle de réponse minimal pour `/admin/email-exists/{email}`
    private struct EmailExistsResponse: Codable {
        let exists: Bool?
        let data: Bool?
    }
}

