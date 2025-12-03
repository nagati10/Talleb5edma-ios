//
//  ReclamationsView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

struct ReclamationsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var reclamationService = ReclamationService()
    // Texte saisi dans la barre de recherche
    @State private var searchText = ""
    // Présente le formulaire de création d'une nouvelle réclamation
    @State private var showingAddReclamation = false
    // Réclamation à modifier
    @State private var reclamationToEdit: Reclamation?
    // Réclamation à supprimer
    @State private var reclamationToDelete: Reclamation?
    // Affiche l'alerte de confirmation de suppression
    @State private var showDeleteConfirmation = false
    // Message d'erreur
    @State private var errorMessage: String?
    @State private var showError = false
    
    var filteredReclamations: [Reclamation] {
        if searchText.isEmpty {
            return reclamationService.reclamations
        }
        return reclamationService.reclamations.filter { reclamation in
            (reclamation.userName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            reclamation.comment.localizedCaseInsensitiveContains(searchText) ||
            reclamation.type.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGray
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Liste des réclamations
                    if reclamationService.isLoading {
                        ProgressView("Chargement des réclamations...")
                            .padding()
                    } else if filteredReclamations.isEmpty {
                        emptyStateSection
                    } else {
                        reclamationsListSection
                    }
                }
                
                // Bouton flottant
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addButton
                            .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddReclamation) {
                NouvelleReclamationView(reclamationService: reclamationService)
            }
            .sheet(item: $reclamationToEdit) { reclamation in
                EditReclamationView(
                    reclamation: reclamation,
                    reclamationService: reclamationService
                )
                .environmentObject(authService)
            }
            .alert("Supprimer la réclamation", isPresented: $showDeleteConfirmation) {
                Button("Annuler", role: .cancel) {
                    reclamationToDelete = nil
                }
                Button("Supprimer", role: .destructive) {
                    if let reclamation = reclamationToDelete {
                        Task {
                            await deleteReclamation(reclamation)
                        }
                    }
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer cette réclamation ? Cette action est irréversible.")
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Une erreur est survenue")
            }
            .task {
                await reclamationService.loadReclamations()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Réclamations")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("Gérez vos demandes et avis")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
            
            // Barre de recherche
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("Rechercher...", text: $searchText)
                    .foregroundColor(.white)
                    .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .opacity(searchText.isEmpty ? 0 : 1)
                            .onTapGesture {
                                searchText = ""
                            },
                        alignment: .trailing
                    )
            }
            .padding()
            .background(AppColors.white.opacity(0.2))
            .cornerRadius(12)
        }
        .padding()
        .background(AppColors.primaryRed)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(AppColors.mediumGray)
            
            Text("Aucune réclamation")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.black)
            
            Text("Créez votre première réclamation pour partager votre avis")
                .font(.body)
                .foregroundColor(AppColors.mediumGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var reclamationsListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredReclamations) { reclamation in
                    ReclamationCard(
                        reclamation: reclamation,
                        onEdit: {
                            reclamationToEdit = reclamation
                        },
                        onDelete: {
                            reclamationToDelete = reclamation
                            showDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    /// Supprime une réclamation
    private func deleteReclamation(_ reclamation: Reclamation) async {
        do {
            try await reclamationService.deleteReclamation(reclamation.id)
            // Recharger la liste
            await reclamationService.loadReclamations()
            reclamationToDelete = nil
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la suppression: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private var addButton: some View {
        Button(action: {
            showingAddReclamation = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(AppColors.primaryRed)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

struct ReclamationCard: View {
    let reclamation: Reclamation
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(reclamation.type.color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: reclamation.type.icon)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reclamation.userName ?? "Utilisateur")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.black)
                        
                        Text(reclamation.type.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.mediumGray)
                    }
                }
                
                Spacer()
                
                // Statut
                if let status = reclamation.status {
                    Text(status.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status.color)
                        .cornerRadius(8)
                } else {
                    Text("En attente")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
            
            // Note
            HStack {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= reclamation.rating ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(star <= reclamation.rating ? AppColors.primaryRed : AppColors.lightGray)
                }
                
                Spacer()
                
                if let createdAt = reclamation.createdAt {
                    Text(createdAt, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mediumGray)
                } else if let date = reclamation.date {
                    Text(date)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mediumGray)
                }
            }
            
            // Commentaire
            if !reclamation.comment.isEmpty {
                Text(reclamation.comment)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.black)
                    .lineLimit(2)
            }
            
            // Boutons d'action
            HStack(spacing: 12) {
                Spacer()
                
                // Bouton Modifier
                Button(action: onEdit) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                        Text("Modifier")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.primaryRed)
                    .cornerRadius(8)
                }
                
                // Bouton Supprimer
                Button(action: onDelete) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                        Text("Supprimer")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(8)
                }
            }
            .padding(.top, 8)
        }
        .cardStyle()
    }
}

#Preview {
    ReclamationsView()
        .environmentObject(AuthService())
}
