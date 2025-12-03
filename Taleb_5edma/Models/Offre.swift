//
//  Offre.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation

/// Modèle représentant une offre d'emploi
/// Correspond aux DTOs du backend (CreateOffreDto, UpdateOffreDto)
struct Offre: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let tags: [String]?
    let exigences: [String]?
    let location: OffreLocation
    let category: String?
    let salary: String?
    let company: String
    let expiresAt: String?
    let jobType: String?
    let shift: String?
    let isActive: Bool?
    let images: [String]?
    let viewCount: Int?
    let likeCount: Int?
    let userId: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case description
        case tags
        case exigences
        case location
        case category
        case salary
        case company
        case expiresAt
        case jobType
        case shift
        case isActive
        case images
        case viewCount
        case likeCount
        case userId
        case createdAt
        case updatedAt
    }
    
    /// Initializer membre à membre pour créer une instance d'Offre
    /// Permet de créer des instances sans passer par un Decoder
    init(
        id: String,
        title: String,
        description: String,
        tags: [String]? = nil,
        exigences: [String]? = nil,
        location: OffreLocation,
        category: String? = nil,
        salary: String? = nil,
        company: String,
        expiresAt: String? = nil,
        jobType: String? = nil,
        shift: String? = nil,
        isActive: Bool? = nil,
        images: [String]? = nil,
        viewCount: Int? = nil,
        likeCount: Int? = nil,
        userId: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.tags = tags
        self.exigences = exigences
        self.location = location
        self.category = category
        self.salary = salary
        self.company = company
        self.expiresAt = expiresAt
        self.jobType = jobType
        self.shift = shift
        self.isActive = isActive
        self.images = images
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Décodage personnalisé pour gérer les tags et exigences qui peuvent être des chaînes JSON
    /// 
    /// PROBLÈME RÉSOLU : Le backend peut renvoyer les tags/exigences comme des chaînes JSON encodées
    /// au lieu de tableaux simples, ce qui cause un double encodage lors de la mise à jour.
    ///
    /// MODIFICATION : Ajout d'une logique de décodage personnalisée qui détecte si les tags/exigences
    /// sont des chaînes JSON et les décode correctement en tableaux de chaînes.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        
        // Décoder les tags en gérant le cas où ils sont des chaînes JSON
        if let tagsString = try? container.decode(String.self, forKey: .tags),
           let tagsData = tagsString.data(using: .utf8),
           let decodedTags = try? JSONDecoder().decode([String].self, from: tagsData) {
            tags = decodedTags
        } else {
            tags = try container.decodeIfPresent([String].self, forKey: .tags)
        }
        
        // Décoder les exigences en gérant le cas où elles sont des chaînes JSON
        if let exigencesString = try? container.decode(String.self, forKey: .exigences),
           let exigencesData = exigencesString.data(using: .utf8),
           let decodedExigences = try? JSONDecoder().decode([String].self, from: exigencesData) {
            exigences = decodedExigences
        } else {
            exigences = try container.decodeIfPresent([String].self, forKey: .exigences)
        }
        
        location = try container.decode(OffreLocation.self, forKey: .location)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        salary = try container.decodeIfPresent(String.self, forKey: .salary)
        company = try container.decode(String.self, forKey: .company)
        expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt)
        jobType = try container.decodeIfPresent(String.self, forKey: .jobType)
        shift = try container.decodeIfPresent(String.self, forKey: .shift)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        images = try container.decodeIfPresent([String].self, forKey: .images)
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

/// Structure représentant la localisation d'une offre
/// Correspond à l'objet location dans les DTOs backend
struct OffreLocation: Codable {
    let address: String
    let city: String?
    let country: String?
    let coordinates: Coordinates?
    
    enum CodingKeys: String, CodingKey {
        case address
        case city
        case country
        case coordinates
    }
}

/// Structure représentant les coordonnées GPS
struct Coordinates: Codable {
    let lat: Double
    let lng: Double
}

/// DTO pour créer une nouvelle offre
/// Correspond au CreateOffreDto du backend
/// Note: La création utilise multipart/form-data pour supporter les images
struct CreateOffreRequest: Codable {
    let title: String
    let description: String
    let tags: [String]?
    let exigences: [String]?
    let location: OffreLocation
    let category: String?
    let salary: String?
    let company: String
    let expiresAt: String?
    let jobType: String?
    let shift: String?
    let isActive: Bool?
    
    init(
        title: String,
        description: String,
        tags: [String]? = nil,
        exigences: [String]? = nil,
        location: OffreLocation,
        category: String? = nil,
        salary: String? = nil,
        company: String,
        expiresAt: String? = nil,
        jobType: String? = nil,
        shift: String? = nil,
        isActive: Bool? = nil
    ) {
        self.title = title
        self.description = description
        self.tags = tags
        self.exigences = exigences
        self.location = location
        self.category = category
        self.salary = salary
        self.company = company
        self.expiresAt = expiresAt
        self.jobType = jobType
        self.shift = shift
        self.isActive = isActive
    }
    
    /// Encodage personnalisé pour exclure les champs nil
    /// 
    /// PROBLÈME RÉSOLU : Le backend peut rejeter les requêtes contenant des champs null.
    /// Cette méthode garantit que seuls les champs non-nil sont envoyés dans la requête.
    ///
    /// MODIFICATION : Implémentation d'un encode() personnalisé qui vérifie chaque champ optionnel
    /// avant de l'encoder, évitant ainsi d'envoyer des valeurs null au backend.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(location, forKey: .location)
        try container.encode(company, forKey: .company)
        
        // N'encoder les champs optionnels que s'ils ne sont pas nil
        if let tags = tags {
            try container.encode(tags, forKey: .tags)
        }
        if let exigences = exigences {
            try container.encode(exigences, forKey: .exigences)
        }
        if let category = category {
            try container.encode(category, forKey: .category)
        }
        if let salary = salary {
            try container.encode(salary, forKey: .salary)
        }
        if let expiresAt = expiresAt {
            try container.encode(expiresAt, forKey: .expiresAt)
        }
        if let jobType = jobType {
            try container.encode(jobType, forKey: .jobType)
        }
        if let shift = shift {
            try container.encode(shift, forKey: .shift)
        }
        if let isActive = isActive {
            try container.encode(isActive, forKey: .isActive)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case tags
        case exigences
        case location
        case category
        case salary
        case company
        case expiresAt
        case jobType
        case shift
        case isActive
    }
}

/// DTO pour mettre à jour une offre
/// Correspond au UpdateOffreDto du backend
struct UpdateOffreRequest: Codable {
    let title: String?
    let description: String?
    let tags: [String]?
    let exigences: [String]?
    let location: OffreLocation?
    let category: String?
    let salary: String?
    let company: String?
    let expiresAt: String?
    let jobType: String?
    let shift: String?
    let isActive: Bool?
    let images: [String]?
    let viewCount: Int?
    let likeCount: Int?
    
    init(
        title: String? = nil,
        description: String? = nil,
        tags: [String]? = nil,
        exigences: [String]? = nil,
        location: OffreLocation? = nil,
        category: String? = nil,
        salary: String? = nil,
        company: String? = nil,
        expiresAt: String? = nil,
        jobType: String? = nil,
        shift: String? = nil,
        isActive: Bool? = nil,
        images: [String]? = nil,
        viewCount: Int? = nil,
        likeCount: Int? = nil
    ) {
        self.title = title
        self.description = description
        self.tags = tags
        self.exigences = exigences
        self.location = location
        self.category = category
        self.salary = salary
        self.company = company
        self.expiresAt = expiresAt
        self.jobType = jobType
        self.shift = shift
        self.isActive = isActive
        self.images = images
        self.viewCount = viewCount
        self.likeCount = likeCount
    }
    
    /// Encodage personnalisé pour exclure les champs nil du JSON lors des mises à jour
    /// 
    /// PROBLÈME RÉSOLU : Lors des mises à jour partielles (PATCH), envoyer des champs null
    /// peut causer des erreurs 403 ou des problèmes de validation côté backend.
    /// Cette méthode garantit qu'on n'envoie que les champs modifiés (non-nil).
    ///
    /// MODIFICATION : Implémentation d'un encode() personnalisé pour UpdateOffreRequest
    /// qui n'encode que les champs présents, permettant des mises à jour partielles propres.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // N'encoder que les champs qui ne sont pas nil
        if let title = title {
            try container.encode(title, forKey: .title)
        }
        if let description = description {
            try container.encode(description, forKey: .description)
        }
        if let tags = tags {
            try container.encode(tags, forKey: .tags)
        }
        if let exigences = exigences {
            try container.encode(exigences, forKey: .exigences)
        }
        if let location = location {
            try container.encode(location, forKey: .location)
        }
        if let category = category {
            try container.encode(category, forKey: .category)
        }
        if let salary = salary {
            try container.encode(salary, forKey: .salary)
        }
        if let company = company {
            try container.encode(company, forKey: .company)
        }
        if let expiresAt = expiresAt {
            try container.encode(expiresAt, forKey: .expiresAt)
        }
        if let jobType = jobType {
            try container.encode(jobType, forKey: .jobType)
        }
        if let shift = shift {
            try container.encode(shift, forKey: .shift)
        }
        if let isActive = isActive {
            try container.encode(isActive, forKey: .isActive)
        }
        if let images = images {
            try container.encode(images, forKey: .images)
        }
        if let viewCount = viewCount {
            try container.encode(viewCount, forKey: .viewCount)
        }
        if let likeCount = likeCount {
            try container.encode(likeCount, forKey: .likeCount)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case tags
        case exigences
        case location
        case category
        case salary
        case company
        case expiresAt
        case jobType
        case shift
        case isActive
        case images
        case viewCount
        case likeCount
    }
}

