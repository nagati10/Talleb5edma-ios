//
//  ChatModels.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation

// MARK: - Enums

enum ChatModels {
    // Namespace pour éviter les conflits avec Chat.swift
}

extension ChatModels {
    enum MessageType: String, Codable {
        case text = "text"
        case image = "image"
        case video = "video"
        case audio = "audio"
        case emoji = "emoji"
    }
    
    // MARK: - Request Models
    
    struct CreateChatRequest: Codable {
        let entreprise: String
        let offer: String
    }
    
    struct SendMessageRequest: Codable {
        let content: String?
        let type: MessageType
        let mediaUrl: String?
        let fileName: String?
        let fileSize: String?
        let duration: String?
    }
    
    struct BlockChatRequest: Codable {
        let blockReason: String?
    }

    // MARK: - Response Models
    
    struct CreateChatResponse: Codable {
        let id: String
        let candidate: String?
        let entreprise: String?
        let offer: String?
        let isBlocked: Bool?
        let blockedBy: String?
        let blockReason: String?
        let isDeleted: Bool?
        let deletedBy: String?
        let isAccepted: Bool?
        let acceptedAt: String?
        let lastActivity: String?
        let lastMessage: String?
        let lastMessageType: String?
        let unreadCandidate: Int?
        let unreadEntreprise: Int?
        let createdAt: String?
        let updatedAt: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case candidate, entreprise, offer, isBlocked, blockedBy, blockReason
            case isDeleted, deletedBy, isAccepted, acceptedAt, lastActivity
            case lastMessage, lastMessageType, unreadCandidate, unreadEntreprise
            case createdAt, updatedAt
        }
    }
    
    struct ChatUser: Codable {
        let id: String
        let nom: String
        let email: String
        let contact: String?
        let image: String?
        let isOrganization: Bool?
        
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case nom, email, contact, image
            case isOrganization = "is_Organization"
        }
    }

    // Simple Offer model for chat
    struct ChatOffer: Codable {
        let id: String
        let title: String?
        let company: String?
        let salary: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case title, company, salary
        }
    }

    struct GetChatByIdResponse: Codable {
        let id: String
        let candidate: ChatUser?
        let entreprise: ChatUser?
        let offer: ChatOffer?
        let isBlocked: Bool?
        let blockedBy: String?
        let blockReason: String?
        let isDeleted: Bool?
        let deletedBy: String?
        let isAccepted: Bool?
        let acceptedAt: String?
        let lastActivity: String?
        let lastMessage: String?
        let lastMessageType: String?
        let unreadCandidate: Int?
        let unreadEntreprise: Int?
        let createdAt: String?
        let updatedAt: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case candidate, entreprise, offer, isBlocked, blockedBy, blockReason
            case isDeleted, deletedBy, isAccepted, acceptedAt, lastActivity
            case lastMessage, lastMessageType, unreadCandidate, unreadEntreprise
            case createdAt, updatedAt
        }
    }
    
    struct GetUserChatsResponse: Codable {
        let id: String
        let candidate: ChatUser?
        let entreprise: ChatUser?
        let offer: ChatOffer?
        let isBlocked: Bool?
        let isAccepted: Bool?
        let lastActivity: String?
        let lastMessage: String?
        let lastMessageType: String?
        let unreadCandidate: Int?
        let unreadEntreprise: Int?
        
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case candidate, entreprise, offer, isBlocked, isAccepted, lastActivity
            case lastMessage, lastMessageType, unreadCandidate, unreadEntreprise
        }
    }
    
    struct SendMessageResponse: Codable {
        let id: String
        let chat: String
        let sender: ChatUser?
        let type: MessageType
        let content: String?
        let mediaUrl: String?
        let fileName: String?
        let fileSize: String?
        let duration: String?
        let isRead: Bool?
        let createdAt: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case chat, sender, type, content, mediaUrl, fileName, fileSize, duration
            case isRead, createdAt
        }
    }

    struct GetChatMessagesResponse: Codable {
        let messages: [APIChatMessage]
        let total: Int
    }
    
    // Renamed to avoid conflict with ChatView's ChatMessage
    struct APIChatMessage: Codable, Identifiable {
        let id: String
        let chat: String
        let sender: ChatUser?
        let type: MessageType
        let content: String?
        let mediaUrl: String?
        let fileName: String?
        let fileSize: String?
        let duration: String?
        let isRead: Bool?
        let createdAt: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case chat, sender, type, content, mediaUrl, fileName, fileSize, duration
            case isRead, createdAt
        }
    }
    
    struct UploadMediaResponse: Codable {
        let url: String
        let fileName: String
        let fileSize: String
    }

    // MARK: - Simple Response Models
    
    struct MarkMessagesReadResponse: Codable {
        let message: String
    }
    
    struct DeleteChatResponse: Codable {
        let message: String
    }

    // MARK: - UI Models
    
    enum ChatListItem: Identifiable {
        case message(APIChatMessage)
        case timeSeparator(TimeSeparator)
        
        var id: String {
            switch self {
            case .message(let message):
                return "message_\(message.id)"
            case .timeSeparator(let separator):
                return "separator_\(separator.timestamp)"
            }
        }
    }
    
    struct TimeSeparator {
        let text: String
        let timestamp: String
    }
    
    static func formatDateForDisplay(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Aujourd'hui"
        } else if calendar.isDateInYesterday(date) {
            return "Hier"
        } else {
            formatter.dateFormat = "dd MMM yyyy"
            formatter.locale = Locale(identifier: "fr_FR")
            return formatter.string(from: date)
        }
    }
}

// MARK: - Helper Extensions (au niveau du fichier)

extension ChatModels.APIChatMessage {
    var displayTime: String {
        guard let messageCreatedAt = self.createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: messageCreatedAt) {
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        return ""
    }
}

extension Array where Element == ChatModels.APIChatMessage {
    func groupWithTimeSeparators() -> [ChatModels.ChatListItem] {
        var items: [ChatModels.ChatListItem] = []
        var lastDate: String?
        
        let sortedMessages = self.sorted {
            ($0.createdAt ?? "") < ($1.createdAt ?? "")
        }
        
        for message in sortedMessages {
            guard let messageCreatedAt = message.createdAt else { continue }
            let messageDate = String(messageCreatedAt.prefix(10)) // Get YYYY-MM-DD part
            
            if messageDate != lastDate {
                let separator = ChatModels.TimeSeparator(
                    text: ChatModels.formatDateForDisplay(messageDate),
                    timestamp: messageDate
                )
                items.append(.timeSeparator(separator))
                lastDate = messageDate
            }
            items.append(.message(message))
        }
        
        return items
    }
}

