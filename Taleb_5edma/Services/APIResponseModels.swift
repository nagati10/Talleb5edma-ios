//
//  APIResponseModels.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

// APIResponseModels.swift
import Foundation

// Modèles pour les réponses API spécifiques
struct UserResponse: Codable {
    // Données utilisateur éventuelles renvoyées par l'API
    let user: User?
    // Statut global de la réponse ("success" / "error")
    let status: String?
    // Message descriptif provenant du backend
    let message: String?
}

struct SimpleResponse: Codable {
    let status: String?
    let message: String?
    let data: User?
}

// Pour les réponses de mise à jour qui peuvent retourner différents formats
enum UpdateProfileResponse {
    case user(User)
    case message(String)
    case error(String)
}
