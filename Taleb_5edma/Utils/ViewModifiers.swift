//
//  ViewModifiers.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

// MARK: - Card Style Modifier

/// Modificateur de vue pour appliquer un style de carte cohérent dans toute l'application
/// Crée une carte avec fond blanc, coins arrondis et ombre légère
/// Utilisé dans de nombreuses vues pour maintenir une apparence uniforme
///
/// **Utilisation:**
/// ```swift
/// VStack {
///     Text("Contenu")
/// }
/// .cardStyle()
/// ```
struct CardStyle: ViewModifier {
    /// Couleur de fond de la carte (par défaut: blanc)
    var backgroundColor: Color = AppColors.white
    
    /// Rayon des coins arrondis en points (par défaut: 12)
    var cornerRadius: CGFloat = 12
    
    /// Opacité de l'ombre de la carte (par défaut: 0.1 pour une ombre légère)
    var shadowOpacity: Double = 0.1
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(shadowOpacity), radius: 2, x: 0, y: 1)
    }
}

extension View {
    /// Applique un style de carte standard à la vue
    /// - Parameters:
    ///   - backgroundColor: Couleur de fond de la carte (défaut: `AppColors.white`)
    ///   - cornerRadius: Rayon des coins arrondis en points (défaut: 12)
    ///   - shadowOpacity: Opacité de l'ombre (défaut: 0.1)
    /// - Returns: La vue avec le style de carte appliqué
    /// - Note: Ajoute automatiquement du padding et une ombre pour un effet de profondeur
    func cardStyle(
        backgroundColor: Color = AppColors.white,
        cornerRadius: CGFloat = 12,
        shadowOpacity: Double = 0.1
    ) -> some View {
        modifier(CardStyle(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            shadowOpacity: shadowOpacity
        ))
    }
}

// MARK: - Primary Button Style

/// Style de bouton principal avec gradient rouge bordeaux horizontal
/// Utilisé pour les actions principales dans l'application (connexion, soumission, etc.)
/// Affiche un indicateur de chargement lorsque `isLoading` est `true`
struct PrimaryButtonStyle: ButtonStyle {
    /// Indicateur de chargement - affiche un ProgressView si `true`
    var isLoading: Bool = false
    
    /// Indique si le bouton est activé - désactivé = fond gris
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                configuration.label
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            isEnabled
                ? AppColors.redGradientHorizontal
                : LinearGradient(
                    colors: [AppColors.mediumGray, AppColors.mediumGray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
        )
        .foregroundColor(.white)
        .fontWeight(.bold)
        .cornerRadius(12)
        .opacity(configuration.isPressed ? 0.8 : 1.0)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Secondary Button Style

/// Style de bouton secondaire avec bordure colorée
/// Utilisé pour les actions secondaires ou les boutons de navigation
/// Style plus subtil que le bouton primaire, avec fond transparent et bordure
struct SecondaryButtonStyle: ButtonStyle {
    /// Couleur de la bordure et du texte (défaut: rouge bordeaux)
    var color: Color = AppColors.primaryRed
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(color)
            .background(color.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Search Bar Style

/// Modificateur pour créer un style uniforme pour les barres de recherche
/// Applique un fond blanc, des coins arrondis et une ombre légère
/// Utilisé dans `OffersView`, `FavoritesView` et autres vues avec recherche
struct SearchBarStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppColors.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

extension View {
    /// Applique le style de barre de recherche standard
    /// - Returns: La vue avec le style de recherche appliqué
    /// - Note: Utilise la palette AppColors pour maintenir la cohérence visuelle
    func searchBarStyle() -> some View {
        modifier(SearchBarStyle())
    }
}

// MARK: - Section Header Style

/// Modificateur pour les en-têtes de section dans les listes et formulaires
/// Applique une typographie en gras avec une couleur personnalisable
/// Utilisé pour organiser visuellement le contenu en sections distinctes
struct SectionHeaderStyle: ViewModifier {
    /// Couleur du texte de l'en-tête (défaut: rouge bordeaux)
    var color: Color = AppColors.primaryRed
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal)
            .padding(.vertical, 16)
    }
}

extension View {
    /// Applique le style d'en-tête de section standard
    /// - Parameter color: Couleur du texte (défaut: `AppColors.primaryRed`)
    /// - Returns: La vue avec le style d'en-tête appliqué
    /// - Note: Utilisé dans les formulaires multi-sections pour améliorer la lisibilité
    func sectionHeaderStyle(color: Color = AppColors.primaryRed) -> some View {
        modifier(SectionHeaderStyle(color: color))
    }
}

