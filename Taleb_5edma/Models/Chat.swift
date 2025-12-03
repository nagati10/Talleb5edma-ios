//
//  Chat.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation

/// Modèle représentant un chat entre un utilisateur et une entreprise
/// Correspond aux DTOs du backend (CreateChatDto, UpdateChatDto)
struct Chat: Codable, Identifiable {
    let id: String
    let entreprise: String?  // ID de l'entreprise
    let offer: String?  // ID de l'offre
    let isBlocked: Bool?
    let blockReason: String?
    let isAccepted: Bool?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case entreprise
        case offer
        case isBlocked
        case blockReason
        case isAccepted
        case createdAt
        case updatedAt
    }
}

/// Modèle représentant un message dans un chat
struct Message: Codable, Identifiable {
    let id: String
    let chatId: String
    let senderId: String
    let content: String
    let type: MessageType
    let mediaUrl: String?
    let fileName: String?
    let fileSize: Int?
    let duration: Double?  // Pour audio/video en secondes
    let thumbnail: String?
    let replyTo: String?  // ID du message auquel on répond
    let isRead: Bool?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case chatId
        case senderId
        case content
        case type
        case mediaUrl
        case fileName
        case fileSize
        case duration
        case thumbnail
        case replyTo
        case isRead
        case createdAt
        case updatedAt
    }
}

/// Type de message
/// Note: Défini dans ChatModels.swift pour éviter les conflits
/// Utilisez MessageType depuis ChatModels.swift
typealias MessageType = ChatModels.MessageType

/// DTO pour créer un nouveau chat
/// Note: Défini dans ChatModels.swift pour éviter les conflits
/// Utilisez CreateChatRequest depuis ChatModels.swift
typealias CreateChatRequest = ChatModels.CreateChatRequest

/// DTO pour envoyer un message
/// Note: Défini dans ChatModels.swift pour éviter les conflits
/// Utilisez SendMessageRequest depuis ChatModels.swift
/// Pour compatibilité avec l'ancien code, cette structure est conservée mais dépréciée
struct SendMessageRequest: Codable {
    let content: String
    let type: MessageType
    let mediaUrl: String?
    let fileName: String?
    let fileSize: Int?
    let duration: Double?
    let thumbnail: String?
    let replyTo: String?
    
    init(
        content: String,
        type: MessageType,
        mediaUrl: String? = nil,
        fileName: String? = nil,
        fileSize: Int? = nil,
        duration: Double? = nil,
        thumbnail: String? = nil,
        replyTo: String? = nil
    ) {
        self.content = content
        self.type = type
        self.mediaUrl = mediaUrl
        self.fileName = fileName
        self.fileSize = fileSize
        self.duration = duration
        self.thumbnail = thumbnail
        self.replyTo = replyTo
    }
    
    /// Encodage personnalisé pour exclure les champs nil
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(type.rawValue, forKey: .type)
        
        // N'encoder les champs optionnels que s'ils ne sont pas nil
        if let mediaUrl = mediaUrl {
            try container.encode(mediaUrl, forKey: .mediaUrl)
        }
        if let fileName = fileName {
            try container.encode(fileName, forKey: .fileName)
        }
        if let fileSize = fileSize {
            try container.encode(fileSize, forKey: .fileSize)
        }
        if let duration = duration {
            try container.encode(duration, forKey: .duration)
        }
        if let thumbnail = thumbnail {
            try container.encode(thumbnail, forKey: .thumbnail)
        }
        if let replyTo = replyTo {
            try container.encode(replyTo, forKey: .replyTo)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case content
        case type
        case mediaUrl
        case fileName
        case fileSize
        case duration
        case thumbnail
        case replyTo
    }
}

/// DTO pour mettre à jour un chat
/// Correspond au UpdateChatDto du backend
struct UpdateChatRequest: Codable {
    let entreprise: String?
    let offer: String?
    let isBlocked: Bool?
    let blockReason: String?
    let isAccepted: Bool?
    
    init(
        entreprise: String? = nil,
        offer: String? = nil,
        isBlocked: Bool? = nil,
        blockReason: String? = nil,
        isAccepted: Bool? = nil
    ) {
        self.entreprise = entreprise
        self.offer = offer
        self.isBlocked = isBlocked
        self.blockReason = blockReason
        self.isAccepted = isAccepted
    }
    
    /// Encodage personnalisé pour exclure les champs nil
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // N'encoder que les champs qui ne sont pas nil
        if let entreprise = entreprise {
            try container.encode(entreprise, forKey: .entreprise)
        }
        if let offer = offer {
            try container.encode(offer, forKey: .offer)
        }
        if let isBlocked = isBlocked {
            try container.encode(isBlocked, forKey: .isBlocked)
        }
        if let blockReason = blockReason {
            try container.encode(blockReason, forKey: .blockReason)
        }
        if let isAccepted = isAccepted {
            try container.encode(isAccepted, forKey: .isAccepted)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case entreprise
        case offer
        case isBlocked
        case blockReason
        case isAccepted
    }
}

/// Réponse paginée pour les messages
struct PaginatedMessagesResponse: Codable {
    let messages: [Message]
    let total: Int
    let page: Int
    let limit: Int
    let hasMore: Bool
}

/// Réponse pour vérifier si un appel est possible
struct CanCallResponse: Codable {
    let canCall: Bool
    let reason: String?
}

