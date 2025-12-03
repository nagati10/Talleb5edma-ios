//
//  ActionButton.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

// MARK: - ActionButton

/// Bouton d'action rapide avec icône et titre en dessous
/// Style compact et moderne cohérent avec la palette de couleurs de l'application
///
/// **Design:**
/// - Icône SF Symbols colorée en rouge bordeaux
/// - Fond rouge bordeaux transparent (opacity 0.1)
/// - Titre en dessous de l'icône avec typographie caption
/// - Taille fixe : 60x60 points
/// - Coins arrondis : 12 points
///
/// **Utilisation:**
/// ```swift
/// ActionButton(
///     title: "Filtre",
///     icon: "slider.horizontal.3",
///     action: { /* action */ }
/// )
/// ```
///
/// **Note:**
/// Utilisé pour les actions rapides dans le header des écrans (filtres, QR, etc.)
struct ActionButton: View {
    // MARK: - Properties
    
    /// Titre affiché sous l'icône
    let title: String
    
    /// Nom de l'icône SF Symbols à afficher
    let icon: String
    
    /// Action à exécuter quand le bouton est tapé
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColors.primaryRed)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.black)
            }
            .frame(width: 60, height: 60)
            .background(AppColors.primaryRed.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        ActionButton(title: "Filtre", icon: "slider.horizontal.3") {}
        ActionButton(title: "QR", icon: "qrcode.viewfinder") {}
        ActionButton(title: "Map", icon: "map") {}
        ActionButton(title: "AI-CV", icon: "doc.text.magnifyingglass") {}
    }
    .padding()
}

