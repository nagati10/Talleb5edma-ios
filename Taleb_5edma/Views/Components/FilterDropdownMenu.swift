//
//  FilterDropdownMenu.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

// MARK: - FilterDropdownMenu

/// Menu déroulant (dropdown) affichant les options de filtrage et de recherche avancée
/// Accessible depuis le bouton "Filtre" dans `OffersView`
///
/// **Options disponibles:**
/// - **Filtres avancés** : Ouvre `FilterView` pour affiner la recherche par critères multiples
/// - **QR** : Ouvre `QRGeneratorView` pour générer des codes QR à partir d'images
/// - **Map** : Ouvre `JobsMapView` pour visualiser les offres sur une carte interactive
/// - **AI-CV** : Ouvre `AICVAnalysisView` pour analyser un CV avec l'intelligence artificielle
///
/// **Design:**
/// - Bouton avec icône de slider et fond rouge bordeaux transparent
/// - Menu natif iOS avec séparateurs entre les sections
/// - Fermeture automatique après sélection d'une option
///
/// **Utilisation:**
/// Utilisé dans `OffersView` pour regrouper toutes les fonctionnalités de filtrage et recherche
struct FilterDropdownMenu: View {
    // MARK: - Properties
    
    /// Binding pour contrôler l'état d'expansion du menu
    /// Utilisé pour fermer le menu après sélection d'une option
    @Binding var isExpanded: Bool
    
    /// Callback appelé quand "Filtres avancés" est sélectionné
    /// Ouvre généralement `FilterView` depuis la vue parente
    let onAdvancedFiltersSelected: () -> Void
    
    /// Callback appelé quand "QR" est sélectionné
    /// Ouvre généralement `QRGeneratorView` depuis la vue parente
    let onQRSelected: () -> Void
    
    /// Callback appelé quand "Map" est sélectionné
    /// Ouvre généralement `JobsMapView` depuis la vue parente
    let onMapSelected: () -> Void
    
    /// Callback appelé quand "AI-CV" est sélectionné
    /// Ouvre généralement `AICVAnalysisView` depuis la vue parente
    let onAICVSelected: () -> Void
    
    var body: some View {
        Menu {
            Button(action: {
                isExpanded = false
                onAdvancedFiltersSelected()
            }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("Filtres avancés")
                }
            }
            
            Divider()
            
            Button(action: {
                isExpanded = false
                onQRSelected()
            }) {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                    Text("QR")
                }
            }
            
            Button(action: {
                isExpanded = false
                onMapSelected()
            }) {
                HStack {
                    Image(systemName: "map")
                    Text("Map")
                }
            }
            
            Button(action: {
                isExpanded = false
                onAICVSelected()
            }) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("AI-CV")
                }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundColor(AppColors.primaryRed)
                
                Text("Filtre")
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
    HStack {
        FilterDropdownMenu(
            isExpanded: .constant(false),
            onAdvancedFiltersSelected: { print("Filtres avancés sélectionné") },
            onQRSelected: { print("QR sélectionné") },
            onMapSelected: { print("Map sélectionné") },
            onAICVSelected: { print("AI-CV sélectionné") }
        )
    }
    .padding()
}

