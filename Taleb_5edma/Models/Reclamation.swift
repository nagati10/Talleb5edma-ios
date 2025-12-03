//
//  Reclamation.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

//
//  Reclamation.swift
//  Taleb_5edma
//

import Foundation
import SwiftUI

struct Reclamation: Identifiable, Codable {
    // Identifiant unique de la réclamation côté API
    let id: String
    // Référence de l'utilisateur ayant soumis la réclamation
    let userId: String
    let userName: String?
    // Catégorie choisie par l'utilisateur
    let type: ReclamationType
    // Texte de la réclamation (correspond à "text" dans le backend)
    let text: String
    // Date de la réclamation
    let date: String?
    // État de traitement de la réclamation
    let status: ReclamationStatus?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case userName
        case type
        case text
        case date
        case status
        case createdAt
        case updatedAt
    }
    
    /// Initializer public pour créer une réclamation manuellement
    init(
        id: String,
        userId: String,
        userName: String? = nil,
        type: ReclamationType,
        text: String,
        date: String? = nil,
        status: ReclamationStatus? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.type = type
        self.text = text
        self.date = date
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        userName = try container.decodeIfPresent(String.self, forKey: .userName)
        
        // Décoder le type depuis le format backend
        let typeString = try container.decode(String.self, forKey: .type)
        type = ReclamationType.fromBackendValue(typeString)
        
        text = try container.decode(String.self, forKey: .text)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        
        // Décoder le statut depuis le format backend
        if let statusString = try? container.decode(String.self, forKey: .status) {
            status = ReclamationStatus.fromBackendValue(statusString)
        } else {
            status = nil
        }
        
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encode(type.toBackendValue(), forKey: .type)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(date, forKey: .date)
        if let status = status {
            try container.encode(status.toBackendValue(), forKey: .status)
        }
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    // Propriétés calculées pour compatibilité avec l'UI existante
    var comment: String {
        return text
    }
    
    var rating: Int {
        // Par défaut, pas de rating dans le backend
        return 0
    }
}

enum ReclamationType: String, Codable, CaseIterable {
    case technique = "Technique"
    case service = "Service"
    case facturation = "Facturation"
    case autre = "Autre"
    
    /// Convertit la valeur Swift vers le format backend (lowercase)
    func toBackendValue() -> String {
        switch self {
        case .technique: return "technique"
        case .service: return "service"
        case .facturation: return "facturation"
        case .autre: return "autre"
        }
    }
    
    /// Convertit la valeur backend vers l'enum Swift
    static func fromBackendValue(_ value: String) -> ReclamationType {
        switch value.lowercased() {
        case "technique": return .technique
        case "service": return .service
        case "facturation": return .facturation
        case "autre": return .autre
        default: return .autre
        }
    }
    
    var icon: String {
        // Icône SF Symbols associée à chaque type pour l'interface
        switch self {
        case .technique: return "wrench.and.screwdriver"
        case .service: return "person.2.fill"
        case .facturation: return "creditcard.fill"
        case .autre: return "doc.text"
        }
    }
    
    var description: String {
        switch self {
        case .technique: return "Problème technique"
        case .service: return "Problème de service"
        case .facturation: return "Problème de facturation"
        case .autre: return "Autre réclamation"
        }
    }
    
    var color: Color {
        switch self {
        case .technique: return .blue
        case .service: return .green
        case .facturation: return .orange
        case .autre: return .red
        }
    }
}

enum ReclamationStatus: String, Codable {
    case pending = "En attente"
    case inProgress = "En cours"
    case resolved = "Résolue"
    case rejected = "Rejetée"
    
    /// Convertit la valeur Swift vers le format backend (lowercase, snake_case)
    func toBackendValue() -> String {
        switch self {
        case .pending: return "pending"
        case .inProgress: return "in_progress"
        case .resolved: return "resolved"
        case .rejected: return "rejected"
        }
    }
    
    /// Convertit la valeur backend vers l'enum Swift
    static func fromBackendValue(_ value: String) -> ReclamationStatus {
        switch value.lowercased() {
        case "pending", "en_attente", "en attente": return .pending
        case "in_progress", "en cours": return .inProgress
        case "resolved", "résolue": return .resolved
        case "rejected", "rejetée": return .rejected
        default: return .pending
        }
    }
    
    var color: Color {
        // Code couleur permettant de distinguer visuellement le statut
        switch self {
        case .pending: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        case .rejected: return .red
        }
    }
}

// MARK: - Request Models

/// Modèle de requête pour créer une nouvelle réclamation
/// Correspond au CreateReclamationDto du backend
struct CreateReclamationRequest: Codable {
    let type: String
    let text: String
    let date: String?
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case date
        case userId
    }
    
    /// Initialise la requête à partir des valeurs Swift
    init(type: ReclamationType, text: String, date: String? = nil, userId: String? = nil) {
        self.type = type.toBackendValue()
        self.text = text
        self.date = date
        self.userId = userId
    }
}

/// Modèle de requête pour mettre à jour une réclamation
/// Correspond au UpdateReclamationDto du backend
struct UpdateReclamationRequest: Codable {
    let type: String?
    let text: String?
    let date: String?
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case date
        case userId
    }
    
    /// Initialise la requête de mise à jour
    init(type: ReclamationType? = nil, text: String? = nil, date: String? = nil, userId: String? = nil) {
        self.type = type?.toBackendValue()
        self.text = text
        self.date = date
        self.userId = userId
    }
}

/// Modèle de requête pour mettre à jour le statut d'une réclamation
struct UpdateReclamationStatusRequest: Codable {
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case status
    }
    
    init(status: ReclamationStatus) {
        self.status = status.toBackendValue()
    }
}

// MARK: - Statistics Models

/// Modèle de réponse pour les statistiques par type
struct ReclamationTypeStats: Codable {
    let type: String
    let count: Int
}

/// Modèle de réponse pour les statistiques par statut
struct ReclamationStatusStats: Codable {
    let status: String
    let count: Int
}
