//
//  MainContentWrapper.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

// MARK: - MainContentWrapper

/// Wrapper générique pour ajouter le header fixe (`DashboardHeaderView`) sur tous les écrans principaux
/// Permet de garantir une apparence et une navigation cohérentes dans toute l'application
///
/// **Fonctionnalités:**
/// - Ajoute automatiquement le `DashboardHeaderView` en haut de chaque écran
/// - Gère les bindings pour le menu, les notifications et le profil
/// - Permet de passer n'importe quel contenu SwiftUI en tant que vue enfant
///
/// **Utilisation:**
/// ```swift
/// MainContentWrapper(
///     showingNotifications: $showingNotifications,
///     showingProfile: $showingProfile,
///     showingMenu: $showingMenu,
///     notificationCount: 3
/// ) {
///     OffersView()
/// }
/// ```
///
/// **Avantages:**
/// - Cohérence visuelle : même header sur toutes les pages
/// - Réutilisabilité : un seul composant pour tous les écrans
/// - Maintenabilité : modifications du header centralisées
struct MainContentWrapper<Content: View>: View {
    // MARK: - Bindings
    
    /// Binding pour contrôler l'affichage des notifications
    @Binding var showingNotifications: Bool
    
    /// Binding pour contrôler l'affichage du profil
    @Binding var showingProfile: Bool
    
    /// Binding pour contrôler l'affichage du menu latéral
    @Binding var showingMenu: Bool
    
    // MARK: - Properties
    
    /// Nombre de notifications non lues à afficher dans le badge
    let notificationCount: Int
    
    /// Contenu spécifique à chaque écran (générique pour accepter n'importe quelle vue)
    let content: Content
    
    init(
        showingNotifications: Binding<Bool> = .constant(false),
        showingProfile: Binding<Bool> = .constant(false),
        showingMenu: Binding<Bool> = .constant(false),
        notificationCount: Int = 0,
        @ViewBuilder content: () -> Content
    ) {
        self._showingNotifications = showingNotifications
        self._showingProfile = showingProfile
        self._showingMenu = showingMenu
        self.notificationCount = notificationCount
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header fixe avec menu, notifications et profil
            DashboardHeaderView(
                showingNotifications: $showingNotifications,
                showingProfile: $showingProfile,
                showingMenu: $showingMenu,
                notificationCount: notificationCount
            )
            
            // Contenu spécifique à chaque écran
            content
        }
    }
}

#Preview {
    MainContentWrapper(notificationCount: 3) {
        ScrollView {
            Text("Contenu de l'écran")
                .padding()
        }
    }
}

