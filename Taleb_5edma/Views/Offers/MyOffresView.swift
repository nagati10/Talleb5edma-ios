//
//  MyOffresView.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import SwiftUI

/// Vue pour afficher et gérer les offres de l'utilisateur connecté
/// Permet de modifier et supprimer ses propres offres
struct MyOffresView: View {
    @StateObject private var viewModel = OffreViewModel()
    @State private var selectedOffre: Offre?
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var offreToDelete: Offre?
    
    var body: some View {
        ZStack {
            AppColors.backgroundGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Liste des offres
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.offres.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.offres) { offre in
                                MyOffreCard(offre: offre) {
                                    selectedOffre = offre
                                    showingEditSheet = true
                                } onDelete: {
                                    offreToDelete = offre
                                    showingDeleteAlert = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedOffre) { offre in
            EditOfferView(offre: offre, viewModel: viewModel) {
                Task {
                    await viewModel.loadMyOffres()
                }
            }
        }
        .alert("Supprimer l'offre", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) {
                offreToDelete = nil
            }
            Button("Supprimer", role: .destructive) {
                if let offre = offreToDelete {
                    Task {
                        await deleteOffre(offre)
                    }
                }
            }
        } message: {
            if let offre = offreToDelete {
                Text("Êtes-vous sûr de vouloir supprimer l'offre \"\(offre.title)\" ? Cette action est irréversible.")
            }
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue")
        }
        .onAppear {
            Task {
                await viewModel.loadMyOffres()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.primaryRed, AppColors.accentPink]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mes offres")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(viewModel.offres.count) offre\(viewModel.offres.count > 1 ? "s" : "")")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .frame(height: 120)
            
            // Barre de recherche optionnelle
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.mediumGray)
                
                Text("Rechercher dans mes offres...")
                    .font(.subheadline)
                    .foregroundColor(AppColors.mediumGray)
                
                Spacer()
            }
            .padding()
            .background(AppColors.white)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "briefcase")
                .font(.system(size: 60))
                .foregroundColor(AppColors.mediumGray)
            
            Text("Aucune offre")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.black)
            
            Text("Vous n'avez pas encore créé d'offre")
                .font(.subheadline)
                .foregroundColor(AppColors.mediumGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Actions
    
    private func deleteOffre(_ offre: Offre) async {
        let success = await viewModel.deleteOffre(offre.id)
        if success {
            offreToDelete = nil
        }
    }
}

// MARK: - My Offre Card

struct MyOffreCard: View {
    let offre: Offre
    let onEdit: () -> Void
    let onDelete: () -> Void
    
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
                    
                    if let city = offre.location.city {
                        Text(city)
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
            
            // Tags
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
            
            // Statistiques
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
                
                if let viewCount = offre.viewCount {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 12))
                        Text("\(viewCount)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppColors.mediumGray)
                }
                
                Spacer()
                
                // Badge actif/inactif
                if let isActive = offre.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isActive ? AppColors.successGreen : AppColors.mediumGray)
                            .frame(width: 6, height: 6)
                        Text(isActive ? "Active" : "Inactive")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isActive ? AppColors.successGreen : AppColors.mediumGray)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    HStack {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                        Text("Modifier")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(AppColors.primaryRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.primaryRed, lineWidth: 1.5)
                    )
                    .cornerRadius(8)
                }
                
                Button(action: onDelete) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text("Supprimer")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.primaryRed)
                    .cornerRadius(8)
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
        MyOffresView()
    }
}

