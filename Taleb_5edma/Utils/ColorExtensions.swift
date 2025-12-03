//
//  ColorExtensions.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

// MARK: - Color Extensions

/// Extension de `Color` pour la compatibilité avec les anciennes références de code
/// **⚠️ IMPORTANT:** Utilisez `AppColors` pour toutes les nouvelles couleurs afin de maintenir
/// la cohérence de la palette de l'application.
///
/// Cette extension fournit des alias pour faciliter la migration progressive du code existant
/// vers l'utilisation de `AppColors`. Les nouvelles fonctionnalités devraient directement
/// utiliser `AppColors` plutôt que ces alias.
extension Color {
    // MARK: - Deprecated Aliases - Utilisez AppColors à la place
    
    /// ⚠️ Déprécié - Utilisez `AppColors.primaryRed` à la place
    /// Alias pour maintenir la compatibilité avec le code existant
    @available(*, deprecated, message: "Utilisez AppColors.primaryRed pour la cohérence")
    static let primaryRed = AppColors.primaryRed
    
    /// @deprecated Utilisez AppColors.backgroundGray
    static let backgroundGray = AppColors.backgroundGray
    
    /// @deprecated Utilisez AppColors.white
    // Note: Pas de alias pour éviter la référence circulaire avec AppColors.white = Color.white
    // Utilisez directement AppColors.white
    
    /// @deprecated Utilisez AppColors.black
    // Note: Pas de alias pour éviter la référence circulaire avec AppColors.black = Color.black
    // Utilisez directement AppColors.black
    
    /// @deprecated Utilisez AppColors.mediumGray
    static let mediumGray = AppColors.mediumGray
    
    /// @deprecated Utilisez AppColors.lightGray
    static let lightGray = AppColors.lightGray
    
    /// @deprecated Utilisez AppColors.accentBlue
    static let accentBlue = AppColors.accentBlue
    
    /// ⚠️ Déprécié - Utilisez `AppColors.accentBlue` à la place
    /// Alias pour maintenir la compatibilité avec le code existant
    @available(*, deprecated, message: "Utiliser AppColors.accentBlue pour la cohérence de la palette")
    static let accentPurple = AppColors.accentBlue
    
    /// @deprecated Utilisez AppColors.accentPink
    static let accentPink = AppColors.accentPink
    
    /// @deprecated Utilisez AppColors.successGreen
    static let successGreen = AppColors.successGreen
    
    // MARK: - Couleurs spécifiques (mode sombre)
    
    /// Background sombre pour les écrans de détail (#2A2A2A)
    static let darkBackground = Color(hex: 0x2A2A2A)
    
    /// Background pour les cartes en mode sombre (#333333)
    static let cardBackground = Color(hex: 0x333333)
    
    /// Texte principal en mode sombre (#ECECEC)
    static let textPrimary = Color(hex: 0xECECEC)
    
    /// Texte secondaire en mode sombre (#CCCCCC)
    static let textSecondary = Color(hex: 0xCCCCCC)
    
    /// Rouge pour les boutons (#DC2626) - Utilisez AppColors.lightRed
    static let redButton = AppColors.lightRed
    
    /// Rouge chat (#920000) - Utilisez AppColors.buttonRed
    static let chatRed = AppColors.buttonRed
    
    /// Rouge clair chat (#FF5151) - Utilisez AppColors.lighterRed
    static let chatLightRed = AppColors.lighterRed
    
    /// Gris chat (#A3A3A3) - Utilisez AppColors.mediumDarkGray
    static let chatGray = AppColors.mediumDarkGray
    
    // MARK: - Couleurs spécifiques pour comparaison
    
    /// Background sombre pour comparaison (#1F252A)
    static let customDarkBackground = Color(hex: 0x1F252A)
    
    /// Gradient start pour comparaison (#E3F2FD)
    static let customGradientStart = Color(hex: 0xE3F2FD)
    
    /// Gradient end pour comparaison (#BBDEFB)
    static let customGradientEnd = Color(hex: 0xBBDEFB)
    
    /// Accent rose personnalisé (#FF4081) - Utilisez AppColors.accentPink
    static let customPinkAccent = AppColors.accentPink
    
    /// Accent orange personnalisé (#FF6E40)
    static let customOrangeAccent = Color(hex: 0xFF6E40)
    
    /// Accent vert personnalisé (#4CAF50) - Utilisez AppColors.successGreen
    static let customGreenAccent = AppColors.successGreen
    
    /// Accent ambre personnalisé (#FFB300)
    static let customAmberAccent = Color(hex: 0xFFB300)
    
    /// Background gris personnalisé (#F5F5F5) - Utilisez AppColors.backgroundGray
    static let customGrayBackground = AppColors.backgroundGray
    
    /// Gris foncé personnalisé (#212121) - Utilisez AppColors.darkerGray
    static let customDarkGray = AppColors.darkerGray
    
    /// Texte primaire personnalisé (#424242) - Utilisez AppColors.darkGray
    static let customTextPrimary = AppColors.darkGray
    
    /// Texte secondaire personnalisé (#757575)
    static let customTextSecondary = Color(hex: 0x757575)
}
