//
//  ContentView.swift
//  Taleb_5edma
//
//  Created by Apple on 09/11/2025.
//

// ContentView.swift
import SwiftUI

// MARK: - ContentView

/// Vue principale qui gère l'affichage conditionnel du contenu selon l'état de l'utilisateur
/// Détermine si l'utilisateur doit voir l'écran d'onboarding, le dashboard, ou les écrans d'authentification
/// Coordonne la logique entre AuthService, OnboardingViewModel et les différentes vues de l'application
struct ContentView: View {
    // MARK: - Properties
    
    /// Service d'authentification partagé dans toute l'application
    /// 
    /// **Utilisation de @EnvironmentObject :**
    /// - Cette propriété reçoit l'instance de `AuthService` créée dans `Taleb_5edmaApp`
    /// - Contrairement à `@StateObject`, `@EnvironmentObject` ne crée pas une nouvelle instance
    /// - Cela garantit que toutes les vues utilisent la même instance partagée
    /// - Les modifications dans `authService` (comme la connexion/déconnexion) sont automatiquement propagées
    /// 
    /// **Avantages pour la persistance de session :**
    /// - L'instance `AuthService` est créée une seule fois au démarrage de l'application
    /// - Elle charge automatiquement la session depuis UserDefaults dans son initializer
    /// - Toutes les vues accèdent aux mêmes données utilisateur et token
    /// - Lorsque la session est restaurée, toutes les vues sont automatiquement mises à jour
    @EnvironmentObject var authService: AuthService
    
    /// Indicateur local du statut d'onboarding de l'utilisateur
    /// Synchronisé avec UserDefaults via OnboardingViewModel
    @State private var hasCompletedOnboarding = false
    
    /// ViewModel pour gérer la logique et la persistance de l'onboarding
    /// Gère la sauvegarde et la vérification des préférences utilisateur
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    
    // MARK: - Computed Properties
    
    /// Calcule si l'écran d'onboarding doit être affiché pour l'utilisateur actuel
    /// Vérifie si l'utilisateur est connecté (avec token ET utilisateur) et s'il a déjà complété l'onboarding
    /// Retourne `true` si l'onboarding doit être affiché, `false` sinon
    private var shouldShowOnboarding: Bool {
        // Vérifier strictement que l'utilisateur est authentifié avec token ET profil
        guard authService.isAuthenticated,
              authService.authToken != nil,
              authService.currentUser != nil,
              let userId = authService.currentUser?.id else {
            // Si l'utilisateur n'est pas complètement authentifié, ne pas afficher l'onboarding
            return false
        }
        return !OnboardingViewModel.hasCompletedOnboarding(for: userId)
    }
    
    // MARK: - Body
    
    /// Structure principale de la vue avec navigation conditionnelle
    /// Affiche différents écrans selon l'état d'authentification et d'onboarding
    var body: some View {
        Group {
            // Vérifier d'abord si l'utilisateur est authentifié
            if authService.isAuthenticated {
                // Utilisateur connecté : vérifier le statut d'onboarding
                if !shouldShowOnboarding {
                    // L'utilisateur a complété l'onboarding : afficher le tableau de bord principal
                    // DashboardView contient la TabView avec tous les onglets de l'application
                    DashboardView()
                        .environmentObject(authService)
                } else {
                    // Premier lancement pour ce compte : afficher l'écran d'onboarding
                    // Permet à l'utilisateur de définir ses préférences (niveau d'étude, domaine, etc.)
                    OnboardingView()
                        .environmentObject(authService)
                        .environmentObject(onboardingViewModel)
                        .onAppear {
                            // Initialiser le service d'authentification dans le ViewModel
                            onboardingViewModel.authService = authService
                            // Vérifier le statut d'onboarding au chargement de l'écran
                            checkOnboardingStatus()
                        }
                        .onChange(of: onboardingViewModel.onboardingComplete) { oldValue, newValue in
                            // Quand l'onboarding est complété, mettre à jour l'état local
                            // Cela déclenchera un re-render et affichera le DashboardView
                            if newValue {
                                hasCompletedOnboarding = true
                            }
                        }
                        .onChange(of: authService.currentUser?.id) { oldValue, newValue in
                            // Si l'utilisateur change (déconnexion/reconnexion), vérifier à nouveau l'onboarding
                            // Nécessaire car chaque utilisateur a son propre statut d'onboarding
                            checkOnboardingStatus()
                        }
                }
            } else {
                // Aucun utilisateur connecté : afficher le parcours d'authentification
                // AuthCoordinatorView gère la navigation entre Login, SignUp et Verification
                AuthCoordinatorView()
                    .environmentObject(authService)
            }
        }
        // Injecter le service d'authentification dans l'environnement pour toutes les sous-vues
        .environmentObject(authService)
        .onAppear {
            // Debug: Vérifier l'état d'authentification au démarrage de l'application
            // Utile pour diagnostiquer les problèmes de connexion ou d'onboarding
            #if DEBUG
            print("🔍 ContentView - État authentification: \(authService.isAuthenticated)")
            print("🔍 ContentView - Token présent: \(authService.authToken != nil)")
            print("🔍 ContentView - Utilisateur présent: \(authService.currentUser != nil)")
            if let userId = authService.currentUser?.id {
                print("🔍 ContentView - ID Utilisateur: \(userId)")
                print("🔍 ContentView - Onboarding complété: \(!shouldShowOnboarding)")
            }
            #endif
            // Vérifier le statut d'onboarding au chargement
            checkOnboardingStatus()
        }
        .onChange(of: authService.isAuthenticated) { oldValue, newValue in
            // Quand l'état d'authentification change (connexion ou déconnexion)
            if newValue {
                // Utilisateur vient de se connecter : vérifier immédiatement l'onboarding
                checkOnboardingStatus()
            } else {
                // Utilisateur s'est déconnecté : réinitialiser l'état d'onboarding
                hasCompletedOnboarding = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Vérifie et met à jour le statut d'onboarding pour l'utilisateur actuel
    /// Utilise OnboardingViewModel pour interroger UserDefaults et déterminer
    /// si l'utilisateur a déjà complété l'onboarding pour ce compte spécifique
    private func checkOnboardingStatus() {
        // Vérifier qu'un utilisateur est connecté
        guard let userId = authService.currentUser?.id else {
            // Pas d'utilisateur : considérer que l'onboarding n'est pas complété
            hasCompletedOnboarding = false
            return
        }
        // Vérifier dans UserDefaults si cet utilisateur spécifique a complété l'onboarding
        hasCompletedOnboarding = OnboardingViewModel.hasCompletedOnboarding(for: userId)
        
        #if DEBUG
        print("🔍 ContentView - Vérification onboarding - UserID: \(userId), Complété: \(hasCompletedOnboarding)")
        #endif
    }
}

#Preview {
    ContentView()
}

