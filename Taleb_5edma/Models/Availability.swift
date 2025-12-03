//
//  Availability.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation

/// Modèle représentant une disponibilité d'un utilisateur
/// Correspond aux DTOs du backend (CreateDisponibiliteDto, UpdateDisponibiliteDto)
struct Disponibilite: Codable, Identifiable {
    let id: String
    let jour: String  // "Lundi", "Mardi", etc.
    let heureDebut: String  // Format: "09:00"
    let heureFin: String?  // Format: "17:00"
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case jour
        case heureDebut
        case heureFin
        case createdAt
        case updatedAt
    }
}

/// DTO pour créer une nouvelle disponibilité
/// Correspond au CreateDisponibiliteDto du backend
struct CreateDisponibiliteRequest: Codable {
    let jour: String
    let heureDebut: String
    let heureFin: String?
    
    init(jour: String, heureDebut: String, heureFin: String? = nil) {
        self.jour = jour
        self.heureDebut = heureDebut
        self.heureFin = heureFin
    }
    
    /// Encodage personnalisé pour exclure les champs nil du JSON
    /// 
    /// PROBLÈME RÉSOLU : Pour les disponibilités "toute la journée", heureFin est nil.
    /// Le backend peut rejeter les requêtes contenant des champs null.
    /// Cette méthode garantit que heureFin n'est envoyé que s'il a une valeur.
    ///
    /// MODIFICATION : Implémentation d'un encode() personnalisé qui n'encode heureFin
    /// que s'il n'est pas nil, permettant de créer des disponibilités sans heure de fin.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jour, forKey: .jour)
        try container.encode(heureDebut, forKey: .heureDebut)
        
        // N'encoder heureFin que s'il n'est pas nil
        // Cela permet de créer des disponibilités "toute la journée" sans heure de fin
        if let heureFin = heureFin {
            try container.encode(heureFin, forKey: .heureFin)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case jour
        case heureDebut
        case heureFin
    }
}

/// DTO pour mettre à jour une disponibilité
/// Correspond au UpdateDisponibiliteDto du backend
struct UpdateDisponibiliteRequest: Codable {
    let jour: String?
    let heureDebut: String?
    let heureFin: String?
    
    init(jour: String? = nil, heureDebut: String? = nil, heureFin: String? = nil) {
        self.jour = jour
        self.heureDebut = heureDebut
        self.heureFin = heureFin
    }
    
    /// Encodage personnalisé pour exclure les champs nil du JSON lors des mises à jour
    /// 
    /// PROBLÈME RÉSOLU : Lors des mises à jour partielles (PATCH), envoyer des champs null
    /// peut causer des erreurs côté backend. Cette méthode garantit qu'on n'envoie que les champs modifiés.
    ///
    /// MODIFICATION : Implémentation d'un encode() personnalisé pour UpdateDisponibiliteRequest
    /// qui n'encode que les champs présents, permettant des mises à jour partielles propres.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // N'encoder que les champs qui ne sont pas nil
        // Pour les requêtes PATCH, cela permet de ne modifier que les champs spécifiés
        if let jour = jour {
            try container.encode(jour, forKey: .jour)
        }
        if let heureDebut = heureDebut {
            try container.encode(heureDebut, forKey: .heureDebut)
        }
        if let heureFin = heureFin {
            try container.encode(heureFin, forKey: .heureFin)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case jour
        case heureDebut
        case heureFin
    }
}
