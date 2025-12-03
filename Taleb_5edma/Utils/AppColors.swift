//
//  AppColors.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import SwiftUI

// MARK: - AppColors

/// Palette de couleurs unifiée et centralisée pour toute l'application Taleb 5edma
///
/// Cette structure définit toutes les couleurs utilisées dans l'application pour garantir
/// une cohérence visuelle et faciliter les modifications globales de design.
///
/// **Palette principale:**
/// - Rouge bordeaux foncé (#5A0E24, #76153C, #BF124D)
/// - Bleu clair accent (#67B2D8)
/// - Gris avec ses dégradés (#F5F5F5 à #212121)
///
/// **Utilisation:**
/// ```swift
/// Text("Hello")
///     .foregroundColor(AppColors.primaryRed)
///     .background(AppColors.backgroundGray)
/// ```
///
/// **Avantages:**
/// - Cohérence visuelle dans toute l'application
/// - Modification centralisée de la palette
/// - Facilite le support du dark mode (futur)
struct AppColors {
    // MARK: - Primary Colors (Rouge Bordeaux)
    
    /// Rouge bordeaux principal (#BF124D)
    static let primaryRed = Color(hex: 0xBF124D)
    
    /// Rouge bordeaux foncé pour les backgrounds (#76153C)
    static let darkRed = Color(hex: 0x76153C)
    
    /// Rouge bordeaux très foncé (#5A0E24)
    static let darkerRed = Color(hex: 0x5A0E24)
    
    /// Rouge bordeaux clair (#BF124D) - même que primaryRed
    static let lightRed = Color(hex: 0xBF124D)
    
    /// Rouge bordeaux très clair (dérivé de #BF124D avec plus de luminosité)
    static let lighterRed = Color(hex: 0xFF4081)
    
    /// Rouge bordeaux pour les boutons (#76153C)
    static let buttonRed = Color(hex: 0x76153C)
    
    // MARK: - Neutral Colors (Gris avec dégradés)
    
    /// Blanc pour les backgrounds de contenu
    static let white = Color.white
    
    /// Noir pour le texte principal
    static let black = Color.black
    
    /// Gris très clair pour les backgrounds (#F5F5F5)
    static let backgroundGray = Color(hex: 0xF5F5F5)
    
    /// Gris clair pour les bordures (#CCCCCC)
    static let lightGray = Color(hex: 0xCCCCCC)
    
    /// Gris moyen pour le texte secondaire (#666666)
    static let mediumGray = Color(hex: 0x666666)
    
    /// Gris moyen-foncé (#A3A3A3)
    static let mediumDarkGray = Color(hex: 0xA3A3A3)
    
    /// Gris foncé pour le texte (#424242)
    static let darkGray = Color(hex: 0x424242)
    
    /// Gris très foncé (#212121)
    static let darkerGray = Color(hex: 0x212121)
    
    /// Gris pour les séparateurs (#E0E0E0)
    static let separatorGray = Color(hex: 0xE0E0E0)
    
    // MARK: - Accent Colors (Couleurs d'accent)
    
    /// Bleu clair utilisé pour les boutons et liens (#67B2D8)
    static let accentBlue = Color(hex: 0x67B2D8)
    
    /// Violet/bleu utilisé pour les boutons et liens (#6B46C1)
    /// Note: Déprécié - utiliser `accentBlue` pour maintenir la palette unifiée
    @available(*, deprecated, message: "Utiliser AppColors.accentBlue pour la cohérence de la palette")
    static let accentPurple = Color(hex: 0x6B46C1)
    
    /// Rose/violet utilisé dans les gradients avec le rouge bordeaux (#FF4081)
    /// Crée des dégradés harmonieux avec `primaryRed` pour les headers et boutons
    static let accentPink = Color(hex: 0xFF4081)
    
    // MARK: - Semantic Colors (Couleurs sémantiques)
    
    /// Vert pour les indicateurs de succès (#4CAF50)
    static let successGreen = Color(hex: 0x4CAF50)
    
    /// Rouge pour les erreurs (#BF124D)
    static let errorRed = Color(hex: 0xBF124D)
    
    // MARK: - Background Colors
    
    /// Background pour les cellules de liste
    static let cellBackground = Color.white
    
    // MARK: - Gradients (Rouge Bordeaux)
    
    /// Gradient rouge bordeaux principal (foncé -> clair)
    static var redGradient: LinearGradient {
        LinearGradient(
            colors: [darkerRed, darkRed, primaryRed],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Gradient rouge bordeaux vertical (pour headers)
    static var redGradientVertical: LinearGradient {
        LinearGradient(
            colors: [darkerRed, darkRed, primaryRed],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Gradient rouge bordeaux horizontal (pour boutons)
    static var redGradientHorizontal: LinearGradient {
        LinearGradient(
            colors: [darkerRed, darkRed, primaryRed],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Gradients (Gris)
    
    /// Gradient gris pour les backgrounds
    static var grayGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xFAFAFA), backgroundGray, lightGray],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Gradient gris horizontal
    static var grayGradientHorizontal: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xFAFAFA), backgroundGray],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    /// Gradient gris foncé (pour modes sombres)
    static var darkGrayGradient: LinearGradient {
        LinearGradient(
            colors: [darkerGray, darkGray, mediumGray],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Gradients (Accent)
    
    /// Gradient bleu-rose pour les boutons d'action
    static var purpleGradient: LinearGradient {
        LinearGradient(
            colors: [accentBlue, accentPink],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    /// Gradient rouge-bleu (mix)
    static var redPurpleGradient: LinearGradient {
        LinearGradient(
            colors: [primaryRed, accentBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    /// Gradient rouge-bleu (nouvelle palette)
    static var redBlueGradient: LinearGradient {
        LinearGradient(
            colors: [primaryRed, accentBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Color Extension Helper
extension Color {
    init(hex: UInt64, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        
        if alpha == 1.0 {
            self.init(red: red, green: green, blue: blue)
        } else {
            self.init(
                .sRGB,
                red: red,
                green: green,
                blue: blue,
                opacity: alpha
            )
        }
    }
}

