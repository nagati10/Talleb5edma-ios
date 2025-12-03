//
//  JobCategory.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation

/// Enum représentant les catégories d'offres d'emploi disponibles
/// Utilisé pour le filtrage et la catégorisation des offres
enum JobCategory: String, CaseIterable {
    case all = "Tous"
    case construction = "BTP"
    case tech = "Informatique"
    case marketing = "Marketing"
    case restaurant = "Restauration"
    case delivery = "Livraison"
    case retail = "Vente"
}

