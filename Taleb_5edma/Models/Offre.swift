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
    let userId: String?  // This maps to "createdBy" from backend
    let createdAt: Date?
    let updatedAt: Date?
    
    // New fields from your MongoDB structure
    let createdBy: CreatedBy?
    let days: Int?
    let likedBy: [String]?
    let acceptedUsers: [String]?
    let blockedUsers: [String]?
    
    // Computed property to easily access the entreprise ID
    var entrepriseId: String? {
        return createdBy?.id ?? userId
    }
    
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
        case createdBy
        case days
        case likedBy
        case acceptedUsers
        case blockedUsers
    }
    
    /// Initializer membre à membre pour créer une instance d'Offre
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
        updatedAt: Date? = nil,
        createdBy: CreatedBy? = nil,
        days: Int? = nil,
        likedBy: [String]? = nil,
        acceptedUsers: [String]? = nil,
        blockedUsers: [String]? = nil
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
        self.createdBy = createdBy
        self.days = days
        self.likedBy = likedBy
        self.acceptedUsers = acceptedUsers
        self.blockedUsers = blockedUsers
    }
    
    /// Décodage personnalisé pour gérer les différents formats de données
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        location = try container.decode(OffreLocation.self, forKey: .location)
        company = try container.decode(String.self, forKey: .company)
        
        // Optional fields with flexible decoding
        tags = try? container.decodeIfPresent([String].self, forKey: .tags)
        exigences = try? container.decodeIfPresent([String].self, forKey: .exigences)
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        salary = try? container.decodeIfPresent(String.self, forKey: .salary)
        expiresAt = try? container.decodeIfPresent(String.self, forKey: .expiresAt)
        jobType = try? container.decodeIfPresent(String.self, forKey: .jobType)
        shift = try? container.decodeIfPresent(String.self, forKey: .shift)
        isActive = try? container.decodeIfPresent(Bool.self, forKey: .isActive)
        images = try? container.decodeIfPresent([String].self, forKey: .images)
        viewCount = try? container.decodeIfPresent(Int.self, forKey: .viewCount)
        likeCount = try? container.decodeIfPresent(Int.self, forKey: .likeCount)
        
        // Handle createdBy as complex object
        createdBy = try? container.decodeIfPresent(CreatedBy.self, forKey: .createdBy)
        
        // Handle userId/createdBy mapping - if createdBy exists, use its ID
        if let createdByValue = createdBy {
            userId = createdByValue.id
        } else {
            userId = try? container.decodeIfPresent(String.self, forKey: .userId)
        }
        
        // Additional fields from MongoDB
        days = try? container.decodeIfPresent(Int.self, forKey: .days)
        likedBy = try? container.decodeIfPresent([String].self, forKey: .likedBy)
        acceptedUsers = try? container.decodeIfPresent([String].self, forKey: .acceptedUsers)
        blockedUsers = try? container.decodeIfPresent([String].self, forKey: .blockedUsers)
        
        // Date fields
        createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try? container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

/// Structure représentant l'utilisateur qui a créé l'offre
struct CreatedBy: Codable {
    let id: String
    let nom: String
    let email: String
    let contact: String?
    let image: String?
    let modeExamens: Bool?
    let is_archive: Bool?
    let TrustXP: Int?
    let is_Organization: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nom
        case email
        case contact
        case image
        case modeExamens
        case is_archive
        case TrustXP
        case is_Organization
    }
}

/// Structure représentant la localisation d'une offre
struct OffreLocation: Codable {
    let address: String
    let city: String?
    let country: String?
    let coordinates: Coordinates?
    
    // Flexible initializer for location
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        address = try container.decode(String.self, forKey: .address)
        city = try? container.decodeIfPresent(String.self, forKey: .city)
        country = try? container.decodeIfPresent(String.self, forKey: .country)
        coordinates = try? container.decodeIfPresent(Coordinates.self, forKey: .coordinates)
    }
    
    init(address: String, city: String? = nil, country: String? = nil, coordinates: Coordinates? = nil) {
        self.address = address
        self.city = city
        self.country = country
        self.coordinates = coordinates
    }
    
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
    
    enum CodingKeys: String, CodingKey {
        case lat
        case lng
    }
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


