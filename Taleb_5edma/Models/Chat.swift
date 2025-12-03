//
//  Chat.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation

/// Modèle représentant un chat entre un utilisateur et une entreprise
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
    let chatId: String?
    let senderId: String?
    let content: String
    let type: MessageType
    let mediaUrl: String?
    let fileName: String?
    let fileSize: String?
    let duration: String?
    let thumbnail: String?
    let replyTo: String?
    let isRead: Bool?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case chatId
        case sender  // Changed from senderId to sender to match API response
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
    
    // Nested structure to decode the sender object
    private struct SenderObject: Codable {
        let id: String
        
        enum CodingKeys: String, CodingKey {
            case id = "_id"
        }
    }
    
    // Custom decoder to handle nested sender object
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        type = try container.decode(MessageType.self, forKey: .type)
        
        // Optional fields
        chatId = try? container.decodeIfPresent(String.self, forKey: .chatId)
        
        // Parse sender - can be either a string ID or an object with _id
        if let senderObject = try? container.decodeIfPresent(SenderObject.self, forKey: .sender) {
            // API returns sender as an object: {"_id": "...", "nom": "...", ...}
            senderId = senderObject.id
        } else if let senderString = try? container.decodeIfPresent(String.self, forKey: .sender) {
            // Fallback: sender might be just a string ID
            senderId = senderString
        } else {
            senderId = nil
        }
        
        mediaUrl = try? container.decodeIfPresent(String.self, forKey: .mediaUrl)
        fileName = try? container.decodeIfPresent(String.self, forKey: .fileName)
        fileSize = try? container.decodeIfPresent(String.self, forKey: .fileSize)
        duration = try? container.decodeIfPresent(String.self, forKey: .duration)
        thumbnail = try? container.decodeIfPresent(String.self, forKey: .thumbnail)
        replyTo = try? container.decodeIfPresent(String.self, forKey: .replyTo)
        isRead = try? container.decodeIfPresent(Bool.self, forKey: .isRead)
        createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try? container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    // Custom encoder to satisfy Encodable protocol
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
        
        // Optional fields
        try container.encodeIfPresent(chatId, forKey: .chatId)
        try container.encodeIfPresent(senderId, forKey: .sender)  // Encode senderId as "sender"
        try container.encodeIfPresent(mediaUrl, forKey: .mediaUrl)
        try container.encodeIfPresent(fileName, forKey: .fileName)
        try container.encodeIfPresent(fileSize, forKey: .fileSize)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(thumbnail, forKey: .thumbnail)
        try container.encodeIfPresent(replyTo, forKey: .replyTo)
        try container.encodeIfPresent(isRead, forKey: .isRead)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

/// Type de message
enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case audio = "audio"
    case video = "video"
    case file = "file"
    case emoji = "emoji"
}

// MARK: - Message Convenience Initializer
extension Message {
    /// Convenience initializer for creating Message instances programmatically
    init(
        id: String,
        chatId: String?,
        senderId: String?,
        content: String?,
        type: MessageType,
        mediaUrl: String? = nil,
        fileName: String? = nil,
        fileSize: String? = nil,
        duration: String? = nil,
        thumbnail: String? = nil,
        replyTo: String? = nil,
        isRead: Bool? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.content = content ?? ""
        self.type = type
        self.mediaUrl = mediaUrl
        self.fileName = fileName
        self.fileSize = fileSize
        self.duration = duration
        self.thumbnail = thumbnail
        self.replyTo = replyTo
        self.isRead = isRead
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// DTO pour créer un nouveau chat
struct CreateChatRequest: Codable {
    let entreprise: String?
    let offer: String?
    
    init(entreprise: String? = nil, offer: String? = nil) {
        self.entreprise = entreprise
        self.offer = offer
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
    }
    
    enum CodingKeys: String, CodingKey {
        case entreprise
        case offer
    }
}

/// DTO pour envoyer un message
struct SendMessageRequest: Codable {
    let content: String
    let type: MessageType
    let mediaUrl: String?
    let fileName: String?
    let fileSize: String?
    let duration: String?
    let thumbnail: String?
    let replyTo: String?
    
    init(
        content: String,
        type: MessageType = .text,
        mediaUrl: String? = nil,
        fileName: String? = nil,
        fileSize: String? = nil,
        duration: String? = nil,
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(type.rawValue, forKey: .type)
        
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
/// Réponse paginée pour les messages - UPDATED to match backend structure
struct PaginatedMessagesResponse: Codable {
    let messages: [Message]
    let total: Int
    // Make page, limit, and hasMore optional to match backend response
    let page: Int?
    let limit: Int?
    let hasMore: Bool?
    
    // Add a custom initializer for flexibility
    init(messages: [Message], total: Int, page: Int? = nil, limit: Int? = nil, hasMore: Bool? = nil) {
        self.messages = messages
        self.total = total
        self.page = page
        self.limit = limit
        self.hasMore = hasMore
    }
    
    // Custom coding keys to handle the actual backend response
    enum CodingKeys: String, CodingKey {
        case messages
        case total
        case page
        case limit
        case hasMore
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        messages = try container.decode([Message].self, forKey: .messages)
        total = try container.decode(Int.self, forKey: .total)
        
        // Optional fields - don't fail if they're missing
        page = try? container.decodeIfPresent(Int.self, forKey: .page)
        limit = try? container.decodeIfPresent(Int.self, forKey: .limit)
        hasMore = try? container.decodeIfPresent(Bool.self, forKey: .hasMore)
    }
}

/// Réponse pour vérifier si un appel est possible
struct CanCallResponse: Codable {
    let canCall: Bool
    let reason: String?
}
