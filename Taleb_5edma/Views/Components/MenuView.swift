//
//  MenuView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

// MARK: - MenuView

/// Menu latéral modal affichant toutes les options de navigation de l'application
/// Accessible depuis le bouton menu ☰ dans le header de toutes les pages principales
///
/// **Fonctionnalités:**
/// - Navigation vers les écrans principaux (Accueil, Calendrier, Disponibilités, Offres)
/// - Accès aux favoris, réclamations, profil
/// - Création d'offres d'emploi
/// - Modification des préférences utilisateur (onboarding)
///
/// **Structure:**
/// - Header avec informations utilisateur (nom, email, photo)
/// - Sections organisées par catégorie (Navigation, Favoris, Offres, Compte)
/// - Bouton de fermeture en haut à droite
///
/// **Utilisation:**
/// Présenté comme une sheet depuis `DashboardHeaderView` quand l'utilisateur clique sur le menu ☰
struct MenuView: View {
    // MARK: - Environment & Bindings
    
    /// Ferme la sheet du menu quand appelé
    @Environment(\.dismiss) var dismiss
    
    /// Service d'authentification pour obtenir les informations utilisateur
    @EnvironmentObject var authService: AuthService
    
    /// Binding vers l'onglet sélectionné dans DashboardView pour navigation entre onglets
    @Binding var selectedTab: Int
    
    // MARK: - State Properties
    
    /// Indique si la vue des favoris doit être affichée
    @State private var showingFavorites = false
    
    /// Indique si la vue des réclamations doit être affichée
    @State private var showingReclamations = false
    
    /// Indique si la vue du profil doit être affichée
    @State private var showingProfile = false
    
    /// Indique si l'écran d'onboarding doit être affiché (pour modifier les préférences)
    @State private var showingOnboarding = false
    
    /// Indique si l'écran de création d'offre doit être affiché
    @State private var showingCreateOffer = false
    
    /// Indique si la vue des offres de l'utilisateur doit être affichée
    @State private var showingMyOffres = false
    
    /// Indique si la vue des données biométriques doit être affichée
    @State private var showingBioData = false
    
    /// Flag pour gérer la navigation vers l'onglet Offres après fermeture de FavoritesView
    @State private var shouldNavigateToOffers = false
    
    /// ViewModel pour gérer l'onboarding et la sauvegarde des préférences
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header avec informations utilisateur
                        menuHeader
                        
                        // Options du menu
                        menuOptions
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
            }
            .sheet(isPresented: $showingFavorites, onDismiss: {
                // Si on vient de fermer FavoritesView pour aller aux offres
                if shouldNavigateToOffers {
                    shouldNavigateToOffers = false
                    selectedTab = 4
                    dismiss()
                }
            }) {
                NavigationView {
                    FavoritesView(
                        onBrowseOffers: {
                            // Marquer qu'on veut naviguer vers les offres
                            shouldNavigateToOffers = true
                            // Fermer FavoritesView (cela déclenchera onDismiss)
                            showingFavorites = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingReclamations) {
                ReclamationsView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(authService: authService)
            }
            .sheet(isPresented: $showingMyOffres) {
                NavigationView {
                    MyOffresView()
                }
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
                    .environmentObject(authService)
                    .environmentObject(onboardingViewModel)
                    .onAppear {
                        onboardingViewModel.authService = authService
                    }
                    .onChange(of: onboardingViewModel.onboardingComplete) { oldValue, newValue in
                        if newValue {
                            showingOnboarding = false
                        }
                    }
            }
            .sheet(isPresented: $showingCreateOffer) {
                CreateOfferView()
                    .environmentObject(authService)
            }
        }
    }
    
    // MARK: - Menu Header
    
    private var menuHeader: some View {
        VStack(spacing: 16) {
            // Photo de profil
            ZStack {
                Circle()
                    .fill(AppColors.primaryRed)
                    .frame(width: 80, height: 80)
                
                if let imageUrl = authService.currentUser?.image, !imageUrl.isEmpty {
                    Text("IMG")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text(getInitials(from: authService.currentUser?.nom ?? "U"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Nom et email
            VStack(spacing: 4) {
                Text(authService.currentUser?.nom ?? "Utilisateur")
                    .font(.headline)
                    .foregroundColor(AppColors.black)
                
                Text(authService.currentUser?.email ?? "email@exemple.com")
                    .font(.subheadline)
                    .foregroundColor(AppColors.mediumGray)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(AppColors.white)
    }
    
    // MARK: - Menu Options
    
    private var menuOptions: some View {
        VStack(spacing: 16) {
            // Section Navigation
            MenuSection(title: "Navigation") {
                MenuItem(
                    icon: "house.fill",
                    iconColor: AppColors.primaryRed,
                    title: "Accueil",
                    action: {
                        selectedTab = 0
                        dismiss()
                    }
                )
                
                MenuItem(
                    icon: "calendar",
                    iconColor: AppColors.darkGray,
                    title: "Calendrier",
                    action: {
                        selectedTab = 1
                        dismiss()
                    }
                )
                
                MenuItem(
                    icon: "clock.fill",
                    iconColor: AppColors.primaryRed,
                    title: "Disponibilités",
                    action: {
                        selectedTab = 2
                        dismiss()
                    }
                )
                
                MenuItem(
                    icon: "briefcase.fill",
                    iconColor: AppColors.successGreen,
                    title: "Offres d'emploi",
                    action: {
                        selectedTab = 3
                        dismiss()
                    }
                )
            }
            
            // Section Favoris
            MenuSection(title: "Favoris") {
                MenuItem(
                    icon: "heart.fill",
                    iconColor: AppColors.primaryRed,
                    title: "Mes offres favorites",
                    action: {
                        showingFavorites = true
                    }
                )
            }
            
            // Section Offres
            MenuSection(title: "Offres") {
                MenuItem(
                    icon: "briefcase.fill",
                    iconColor: AppColors.primaryRed,
                    title: "Mes offres",
                    action: {
                        showingMyOffres = true
                    }
                )
                
                MenuItem(
                    icon: "plus.circle.fill",
                    iconColor: AppColors.primaryRed,
                    title: "Créer une offre",
                    action: {
                        showingCreateOffer = true
                    }
                )
            }
            
            // Section Compte
            MenuSection(title: "Compte") {
                MenuItem(
                    icon: "person.circle",
                    iconColor: AppColors.primaryRed,
                    title: "Mon profil",
                    action: {
                        showingProfile = true
                    }
                )
                
                MenuItem(
                    icon: "exclamationmark.bubble",
                    iconColor: AppColors.primaryRed,
                    title: "Mes réclamations",
                    action: {
                        showingReclamations = true
                    }
                )
                
                MenuItem(
                    icon: "slider.horizontal.3",
                    iconColor: AppColors.primaryRed,
                    title: "Modifier mes préférences",
                    action: {
                        // Réinitialiser l'onboarding pour permettre de le refaire
                        if let userId = authService.currentUser?.id {
                            OnboardingViewModel.resetOnboarding(for: userId)
                        }
                        // Réinitialiser le ViewModel pour permettre de recommencer
                        onboardingViewModel.onboardingComplete = false
                        // Charger les préférences depuis le backend avant d'afficher
                        Task {
                            await loadSavedPreferences()
                            await MainActor.run {
                                showingOnboarding = true
                            }
                        }
                    }
                )
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func getInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else {
            return String(name.prefix(1)).uppercased()
        }
    }
    
    /// Charge les préférences sauvegardées depuis le backend
    /// Les préférences seront utilisées pour pré-remplir le formulaire d'onboarding
    private func loadSavedPreferences() async {
        // S'assurer que l'authService est configuré dans le ViewModel
        onboardingViewModel.authService = authService
        
        // Charger les préférences (le ViewModel les stockera dans loadedPreferences)
        await onboardingViewModel.loadPreferencesForEditing()
    }
}

// MARK: - Menu Section

struct MenuSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.mediumGray)
                .padding(.horizontal)
                .padding(.top, 8)
            
            VStack(spacing: 0) {
                content
            }
            .background(AppColors.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Menu Item

struct MenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 32)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(AppColors.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.mediumGray)
            }
            .padding()
        }
        
        Divider()
            .padding(.leading, 48)
            .background(AppColors.separatorGray)
    }
}

#Preview {
    MenuView(selectedTab: .constant(0))
        .environmentObject(AuthService())
}

