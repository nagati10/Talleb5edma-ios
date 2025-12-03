//
//  ViewExtensions.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

// MARK: - Corner Radius Extension

/// Extension de `View` pour arrondir sélectivement certains coins d'une vue
/// Utile pour créer des effets visuels sophistiqués (ex: cardes avec coins arrondis uniquement en haut)
///
/// **Utilisation:**
/// ```swift
/// Rectangle()
///     .cornerRadius(12, corners: [.topLeft, .topRight])
/// ```
///
/// **Exemple pratique:**
/// Créer une carte avec coins arrondis uniquement en haut pour un header
extension View {
    /// Arrondit des coins spécifiques d'une vue avec un rayon personnalisable
    /// - Parameters:
    ///   - radius: Le rayon de l'arrondi en points (par défaut: `.infinity` pour un cercle complet)
    ///   - corners: Les coins à arrondir parmi `.topLeft`, `.topRight`, `.bottomLeft`, `.bottomRight`, `.allCorners`
    /// - Returns: La vue avec les coins spécifiés arrondis
    /// - Note: Utilise `RoundedCorner` en interne pour créer la forme personnalisée
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - RoundedCorner Shape

/// Forme personnalisée pour arrondir sélectivement certains coins d'un rectangle
/// Utilisée par l'extension `cornerRadius(_:corners:)` pour créer des coins arrondis partiels
struct RoundedCorner: Shape {
    /// Rayon de l'arrondi en points
    /// `.infinity` crée un coin parfaitement circulaire (utile pour les badges)
    var radius: CGFloat = .infinity
    
    /// Les coins à arrondir parmi les options disponibles
    /// Par défaut: tous les coins sont arrondis (comportement standard)
    var corners: UIRectCorner = .allCorners

    /// Crée le chemin de la forme avec les coins spécifiés arrondis
    /// - Parameter rect: Le rectangle dans lequel dessiner la forme
    /// - Returns: Le chemin de la forme avec les coins arrondis
    func path(in rect: CGRect) -> Path {
        // Utiliser UIBezierPath pour créer facilement des coins arrondis sélectifs
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

