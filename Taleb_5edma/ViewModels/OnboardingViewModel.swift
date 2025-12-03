//
//  OnboardingViewModel.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI
import Combine

// MARK: - OnboardingViewModel

/// ViewModel pour gérer le processus d'onboarding des nouveaux utilisateurs
/// Suit le pattern MVVM : sépare la logique métier de la vue OnboardingView
/// Gère la sauvegarde des préférences utilisateur sur le backend via StudentPreferencesService
///
/// **Fonctionnalités:**
/// - Sauvegarde des préférences utilisateur (niveau d'étude, domaine, compétences, etc.)
/// - Vérification du statut d'onboarding par utilisateur
/// - Réinitialisation de l'onboarding pour permettre de le refaire
///
/// **Persistance:**
/// - Utilise StudentPreferencesService pour sauvegarder sur le backend
/// - Utilise UserDefaults comme cache local pour améliorer les performances
/// - Permet à plusieurs utilisateurs d'avoir leur propre statut d'onboarding
@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Indicateur de chargement pendant la sauvegarde des préférences
    @Published var isLoading = false
    
    /// Indique si une erreur doit être affichée
    @Published var showError = false
    
    /// Message d'erreur à afficher à l'utilisateur
    @Published var errorMessage: String?
    
    /// Indique si l'onboarding a été complété avec succès
    /// Quand `true`, déclenche la navigation vers le Dashboard
    @Published var onboardingComplete = false
    
    /// Préférences chargées depuis le backend pour pré-remplir le formulaire
    @Published var loadedPreferences: UserPreferences?
    
    /// Indique si les préférences sont en cours de chargement
    @Published var isLoadingPreferences = false
    
    // MARK: - Properties
    
    /// Service d'authentification pour obtenir l'ID de l'utilisateur actuel
    /// Optionnel car initialisé après la création du ViewModel
    var authService: AuthService?
    
    /// Service pour gérer les préférences étudiant
    private let preferencesService = StudentPreferencesService()
    
    // MARK: - Initialization
    
    /// Initialise le ViewModel
    /// L'authService doit être défini après l'initialisation via `authService = ...`
    init() {
        // Initialisation vide - l'authService sera injecté depuis OnboardingView
    }
    
    // MARK: - Section Titles
    
    /// Retourne le titre de la section d'onboarding correspondant à l'index
    /// - Parameter section: L'index de la section (0-4)
    /// - Returns: Le titre de la section en français
    /// - Note: Utilisé dans OnboardingView pour afficher les titres des différentes étapes
    func getSectionTitle(_ section: Int) -> String {
        switch section {
        case 0:
            return "Informations académiques"
        case 1:
            return "Préférences de recherche"
        case 2:
            return "Compétences"
        case 3:
            return "Langues"
        case 4:
            return "Centres d'intérêt"
        default:
            return ""
        }
    }
    
    // MARK: - Save Preferences
    
    /// Sauvegarde les préférences utilisateur sur le backend via StudentPreferencesService
    /// Marque également l'onboarding comme complété pour cet utilisateur spécifique
    /// - Parameter preferences: Les préférences utilisateur à sauvegarder (UserPreferences)
    /// - Note: Les préférences sont sauvegardées sur le backend et en cache local (UserDefaults)
    /// - Important: Nécessite qu'un utilisateur soit connecté (authService.currentUser?.id)
    func savePreferences(_ preferences: UserPreferences) {
        guard !isLoading else { return }
        guard let userId = authService?.currentUser?.id else {
            errorMessage = "Utilisateur non identifié"
            showError = true
            return
        }
        
        // Vérifier que le token d'authentification est présent
        guard let token = authService?.authToken else {
            errorMessage = "Vous devez être connecté pour effectuer cette action"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Sauvegarder sur le backend (étape finale, toutes les données sont complètes)
                // Le token est passé directement depuis AuthService pour garantir la synchronisation
                let response = try await preferencesService.createStudentPreferences(
                    preferences,
                    currentStep: 5,
                    isCompleted: true,
                    token: token
                )
                
                // Convertir la réponse en UserPreferences pour le cache local
                let savedPreferences = response.toUserPreferences()
                
                // Sauvegarder en cache local (UserDefaults) pour améliorer les performances
                if let encoded = try? JSONEncoder().encode(savedPreferences) {
                    UserDefaults.standard.set(encoded, forKey: "userPreferences_\(userId)")
                }
                
                // Marquer l'onboarding comme complété pour cet utilisateur spécifique
                var completedUserIds = UserDefaults.standard.stringArray(forKey: "onboardingCompletedUserIds") ?? []
                if !completedUserIds.contains(userId) {
                    completedUserIds.append(userId)
                    UserDefaults.standard.set(completedUserIds, forKey: "onboardingCompletedUserIds")
                }
                
                await MainActor.run {
                    self.isLoading = false
                    self.onboardingComplete = true
                    print("✅ Préférences sauvegardées avec succès sur le backend pour l'utilisateur: \(userId)")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    if let preferencesError = error as? StudentPreferencesError {
                        // Si le token est expiré, nettoyer la session
                        if case StudentPreferencesError.notAuthenticated = preferencesError {
                            self.errorMessage = "Votre session a expiré. Veuillez vous reconnecter."
                            // Nettoyer la session si le token est expiré
                            authService?.logout()
                        } else {
                            self.errorMessage = preferencesError.errorDescription
                        }
                    } else {
                        self.errorMessage = "Erreur lors de la sauvegarde: \(error.localizedDescription)"
                    }
                    self.showError = true
                    print("❌ Erreur sauvegarde préférences: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Check Onboarding Status
    
    /// Vérifie si l'utilisateur spécifique a complété l'onboarding
    /// Vérifie d'abord le cache local, puis le backend si nécessaire
    /// - Parameter userId: L'identifiant de l'utilisateur
    /// - Returns: True si l'onboarding est complété, false sinon
    static func hasCompletedOnboarding(for userId: String?) -> Bool {
        guard let userId = userId else {
            return false
        }
        
        // Vérifier le cache local d'abord
        let completedUserIds = UserDefaults.standard.stringArray(forKey: "onboardingCompletedUserIds") ?? []
        return completedUserIds.contains(userId)
    }
    
    /// Vérifie si l'utilisateur a complété l'onboarding en interrogeant le backend
    /// - Returns: True si l'onboarding est complété, false sinon
    func checkOnboardingStatusFromBackend() async -> Bool {
        do {
            let response = try await preferencesService.getMyStudentPreferences()
            return response.isCompleted ?? false
        } catch {
            // Si les préférences n'existent pas (404), l'onboarding n'est pas complété
            if case StudentPreferencesError.notFound = error {
                return false
            }
            // Pour les autres erreurs, retourner false par sécurité
            print("⚠️ Erreur lors de la vérification du statut d'onboarding: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Get Preferences
    
    /// Récupère les préférences sauvegardées depuis le cache local (UserDefaults)
    /// - Parameter userId: L'identifiant unique de l'utilisateur (optionnel)
    /// - Returns: Les préférences utilisateur décodées depuis UserDefaults, ou `nil` si non trouvées
    /// - Note: Utilise la clé "userPreferences_{userId}" pour récupérer les données
    /// - Usage: Permet de pré-remplir le formulaire d'onboarding avec les préférences précédentes
    static func getSavedPreferences(for userId: String?) -> UserPreferences? {
        guard let userId = userId,
              let data = UserDefaults.standard.data(forKey: "userPreferences_\(userId)"),
              let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return nil
        }
        return preferences
    }
    
    /// Récupère les préférences depuis le backend
    /// - Returns: Les préférences utilisateur, ou `nil` si non trouvées
    func getPreferencesFromBackend() async -> UserPreferences? {
        await MainActor.run {
            isLoadingPreferences = true
        }
        
        do {
            let response = try await preferencesService.getMyStudentPreferences()
            let preferences = response.toUserPreferences()
            
            // Mettre à jour le cache local
            if let userId = authService?.currentUser?.id,
               let encoded = try? JSONEncoder().encode(preferences) {
                UserDefaults.standard.set(encoded, forKey: "userPreferences_\(userId)")
            }
            
            await MainActor.run {
                self.loadedPreferences = preferences
                self.isLoadingPreferences = false
            }
            
            return preferences
        } catch {
            if case StudentPreferencesError.notFound = error {
                await MainActor.run {
                    self.isLoadingPreferences = false
                }
                return nil
            }
            
            // Si le token est expiré, nettoyer la session
            if case StudentPreferencesError.notAuthenticated = error {
                print("🔒 Token expiré lors de la récupération des préférences - Nettoyage de la session")
                await MainActor.run {
                    self.isLoadingPreferences = false
                    authService?.logout()
                }
                return nil
            }
            
            print("⚠️ Erreur lors de la récupération des préférences: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoadingPreferences = false
            }
            return nil
        }
    }
    
    /// Charge les préférences depuis le backend ou le cache local
    /// Utilisé pour pré-remplir le formulaire d'onboarding
    func loadPreferencesForEditing() async {
        // Essayer d'abord depuis le backend
        if await getPreferencesFromBackend() != nil {
            print("✅ Préférences chargées depuis le backend")
            return
        }
        
        // Si le backend ne retourne rien, essayer le cache local
        if let userId = authService?.currentUser?.id,
           let cachedPreferences = OnboardingViewModel.getSavedPreferences(for: userId) {
            await MainActor.run {
                self.loadedPreferences = cachedPreferences
                print("✅ Préférences chargées depuis le cache local")
            }
        } else {
            print("ℹ️ Aucune préférence trouvée, formulaire vide")
        }
    }
    
    // MARK: - Reset Onboarding
    
    /// Réinitialise l'onboarding pour un utilisateur spécifique (cache local uniquement)
    /// Permet à l'utilisateur de refaire l'onboarding en supprimant son statut de la liste des utilisateurs complétés
    /// - Parameter userId: L'identifiant unique de l'utilisateur à réinitialiser (optionnel)
    /// - Note: Les préférences sauvegardées ne sont pas supprimées, seul le statut "complété" est retiré
    /// - Usage: Appelé depuis MenuView quand l'utilisateur choisit "Modifier mes préférences"
    static func resetOnboarding(for userId: String?) {
        guard let userId = userId else { return }
        
        var completedUserIds = UserDefaults.standard.stringArray(forKey: "onboardingCompletedUserIds") ?? []
        completedUserIds.removeAll { $0 == userId }
        UserDefaults.standard.set(completedUserIds, forKey: "onboardingCompletedUserIds")
        
        print("✅ Onboarding réinitialisé pour l'utilisateur: \(userId)")
    }
    
    /// Supprime les préférences de l'utilisateur depuis le backend
    /// - Note: Supprime également le cache local
    func deletePreferences() async throws {
        try await preferencesService.deleteMyStudentPreferences()
        
        // Supprimer le cache local
        if let userId = authService?.currentUser?.id {
            UserDefaults.standard.removeObject(forKey: "userPreferences_\(userId)")
            var completedUserIds = UserDefaults.standard.stringArray(forKey: "onboardingCompletedUserIds") ?? []
            completedUserIds.removeAll { $0 == userId }
            UserDefaults.standard.set(completedUserIds, forKey: "onboardingCompletedUserIds")
        }
        
        print("✅ Préférences supprimées avec succès")
    }
    
    /// Met à jour une étape spécifique du formulaire
    /// - Parameters:
    ///   - step: Le numéro de l'étape (1-5)
    ///   - data: Les données de l'étape sous forme de dictionnaire
    ///   - markCompleted: Si true, marque le formulaire comme complété
    func updateStep(step: Int, data: [String: String], markCompleted: Bool? = nil) async throws {
        _ = try await preferencesService.updateStep(step: step, data: data, markCompleted: markCompleted)
        print("✅ Étape \(step) mise à jour avec succès")
    }
}

