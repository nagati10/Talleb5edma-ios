//
//  QuickOffersMenu.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import SwiftUI

/// Structure représentant une catégorie d'offre avec son icône
struct OfferCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let category: JobCategory
}

/// Menu rapide avec des icônes d'offres par catégorie
/// Inspiré du design de l'écran "Activity"
struct QuickOffersMenu: View {
    let categories: [OfferCategory]
    let onCategorySelected: (JobCategory) -> Void
    
    init(onCategorySelected: @escaping (JobCategory) -> Void) {
        self.onCategorySelected = onCategorySelected
        
        // Catégories d'offres avec leurs icônes
        self.categories = [
            OfferCategory(
                name: "BTP",
                icon: "hammer.fill",
                color: AppColors.primaryRed,
                category: .construction
            ),
            OfferCategory(
                name: "Informatique",
                icon: "laptopcomputer",
                color: AppColors.accentBlue,
                category: .tech
            ),
            OfferCategory(
                name: "Marketing",
                icon: "megaphone.fill",
                color: AppColors.primaryRed,
                category: .marketing
            ),
            OfferCategory(
                name: "Restauration",
                icon: "fork.knife",
                color: AppColors.accentBlue,
                category: .restaurant
            ),
            OfferCategory(
                name: "Livraison",
                icon: "bicycle",
                color: AppColors.primaryRed,
                category: .delivery
            ),
            OfferCategory(
                name: "Vente",
                icon: "bag.fill",
                color: AppColors.accentBlue,
                category: .retail
            )
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Catégories d'offres")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.darkerGray)
                
                Spacer()
                
                Button("Voir tout") {
                    onCategorySelected(.all)
                }
                .font(.subheadline)
                .foregroundColor(AppColors.primaryRed)
            }
            
            // Grille d'icônes
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(categories) { category in
                    OfferCategoryCard(category: category) {
                        onCategorySelected(category.category)
                    }
                }
            }
        }
    }
}

/// Carte individuelle pour une catégorie d'offre
struct OfferCategoryCard: View {
    let category: OfferCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icône dans un cercle
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(category.color)
                }
                
                // Nom de la catégorie
                Text(category.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.darkerGray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        category.color.opacity(0.1),
                        category.color.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    QuickOffersMenu { category in
        print("Catégorie sélectionnée: \(category)")
    }
    .padding()
    .background(AppColors.backgroundGray)
}

