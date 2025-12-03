//
//  ProfileViewModel.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI
import Combine

// MARK: - ProfileViewModel

/// ViewModel pour gérer le profil utilisateur et ses mises à jour
/// Suit le pattern MVVM : sépare la logique métier de la vue ProfileView
///
/// **Responsabilités:**
/// - Chargement du profil utilisateur depuis l'API
/// - Mise à jour des informations du profil (nom, contact, email)
/// - Upload de la photo de profil
/// - Gestion des états de chargement et d'erreur
/// - Déconnexion de l'utilisateur
///
/// **Observation:**
/// S'abonne automatiquement aux changements de `authService.currentUser` pour rester synchronisé
@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Utilisateur actuellement connecté - affiché dans ProfileView
    /// Synchronisé automatiquement avec `authService.currentUser`
    @Published var currentUser: User?
    
    /// Indicateur de chargement pendant les opérations réseau
    @Published var isLoading = false
    
    /// Message d'erreur à afficher dans la vue
    @Published var errorMessage: String?
    
    /// Indique si une alerte d'erreur doit être affichée
    @Published var showError = false
    
    /// Indique si un message de succès doit être affiché
    @Published var showSuccess = false
    
    /// Message de succès à afficher à l'utilisateur (ex: "Profil mis à jour avec succès!")
    @Published var successMessage: String?
    
    // MARK: - Properties
    
    /// Service d'authentification injecté - utilisé pour les appels API
    var authService: AuthService
    
    /// Gestionnaires d'abonnements Combine pour observer les changements
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialise le ViewModel avec le service d'authentification
    /// S'abonne automatiquement aux changements de `currentUser` pour rester synchronisé
    /// - Parameter authService: Le service d'authentification à utiliser
    init(authService: AuthService) {
        self.authService = authService
        self.currentUser = authService.currentUser
        
        // Observer les changements de currentUser dans authService
        // Permet de mettre à jour automatiquement la vue si le profil change ailleurs
        authService.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
        
        // Charger le profil si pas déjà chargé au démarrage
        if currentUser == nil {
            loadCurrentUser()
        }
    }
    
    // MARK: - User Profile Methods
    
    /// Charge le profil utilisateur depuis l'API backend
    /// Met à jour `currentUser` avec les données récupérées
    /// Gère les erreurs et met à jour les états de chargement
    func loadCurrentUser() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔄 ProfileViewModel - Chargement du profil...")
                let user = try await authService.getUserProfile()
                
                self.currentUser = user
                self.isLoading = false
                print("✅ Profil chargé: \(user.nom)")
                
            } catch {
                self.errorMessage = self.formatError(error)
                self.showError = true
                self.isLoading = false
                print("❌ Erreur chargement: \(error)")
            }
        }
    }
    
    /// Déconnecte l'utilisateur et réinitialise le profil
    /// Appelle `authService.logout()` pour nettoyer la session
    func logout() {
        print("🚪 Déconnexion...")
        isLoading = true
        authService.logout()
        currentUser = nil
        isLoading = false
    }
    
    /// Met à jour le profil utilisateur avec de nouvelles informations
    /// - Parameters:
    ///   - nom: Le nouveau nom d'utilisateur
    ///   - contact: Le nouveau numéro de contact
    /// - Note: L'email est préservé depuis `currentUser` car il ne peut pas être modifié
    /// - Validation: Vérifie que les champs ne sont pas vides avant l'envoi
    func updateUserProfile(nom: String, contact: String) {
        // Validation basique des champs requis
        guard !nom.isEmpty, !contact.isEmpty else {
            errorMessage = "Veuillez remplir tous les champs obligatoires"
            showError = true
            print("❌ Validation échouée: champs vides")
            return
        }
        
        guard let email = currentUser?.email, !email.isEmpty else {
            errorMessage = "Email utilisateur non disponible"
            showError = true
            print("❌ Email manquant")
            return
        }
        
        print("🔄 Début mise à jour profil")
        print("   Nom: \(nom)")
        print("   Email: \(email)")
        print("   Contact: \(contact)")
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        showSuccess = false
        
        Task {
            do {
                let updateRequest = UpdateUserRequest(
                    nom: nom.trimmingCharacters(in: .whitespaces),
                    email: email,
                    contact: contact.trimmingCharacters(in: .whitespaces),
                    image: currentUser?.image
                )
                
                print("📤 Envoi de la requête de mise à jour...")
                let updatedUser = try await authService.updateUserProfile(updateRequest)
                
                // ✅ Delay UI updates to avoid "Publishing changes..." warning
                DispatchQueue.main.async {
                    print("✅ Mise à jour réussie!")
                    print("   Nouveau nom: \(updatedUser.nom)")
                    print("   Nouveau contact: \(updatedUser.contact)")
                    
                    self.currentUser = updatedUser
                    self.isLoading = false
                    self.successMessage = "Profil mis à jour avec succès!"
                    self.showSuccess = true
                }
                
            } catch {
                DispatchQueue.main.async {
                    print("❌ Erreur mise à jour: \(error)")
                    self.errorMessage = self.formatError(error)
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Formate une erreur pour l'affichage à l'utilisateur
    /// Convertit les `AuthError` en messages lisibles, sinon utilise la description locale
    /// - Parameter error: L'erreur à formater
    /// - Returns: Le message d'erreur formaté en français
    private func formatError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }
        return "Erreur: \(error.localizedDescription)"
    }
    
    /// Upload une nouvelle image de profil vers le serveur
    /// Met à jour `currentUser` avec l'URL de la nouvelle image après succès
    /// - Parameter image: L'image UIImage à uploader (doit être convertie en JPEG)
    /// - Note: Utilise `multipart/form-data` pour l'upload selon le schéma API
    func uploadProfileImage(_ image: UIImage) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        showSuccess = false
        
        Task {
            do {
                print("🖼️ ProfileViewModel - Upload de l'image de profil...")
                let updatedUser = try await authService.uploadProfileImage(image)
                
                DispatchQueue.main.async {
                    print("✅ Image de profil uploadée avec succès!")
                    self.currentUser = updatedUser
                    self.isLoading = false
                    self.successMessage = "Photo de profil mise à jour avec succès!"
                    self.showSuccess = true
                }
                
            } catch {
                DispatchQueue.main.async {
                    print("❌ Erreur upload image: \(error)")
                    self.errorMessage = self.formatError(error)
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    func debugState() {
        print("=== DEBUG PROFILE VIEW MODEL ===")
        print("Current User: \(String(describing: currentUser?.nom))")
        print("Email: \(String(describing: currentUser?.email))")
        print("Contact: \(String(describing: currentUser?.contact))")
        print("Is Loading: \(isLoading)")
        print("Auth Token Present: \(authService.authToken != nil)")
        print("Is Authenticated: \(authService.isAuthenticated)")
        print("================================")
    }
}
