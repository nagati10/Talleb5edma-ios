//
//  DashboardView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

//
//  DashboardView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    
    // États locaux pour piloter la navigation et les affichages contextuels de la vue
    @State private var selectedTab = 3
    @State private var showingNotifications = false
    @State private var showingProfile = false
    @State private var showingMenu = false
    @State private var isExamModeEnabled = false
    @State private var showingCalendar = false
    @State private var showingRoutineBalance = false
    
    // ViewModels pour l'analyse IA
    @StateObject private var evenementViewModel = EvenementViewModel()
    @StateObject private var availabilityViewModel = AvailabilityViewModel()
    @StateObject private var routineBalanceViewModel = RoutineBalanceViewModel()
    
    // Données de démonstration
    private let notificationCount = 3
    private let jobsHours: Double = 15
    private let coursesHours: Double = 5
    private let otherHours: Double = 2
    private let maxHours: Double = 20
    
    private var totalHours: Double {
        jobsHours + coursesHours + otherHours
    }
    
    // Nom d'utilisateur depuis le service d'authentification
    private var userName: String {
        // Récupère le prénom (premier mot) du nom de l'utilisateur
        let fullName = authService.currentUser?.nom ?? "Étudiant"
        return fullName.components(separatedBy: " ").first ?? "Étudiant"
    }
    
    // Événements du jour
    private let todayEvents: [DailyEvent] = [
        DailyEvent(
            id: "1",
            title: "Assistant de chantier",
            time: "09:00 - 13:00",
            type: .job,
            location: "Centre ville Tunis"
        ),
        DailyEvent(
            id: "2",
            title: "Mathématiques",
            time: "14:00 - 16:00",
            type: .course,
            location: "Salle A101"
        )
    ]
    
    var body: some View {
        // TabView principal qui regroupe les différentes sections majeures de l'application
        TabView(selection: $selectedTab) {
            // Écran 1 - Dashboard/Accueil
            homeScreen
            .tag(0)
            
            // Écran 2 - Calendrier
            NavigationView {
                MainContentWrapper(
                    showingNotifications: $showingNotifications,
                    showingProfile: $showingProfile,
                    showingMenu: $showingMenu,
                    notificationCount: notificationCount
                ) {
                CalendarView()
                }
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Calendrier")
            }
            .tag(1)
            
            // Écran 3 - Disponibilités
            NavigationView {
                MainContentWrapper(
                    showingNotifications: $showingNotifications,
                    showingProfile: $showingProfile,
                    showingMenu: $showingMenu,
                    notificationCount: notificationCount
                ) {
                AvailabilityView()
                }
            }
            .tabItem {
                Image(systemName: "clock.fill")
                Text("Dispo")
            }
            .tag(2)
            
            // Écran 4 - Offres d'emploi
            NavigationView {
                MainContentWrapper(
                    showingNotifications: $showingNotifications,
                    showingProfile: $showingProfile,
                    showingMenu: $showingMenu,
                    notificationCount: notificationCount
                ) {
                    OffersView()
                }
            }
            .tabItem {
                Image(systemName: "briefcase.fill")
                Text("Offres")
            }
            .tag(3)
        }
        .accentColor(AppColors.primaryRed)
        .sheet(isPresented: $showingNotifications) {
            // TODO: Créer NotificationsView
            Text("Notifications")
        }
        .sheet(isPresented: $showingMenu) {
            MenuView(selectedTab: $selectedTab)
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(authService: authService)
        }
        .onAppear {
            // Configuration de l'apparence de la tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppColors.white)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    // MARK: - Écran 1: Dashboard/Accueil
    
    private var homeScreen: some View {
        ZStack {
            AppColors.backgroundGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header fixe avec menu, notifications et profil
                DashboardHeaderView(
                    showingNotifications: $showingNotifications,
                    showingProfile: $showingProfile,
                    showingMenu: $showingMenu,
                    notificationCount: notificationCount
                )
                
                // Contenu principal avec ScrollView
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section de bienvenue
                        welcomeSection
                        
                        // Card avec graphique en donut pour les statistiques d'heures
                        WorkStatsCard(
                            jobsHours: jobsHours,
                            coursesHours: coursesHours,
                            otherHours: otherHours,
                            totalHours: totalHours
                        )
                        
                        // Menu rapide avec icônes d'offres
                        QuickOffersMenu { category in
                            // Navigation vers les offres avec filtre de catégorie
                            selectedTab = 3 // Aller à l'onglet Offres
                            // TODO: Implémenter le filtrage par catégorie
                            print("Catégorie sélectionnée: \(category)")
                        }
                        
                        // Card agenda avec événements du jour
                        DailyAgendaCard(events: todayEvents) { event in
                            // TODO: Navigation vers détails de l'événement
                            print("Événement tapé: \(event.title)")
                        }
                        
                        // Toggle Mode Examens
                        ExamModeToggle(isEnabled: $isExamModeEnabled) { isEnabled in
                            // TODO: Activer/désactiver le mode examens
                            print("Mode examens: \(isEnabled ? "activé" : "désactivé")")
                        }
                        
                        // Card Analyse IA - Équilibre de vie
                        RoutineBalanceCard(
                            viewModel: routineBalanceViewModel,
                            onTap: {
                                showingRoutineBalance = true
                            }
                        )
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Charger les données nécessaires pour l'analyse
            Task {
                // Toujours recharger pour avoir les données les plus récentes
                await evenementViewModel.loadEvenements()
                await availabilityViewModel.loadDisponibilites()
                
                // Mettre à jour les références dans routineBalanceViewModel
                // Cela déclenchera automatiquement les observers pour recharger l'analyse
                routineBalanceViewModel.evenementViewModel = evenementViewModel
                routineBalanceViewModel.availabilityViewModel = availabilityViewModel
                
                // Lancer l'analyse initiale avec les données réelles chargées
                await routineBalanceViewModel.analyserRoutine(
                    evenements: evenementViewModel.evenements,
                    disponibilites: availabilityViewModel.disponibilites
                )
            }
        }
        .onChange(of: evenementViewModel.evenements.count) { oldCount, newCount in
            // Recharger l'analyse automatiquement quand les événements changent
            if newCount != oldCount {
                Task {
                    await routineBalanceViewModel.analyserRoutine(
                        evenements: evenementViewModel.evenements,
                        disponibilites: availabilityViewModel.disponibilites
                    )
                }
            }
        }
        .sheet(isPresented: $showingRoutineBalance) {
            NavigationView {
                RoutineBalanceView(
                    evenementViewModel: evenementViewModel,
                    availabilityViewModel: availabilityViewModel
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fermer") {
                            showingRoutineBalance = false
                        }
                        .foregroundColor(AppColors.primaryRed)
                    }
                }
            }
        }
    }
    
    // MARK: - Home Content Sections
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bonjour, \(userName) 👋")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.black)
                    
                    Spacer()
            }
            
            Text("Trouvez le job parfait pour votre emploi du temps")
                .font(.subheadline)
                .foregroundColor(AppColors.mediumGray)
        }
        .padding(.vertical, 8)
        }
    
                 }


#Preview {
    DashboardView()
        .environmentObject(AuthService())
}
