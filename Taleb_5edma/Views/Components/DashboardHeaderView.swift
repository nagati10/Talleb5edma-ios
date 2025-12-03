//
//  DashboardHeaderView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

// MARK: - DashboardHeaderView

/// Header fixe affiché en haut de toutes les pages principales de l'application
/// Contient trois boutons d'action principaux pour la navigation et l'accès rapide
///
/// **Éléments:**
/// - Bouton menu ☰ (gauche) : Ouvre le menu latéral avec toutes les options
/// - Bouton notifications 🔔 (centre-droite) : Affiche les notifications avec badge de compteur
/// - Bouton profil 👤 (droite) : Accède au profil utilisateur
///
/// **Design:**
/// - Fond blanc avec ombre légère pour créer un effet de profondeur
/// - Badge rouge sur l'icône de notification si `notificationCount > 0`
/// - Icône de profil en rouge bordeaux pour correspondre à la palette de l'application
///
/// **Utilisation:**
/// Intégré dans `MainContentWrapper` pour être présent sur toutes les pages principales
/// Les bindings permettent de contrôler l'affichage des modals depuis la vue parente
struct DashboardHeaderView: View {
    // MARK: - Bindings
    
    /// Binding pour contrôler l'affichage de la vue des notifications
    @Binding var showingNotifications: Bool
    
    /// Binding pour contrôler l'affichage de la vue du profil
    @Binding var showingProfile: Bool
    
    /// Binding pour contrôler l'affichage du menu latéral
    @Binding var showingMenu: Bool
    
    // MARK: - Properties
    
    /// Nombre de notifications non lues à afficher dans le badge
    /// Si `notificationCount > 0`, un badge rouge avec le nombre est affiché
    let notificationCount: Int
    
    init(
        showingNotifications: Binding<Bool> = .constant(false),
        showingProfile: Binding<Bool> = .constant(false),
        showingMenu: Binding<Bool> = .constant(false),
        notificationCount: Int = 0
    ) {
        self._showingNotifications = showingNotifications
        self._showingProfile = showingProfile
        self._showingMenu = showingMenu
        self.notificationCount = notificationCount
    }
    
    var body: some View {
        HStack {
            // Bouton menu ☰
            Button(action: {
                showingMenu = true
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(AppColors.black)
            }
            
            Spacer()
            
            // Notifications 🔔 avec badge
            Button(action: {
                showingNotifications = true
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.black)
                    
                    if notificationCount > 0 {
                        Text("\(notificationCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(AppColors.primaryRed)
                            .clipShape(Circle())
                            .offset(x: 8, y: -8)
                    }
                }
            }
            .padding(.trailing, 16)
            
            // Profil 👤
            Button(action: {
                showingProfile = true
            }) {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.primaryRed)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(AppColors.white)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    VStack(spacing: 0) {
        DashboardHeaderView(notificationCount: 3)
        Spacer()
    }
    .background(AppColors.backgroundGray)
}

