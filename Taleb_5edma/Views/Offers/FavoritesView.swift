//
//  FavoritesView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Vue pour afficher et gérer les offres favorites
struct FavoritesView: View {
    @StateObject private var favoritesService = FavoritesService.shared
    @StateObject private var viewModel = OffreViewModel()
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showingComparison = false
    @State private var selectedOffre: Offre?
    @Environment(\.dismiss) var dismiss
    
    // Callback optionnel pour naviguer vers les offres
    var onBrowseOffers: (() -> Void)?
    
    private var favoriteOffres: [Offre] {
        favoritesService.filterFavoriteOffres(from: viewModel.offres)
    }
    
    var filteredOffres: [Offre] {
        if searchText.isEmpty {
            return favoriteOffres
        } else {
            return favoriteOffres.filter { offre in
                offre.title.localizedCaseInsensitiveContains(searchText) ||
                offre.company.localizedCaseInsensitiveContains(searchText) ||
                offre.location.address.localizedCaseInsensitiveContains(searchText) ||
                (offre.location.city?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Barre de recherche
                if !favoriteOffres.isEmpty {
                    searchBarSection
                    
                    // Bouton de comparaison (visible uniquement s'il y a au moins 2 offres favorites)
                    if favoriteOffres.count >= 2 {
                        comparisonButtonSection
                    }
                }
                
                // Contenu
                if isLoading || viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppColors.primaryRed)
                } else if filteredOffres.isEmpty && !isLoading {
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
            }
        }
        .onAppear {
            loadFavoriteOffres()
        }
        .sheet(item: $selectedOffre) { offre in
            OffreDetailView(offre: offre, viewModel: viewModel)
        }
        .sheet(isPresented: $showingComparison) {
            OfferComparisonView()
        }
    }
    
    // MARK: - Comparison Button Section
    
    private var comparisonButtonSection: some View {
        HStack {
            Button(action: {
                showingComparison = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Comparer les offres")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppColors.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(AppColors.primaryRed)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(AppColors.white)
    }
    
    // MARK: - Search Bar Section
    
    private var searchBarSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.mediumGray)
                
                TextField("Rechercher dans vos favoris...", text: $searchText)
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
        }
        .padding()
        .background(AppColors.white)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: searchText.isEmpty ? "heart.slash" : "magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(AppColors.mediumGray)
            
            Text(searchText.isEmpty ? "Aucune offre favorite" : "Aucun résultat")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.black)
            
            Text(
                searchText.isEmpty
                    ? "Les offres que vous ajoutez aux favoris apparaîtront ici"
                    : "Essayez de modifier vos critères de recherche"
            )
            .font(.subheadline)
            .foregroundColor(AppColors.mediumGray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            
            if searchText.isEmpty {
                Button(action: {
                    if let onBrowseOffers = onBrowseOffers {
                        onBrowseOffers()
                    } else {
                        // Fallback: fermer la vue actuelle
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "briefcase.fill")
                        Text("Parcourir les offres")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.primaryRed)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func loadFavoriteOffres() {
        isLoading = true
        
        Task {
            await viewModel.loadOffres()
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationView {
        FavoritesView()
    }
}

