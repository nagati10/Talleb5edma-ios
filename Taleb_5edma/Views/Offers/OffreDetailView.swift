//
//  OffreDetailView.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import SwiftUI

/// Vue de détail d'une offre d'emploi
/// Affiche toutes les informations d'une offre et permet les actions (like, postuler, etc.)
struct OffreDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    let offre: Offre
    @ObservedObject var viewModel: OffreViewModel
    
    @State private var isLiked = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section avec dégradé
                OffreHeaderSection(offre: offre, isLiked: $isLiked, onBack: { dismiss() }, onLike: {
                    Task {
                        let success = await viewModel.likeOffre(offre.id)
                        if success {
                            // Mettre à jour l'état local basé sur le likeCount mis à jour
                            if let updatedOffre = viewModel.offres.first(where: { $0.id == offre.id }) {
                                isLiked = (updatedOffre.likeCount ?? 0) > (offre.likeCount ?? 0)
                            }
                        }
                    }
                })
                
                // Content Section
                ScrollView {
                    VStack(spacing: 24) {
                        OffreDetailsSection(offre: offre)
                        OffreDescriptionSection(offre: offre)
                        if let exigences = offre.exigences, !exigences.isEmpty {
                            OffrePrerequisitesSection(exigences: exigences)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
            }
            
            // Bottom Action Buttons
            OffreBottomActionButtons(offre: offre)
                .environmentObject(authService)
                .padding(.horizontal)
                .padding(.bottom, 16)
                .background(AppColors.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Vérifier si l'offre est aimée (basé sur likeCount)
            isLiked = (offre.likeCount ?? 0) > 0
        }
    }
}

// MARK: - Header Section

struct OffreHeaderSection: View {
    let offre: Offre
    @Binding var isLiked: Bool
    let onBack: () -> Void
    let onLike: () -> Void
    
    var body: some View {
        ZStack {
            // Dégradé rouge-rose
            LinearGradient(
                gradient: Gradient(colors: [AppColors.primaryRed, AppColors.accentPink]),
                startPoint: .leading,
                endPoint: .trailing
            )
            
            VStack(spacing: 0) {
                // Navigation en haut
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Détails de l'offre")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: onLike) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { /* Partager */ }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Contenu principal avec icône, titre et tags
                HStack(alignment: .top, spacing: 16) {
                    // Icône carrée blanche
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(AppColors.primaryRed)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Titre
                        Text(offre.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        // Entreprise
                        Text(offre.company)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                        
                        // Tags
                        HStack(spacing: 8) {
                            if let salary = offre.salary {
                                OffreTag(text: salary)
                            }
                            if let jobType = offre.jobType {
                                OffreTag(text: jobType)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .frame(height: 240)
    }
}

struct OffreTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.primaryRed.opacity(0.8))
            .cornerRadius(12)
    }
}

// MARK: - Offre Details Section

struct OffreDetailsSection: View {
    let offre: Offre
    
    var body: some View {
        GenericCard {
            VStack(spacing: 16) {
                // Première ligne
                HStack(spacing: 20) {
                    OffreDetailRow(
                        icon: "location.fill",
                        label: "Localisation",
                        value: offre.location.address
                    )
                    
                    if let city = offre.location.city {
                        OffreDetailRow(
                            icon: "map.fill",
                            label: "Ville",
                            value: city
                        )
                    }
                }
                
                Divider()
                    .background(AppColors.separatorGray)
                
                // Deuxième ligne
                HStack(spacing: 20) {
                    if let salary = offre.salary {
                        OffreDetailRow(
                            icon: "briefcase.fill",
                            label: "Salaire",
                            value: salary
                        )
                    }
                    
                    if let expiresAt = offre.expiresAt {
                        OffreDetailRow(
                            icon: "calendar",
                            label: "Expire le",
                            value: formatDate(expiresAt)
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
}

struct OffreDetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primaryRed)
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mediumGray)
            }
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Offre Description Section

struct OffreDescriptionSection: View {
    let offre: Offre
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description du poste")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.black)
            
            Text(offre.description)
                .font(.system(size: 14))
                .foregroundColor(AppColors.black)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Prerequisites Section

struct OffrePrerequisitesSection: View {
    let exigences: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prérequis")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.black)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(exigences, id: \.self) { exigence in
                    OffrePrerequisiteItem(text: exigence)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct OffrePrerequisiteItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppColors.primaryRed)
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(AppColors.black)
        }
    }
}

// MARK: - Bottom Action Buttons

struct OffreBottomActionButtons: View {
    let offre: Offre
    @EnvironmentObject var authService: AuthService
    @State private var showingMoreInfo = false
    @State private var showingApply = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { showingMoreInfo = true }) {
                Text("Plus d'infos")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryRed)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.primaryRed, lineWidth: 2)
                    )
                    .cornerRadius(12)
            }
            .sheet(isPresented: $showingMoreInfo) {
                // Plus d'informations
                Text("Plus d'informations")
            }
            
            Button(action: { showingApply = true }) {
                Text("Postuler")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.primaryRed, AppColors.accentPink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .sheet(isPresented: $showingApply) {
                ChatView(offre: offre)
                    .environmentObject(authService)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    OffreDetailView(
        offre: Offre(
            id: "1",
            title: "Développeur Web Junior",
            description: "Nous recherchons un développeur web junior passionné pour rejoindre notre équipe dynamique.",
            tags: ["CDI", "Télétravail"],
            exigences: ["JavaScript", "React", "HTML/CSS"],
            location: OffreLocation(
                address: "123 Rue de la République",
                city: "Tunis",
                country: "Tunisie",
                coordinates: Coordinates(lat: 36.8065, lng: 10.1815)
            ),
            category: "Informatique",
            salary: "500-800 DT/mois",
            company: "TechCorp",
            expiresAt: "2025-12-31",
            jobType: "job",
            shift: "jour",
            isActive: true,
            images: nil,
            viewCount: 10,
            likeCount: 5,
            userId: nil,
            createdAt: nil,
            updatedAt: nil
        ),
        viewModel: OffreViewModel()
    )
}

