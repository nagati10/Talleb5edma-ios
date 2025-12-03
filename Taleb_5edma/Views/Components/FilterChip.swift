//
//  FilterChip.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Chip de filtre réutilisable avec état sélectionné
/// Utilise la palette de couleurs rouge bordeaux
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppColors.primaryRed)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primaryRed : AppColors.primaryRed.opacity(0.1))
                .cornerRadius(16)
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        FilterChip(title: "Tous", isSelected: true) {}
        FilterChip(title: "Informatique", isSelected: false) {}
        FilterChip(title: "Construction", isSelected: false) {}
    }
    .padding()
}

