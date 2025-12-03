//
//  OffersView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

// MARK: - OffersView

/// Écran principal affichant la liste de toutes les offres d'emploi disponibles
/// Un des quatre onglets principaux de l'application (accessible depuis la TabView)
///
/// **Fonctionnalités:**
/// - Affichage de toutes les offres d'emploi dans une liste scrollable
/// - Barre de recherche pour filtrer par titre, entreprise ou localisation
/// - Filtres rapides par catégorie (tous, BTP, Informatique, etc.)
/// - Menu déroulant avec options : Filtres avancés, QR, Map, AI-CV
/// - Header avec gradient rouge bordeaux affichant le nombre d'offres
/// - État vide avec message si aucune offre ne correspond aux critères
///
/// **Navigation:**
/// - Tap sur une carte d'offre → Ouvre `OfferDetailView` en sheet
/// - Bouton "Filtre" → Ouvre `FilterDropdownMenu` avec options
/// - Création d'offre → Accessible depuis le menu latéral
///
/// **Utilisation:**
/// Intégré dans `DashboardView` comme onglet "Offres" (tag 3)
struct OffersView: View {
    // MARK: - Environment
    
    /// Service d'authentification pour accéder aux informations utilisateur
    @EnvironmentObject var authService: AuthService
    
    // MARK: - State Properties
    
    /// Texte saisi dans la barre de recherche pour filtrer les offres
    @State private var searchText = ""
    
    /// Catégorie d'emploi sélectionnée pour le filtrage
    @State private var selectedFilter: JobCategory = .all
    
    /// Indique si la vue des filtres avancés doit être affichée
    @State private var showingFilters = false
    
    /// Indique si la vue de génération QR doit être affichée
    @State private var showingQRGenerator = false
    
    /// Indique si la vue de carte doit être affichée
    @State private var showingMap = false
    
    /// Indique si la vue d'analyse AI-CV doit être affichée
    @State private var showingAICV = false
    
    // MARK: - ViewModel
    
    /// ViewModel pour gérer la logique métier des offres
    @StateObject private var viewModel = OffreViewModel()
    
    /// Offre sélectionnée pour afficher les détails
    @State private var selectedOffre: Offre?
    
    // MARK: - Computed Properties
    
    /// Filtre les offres selon les critères de recherche et de catégorie
    /// - Returns: Liste des offres filtrées correspondant aux critères
    /// - Note: Recherche insensible à la casse dans le titre, l'entreprise et la localisation
    var filteredOffres: [Offre] {
        var filtered = viewModel.offres
        
        // Filtrage par catégorie (si une catégorie spécifique est sélectionnée)
        if selectedFilter != .all {
            filtered = filtered.filter { offre in
                offre.category?.localizedCaseInsensitiveContains(selectedFilter.rawValue) ?? false
            }
        }
        
        // Filtrage par texte de recherche (titre, entreprise, localisation)
        if !searchText.isEmpty {
            filtered = filtered.filter { offre in
                offre.title.localizedCaseInsensitiveContains(searchText) ||
                offre.company.localizedCaseInsensitiveContains(searchText) ||
                offre.location.address.localizedCaseInsensitiveContains(searchText) ||
                (offre.location.city?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header avec opportunités
                opportunitiesHeader
                
                // Filtres rapides
                quickFiltersSection
                
                // Liste des offres
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredOffres.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredOffres) { offre in
                                OffreCardView(offre: offre)
                                    .onTapGesture {
                                        selectedOffre = offre
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingFilters) {
            FilterView()
        }
        .sheet(isPresented: $showingQRGenerator) {
            QRGeneratorView()
        }
        .sheet(isPresented: $showingMap) {
            JobsMapView(offres: viewModel.offres)
        }
        .sheet(isPresented: $showingAICV) {
            AICVAnalysisView()
        }
        .sheet(item: $selectedOffre) { offre in
            OffreDetailView(offre: offre, viewModel: viewModel)
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue")
        }
        .onAppear {
            Task {
                await viewModel.loadOffres()
            }
        }
    }
    
    // MARK: - Opportunities Header
    
    private var opportunitiesHeader: some View {
        VStack(spacing: 0) {
            // Header avec dégradé rouge-rose
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.primaryRed, AppColors.accentPink]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppColors.white)
                            
                            Text("Nouvelles opportunités")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.white)
                        }
                        
                        Text("\(filteredOffres.count) offres pour vous")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Icône circulaire
                    ZStack {
                        Circle()
                            .fill(AppColors.white)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(AppColors.primaryRed)
                    }
                }
                .padding()
            }
            .frame(height: 120)
            
            // Barre de recherche et filtres
            VStack(spacing: 12) {
                // Barre de recherche
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.mediumGray)
                    
                    TextField("Rechercher un emploi...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.mediumGray)
                        }
                    }
                }
                .searchBarStyle()
                
                // Boutons d'action
                HStack(spacing: 12) {
                    FilterDropdownMenu(
                        isExpanded: .constant(false),
                        onAdvancedFiltersSelected: {
                            showingFilters = true
                        },
                        onQRSelected: {
                            showingQRGenerator = true
                        },
                        onMapSelected: {
                            showingMap = true
                        },
                        onAICVSelected: {
                            showingAICV = true
                        }
                    )
                }
            }
            .padding()
            .background(AppColors.white)
        }
    }
    
    // MARK: - Quick Filters Section
    
    private var quickFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(JobCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: selectedFilter == category
                    ) {
                        selectedFilter = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(AppColors.white)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "briefcase")
                .font(.system(size: 60))
                .foregroundColor(AppColors.mediumGray)
            
            Text("Aucune offre trouvée")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.black)
            
            Text("Essayez de modifier vos critères de recherche")
                .font(.subheadline)
                .foregroundColor(AppColors.mediumGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - OffreCardView

/// Composant pour afficher une carte d'offre dans la liste
struct OffreCardView: View {
    let offre: Offre
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(offre.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.black)
                        .lineLimit(2)
                    
                    Text(offre.company)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mediumGray)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.primaryRed)
                        Text(offre.location.address)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.mediumGray)
                    }
                }
                
                Spacer()
                
                if let salary = offre.salary {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(salary)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.primaryRed)
                    }
                }
            }
            
            if let tags = offre.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.primaryRed.opacity(0.1))
                                .foregroundColor(AppColors.primaryRed)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            HStack {
                if let likeCount = offre.likeCount {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                        Text("\(likeCount)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppColors.mediumGray)
                }
                
                Spacer()
                
                if let viewCount = offre.viewCount {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 12))
                        Text("\(viewCount)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppColors.mediumGray)
                }
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        OffersView()
    }
}

