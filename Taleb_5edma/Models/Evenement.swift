//
//  Evenement.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation

/// Modèle représentant un événement dans le calendrier
/// Correspond aux DTOs du backend (CreateEvenementDto, UpdateEvenementDto)
struct Evenement: Codable, Identifiable {
    let id: String
    let titre: String
    let type: String  // "cours", "job", "deadline"
    let date: String  // Format: "2024-01-15" (normalisé depuis ISO)
    let heureDebut: String  // Format: "09:00"
    let heureFin: String  // Format: "10:30"
    let lieu: String?
    let tarifHoraire: Double?
    let couleur: String?  // Format hex: "#FF5733"
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case titre
        case type
        case date
        case heureDebut
        case heureFin
        case lieu
        case tarifHoraire
        case couleur
        case createdAt
        case updatedAt
    }
    
    /// Décodage personnalisé pour normaliser le format de date
    /// 
    /// PROBLÈME RÉSOLU : Le backend renvoie les dates au format ISO complet ("2025-11-14T00:00:00.000Z")
    /// mais la comparaison dans getEvenementsForDate() utilise le format "yyyy-MM-dd" ("2025-11-14").
    /// Cette normalisation garantit que les dates sont toujours au format "yyyy-MM-dd" pour une comparaison cohérente.
    ///
    /// MODIFICATION : Ajout de la logique de normalisation pour extraire uniquement la partie date
    /// si le format reçu est ISO, sinon on garde le format tel quel.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        titre = try container.decode(String.self, forKey: .titre)
        type = try container.decode(String.self, forKey: .type)
        
        // Normaliser la date : extraire seulement la partie date (yyyy-MM-dd) si c'est une date ISO
        // Cette normalisation résout le problème où les événements créés n'apparaissaient pas dans le calendrier
        // car la comparaison de dates échouait à cause du format différent (ISO vs yyyy-MM-dd)
        let dateString = try container.decode(String.self, forKey: .date)
        if dateString.contains("T") {
            // Format ISO : "2025-11-14T00:00:00.000Z" -> "2025-11-14"
            date = String(dateString.prefix(10))
        } else {
            date = dateString
        }
        
        heureDebut = try container.decode(String.self, forKey: .heureDebut)
        heureFin = try container.decode(String.self, forKey: .heureFin)
        lieu = try container.decodeIfPresent(String.self, forKey: .lieu)
        tarifHoraire = try container.decodeIfPresent(Double.self, forKey: .tarifHoraire)
        couleur = try container.decodeIfPresent(String.self, forKey: .couleur)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

/// DTO pour créer un nouvel événement
/// Correspond au CreateEvenementDto du backend
struct CreateEvenementRequest: Codable {
    let titre: String
    let type: String
    let date: String
    let heureDebut: String
    let heureFin: String
    let lieu: String?
    let tarifHoraire: Double?
    let couleur: String?
    
    init(titre: String, type: String, date: String, heureDebut: String, heureFin: String, lieu: String? = nil, tarifHoraire: Double? = nil, couleur: String? = nil) {
        self.titre = titre
        self.type = type
        self.date = date
        self.heureDebut = heureDebut
        self.heureFin = heureFin
        self.lieu = lieu
        self.tarifHoraire = tarifHoraire
        self.couleur = couleur
    }
    
    /// Encodage personnalisé pour exclure les champs nil du JSON
    /// 
    /// PROBLÈME RÉSOLU : Le backend peut rejeter les requêtes contenant des champs null.
    /// Cette méthode garantit que seuls les champs non-nil sont envoyés dans la requête.
    ///
    /// MODIFICATION : Implémentation d'un encode() personnalisé qui vérifie chaque champ optionnel
    /// avant de l'encoder, évitant ainsi d'envoyer des valeurs null au backend.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(titre, forKey: .titre)
        try container.encode(type, forKey: .type)
        try container.encode(date, forKey: .date)
        try container.encode(heureDebut, forKey: .heureDebut)
        try container.encode(heureFin, forKey: .heureFin)
        
        // N'encoder les champs optionnels que s'ils ne sont pas nil
        // Cela évite d'envoyer des valeurs null au backend qui pourraient causer des erreurs
        if let lieu = lieu {
            try container.encode(lieu, forKey: .lieu)
        }
        if let tarifHoraire = tarifHoraire {
            try container.encode(tarifHoraire, forKey: .tarifHoraire)
        }
        if let couleur = couleur {
            try container.encode(couleur, forKey: .couleur)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case titre
        case type
        case date
        case heureDebut
        case heureFin
        case lieu
        case tarifHoraire
        case couleur
    }
}

/// DTO pour mettre à jour un événement
/// Correspond au UpdateEvenementDto du backend
struct UpdateEvenementRequest: Codable {
    let titre: String?
    let type: String?
    let date: String?
    let heureDebut: String?
    let heureFin: String?
    let lieu: String?
    let tarifHoraire: Double?
    let couleur: String?
    
    init(titre: String? = nil, type: String? = nil, date: String? = nil, heureDebut: String? = nil, heureFin: String? = nil, lieu: String? = nil, tarifHoraire: Double? = nil, couleur: String? = nil) {
        self.titre = titre
        self.type = type
        self.date = date
        self.heureDebut = heureDebut
        self.heureFin = heureFin
        self.lieu = lieu
        self.tarifHoraire = tarifHoraire
        self.couleur = couleur
    }
    
    /// Encodage personnalisé pour exclure les champs nil du JSON lors des mises à jour
    /// 
    /// PROBLÈME RÉSOLU : Lors des mises à jour partielles (PATCH), envoyer des champs null
    /// peut causer des erreurs 403 ou des problèmes de validation côté backend.
    /// Cette méthode garantit qu'on n'envoie que les champs modifiés (non-nil).
    ///
    /// MODIFICATION : Implémentation d'un encode() personnalisé pour UpdateEvenementRequest
    /// qui n'encode que les champs présents, permettant des mises à jour partielles propres.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // N'encoder que les champs qui ne sont pas nil
        // Pour les requêtes PATCH, cela permet de ne modifier que les champs spécifiés
        // et d'éviter d'envoyer des valeurs null qui pourraient causer des erreurs
        if let titre = titre {
            try container.encode(titre, forKey: .titre)
        }
        if let type = type {
            try container.encode(type, forKey: .type)
        }
        if let date = date {
            try container.encode(date, forKey: .date)
        }
        if let heureDebut = heureDebut {
            try container.encode(heureDebut, forKey: .heureDebut)
        }
        if let heureFin = heureFin {
            try container.encode(heureFin, forKey: .heureFin)
        }
        if let lieu = lieu {
            try container.encode(lieu, forKey: .lieu)
        }
        if let tarifHoraire = tarifHoraire {
            try container.encode(tarifHoraire, forKey: .tarifHoraire)
        }
        if let couleur = couleur {
            try container.encode(couleur, forKey: .couleur)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case titre
        case type
        case date
        case heureDebut
        case heureFin
        case lieu
        case tarifHoraire
        case couleur
    }
}

