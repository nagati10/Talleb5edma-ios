//
//  JobFilter.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation

/// Modèle représentant les filtres pour la recherche d'offres d'emploi
/// Utilisé dans FilterView pour gérer les critères de recherche
struct JobFilter {
    /// Texte de recherche pour filtrer par titre, entreprise ou localisation
    var searchText: String = ""
    
    /// Catégorie d'emploi sélectionnée
    var selectedCategory: JobCategory = .all
    
    /// Fourchette de salaire (min...max)
    var salaryRange: ClosedRange<Double> = 0...500
    
    /// Localisation pour filtrer les offres
    var location: String = ""
    
    /// Type d'horaire sélectionné
    var scheduleType: ScheduleType = .all
    
    /// Afficher uniquement les offres populaires
    var showPopularOnly: Bool = false
    
    /// Afficher uniquement les offres favorites
    var showFavoritesOnly: Bool = false
}

/// Enum représentant les types d'horaires de travail
enum ScheduleType: String, CaseIterable {
    case all = "Tous"
    case day = "Jour"
    case night = "Nuit"
    case flexible = "Flexible"
}

