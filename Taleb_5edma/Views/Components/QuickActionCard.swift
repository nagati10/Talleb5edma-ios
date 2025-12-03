//
//  QuickActionCard.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Carte d'action rapide avec icône colorée et titre
/// Utilisé dans la section Actions Rapides
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: (() -> Void)?
    
    init(
        title: String,
        icon: String,
        color: Color,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.black)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
        QuickActionCard(
            title: "Rechercher",
            icon: "magnifyingglass",
            color: AppColors.primaryRed
        )
        
        QuickActionCard(
            title: "Mes Candidatures",
            icon: "doc.text.fill",
            color: AppColors.primaryRed
        )
        
        QuickActionCard(
            title: "Emplois Sauvegardés",
            icon: "bookmark.fill",
            color: AppColors.successGreen
        )
        
        QuickActionCard(
            title: "Notifications",
            icon: "bell.fill",
            color: AppColors.accentPink
        )
    }
    .padding()
}

