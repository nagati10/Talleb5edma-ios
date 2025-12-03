//
//  GradientButton.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import SwiftUI

// MARK: - GradientButton

/// Bouton personnalisé avec gradient rouge bordeaux horizontal
/// Utilise la palette de couleurs unifiée de Taleb 5edma
///
/// **Fonctionnalités:**
/// - Gradient horizontal rouge bordeaux (`AppColors.redGradientHorizontal`)
/// - Support d'un état de chargement avec `ProgressView`
/// - État désactivé avec fond gris
/// - Style cohérent avec le design de l'application
///
/// **Utilisation:**
/// ```swift
/// GradientButton(
///     title: "Se connecter",
///     action: { /* action */ },
///     isLoading: false,
///     isEnabled: true
/// )
/// ```
///
/// **Note:**
/// Utilisé dans les écrans d'authentification et les actions principales de l'application
struct GradientButton: View {
    // MARK: - Properties
    
    /// Titre du bouton affiché à l'utilisateur
    let title: String
    
    /// Action à exécuter quand le bouton est tapé
    let action: () -> Void
    
    /// Indique si le bouton est en état de chargement
    /// Si `true`, affiche un `ProgressView` au lieu du titre
    /// et désactive le bouton
    var isLoading: Bool = false
    
    /// Indique si le bouton est activé
    /// Si `false`, affiche un fond gris et désactive le clic
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                isEnabled ? AppColors.redGradientHorizontal : LinearGradient(
                    colors: [AppColors.mediumGray, AppColors.mediumGray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        GradientButton(title: "Login", action: {})
        GradientButton(title: "Loading...", action: {}, isLoading: true)
        GradientButton(title: "Disabled", action: {}, isEnabled: false)
    }
    .padding()
}

