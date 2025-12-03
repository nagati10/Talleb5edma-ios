//
//  Taleb5edma_cursorApp.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import SwiftUI

// MARK: - Taleb5edma_cursorApp

/// Point d'entrée principal de l'application Taleb 5edma
/// Gère le cycle de vie de l'application et la navigation entre les écrans d'authentification
/// et le contenu principal selon l'état de connexion de l'utilisateur
@main
struct Taleb5edma_cursorApp: App {
    // MARK: - Properties
    
    /// Service d'authentification partagé dans toute l'application
    /// 
    /// **Gestion du cycle de vie :**
    /// - Maintenu en vie pour toute la durée de vie de l'application grâce à `@StateObject`
    /// - Créé une seule fois au démarrage de l'application
    /// - Partagé avec toutes les vues via `@EnvironmentObject`
    /// 
    /// **Persistance de session :**
    /// - Au moment de l'initialisation, `AuthService` charge automatiquement :
    ///   - Le token d'authentification depuis UserDefaults (s'il existe)
    ///   - Les informations utilisateur depuis UserDefaults (s'il existe)
    /// - Cela permet de restaurer rapidement la session sans attendre un appel réseau
    /// - La méthode `restoreSession()` est appelée ensuite pour vérifier la validité du token
    @StateObject private var authService = AuthService()
    
    // MARK: - Initialization
    
    /// Initialise l'application et configure les services nécessaires
    init() {
        // Configuration future: Google Sign-In au démarrage de l'application
        // TODO: Configurer GoogleSignIn ici si nécessaire
    }
    
    // MARK: - Body
    
    /// Définit la structure principale de l'application
    /// 
    /// **Navigation conditionnelle basée sur l'authentification :**
    /// - Si l'utilisateur est authentifié (`authService.isAuthenticated == true`) :
    ///   - Affiche `ContentView` qui gère la navigation vers le Dashboard ou l'Onboarding
    ///   - L'utilisateur peut accéder à toutes les fonctionnalités de l'application
    /// 
    /// - Si l'utilisateur n'est pas authentifié (`authService.isAuthenticated == false`) :
    ///   - Affiche `AuthCoordinatorView` qui gère le flux d'authentification
    ///   - L'utilisateur doit se connecter ou s'inscrire
    /// 
    /// **Restauration automatique de session :**
    /// - La méthode `.task` est appelée automatiquement au démarrage de l'application
    /// - Elle appelle `restoreSession()` pour vérifier et restaurer la session si nécessaire
    /// - Cette vérification se fait en arrière-plan sans bloquer l'interface utilisateur
    /// - Si le token est valide mais l'utilisateur manquant, il sera récupéré depuis le serveur
    /// - Si le token est invalide, la session sera nettoyée et l'utilisateur devra se reconnecter
    var body: some Scene {
        WindowGroup {
            Group {
                // Vérifier l'état d'authentification pour déterminer quel écran afficher
                // Cette vérification utilise les données chargées depuis UserDefaults dans l'initializer
                if authService.isAuthenticated {
                    // L'utilisateur est authentifié : afficher le contenu principal de l'application
                    // ContentView gère la navigation vers le Dashboard ou l'Onboarding
                    AppRootView {
                        ContentView()
                            .environmentObject(authService)
                    }                } else {
                    // L'utilisateur n'est pas authentifié : afficher le flux d'authentification
                    // AuthCoordinatorView gère la navigation entre Login, SignUp et Verification
                    AuthCoordinatorView()
                        .environmentObject(authService)
                }
            }
            .task {
                // Restaurer la session au démarrage de l'application
                // Cette méthode vérifie la validité du token et met à jour les données si nécessaire
                // Elle s'exécute en arrière-plan sans bloquer l'interface utilisateur
                // Si une session valide existe déjà dans UserDefaults, aucune action n'est nécessaire
                await authService.restoreSession()
            }
        }
    }
}
