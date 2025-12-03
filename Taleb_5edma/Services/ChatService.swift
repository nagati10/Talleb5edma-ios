//
//  ChatService.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation
import Combine
import UIKit

/// Service pour gérer les opérations CRUD des chats et messages
/// Communique avec le backend NestJS pour créer, lire, mettre à jour et supprimer des chats
class ChatService: ObservableObject {
    // MARK: - Properties
    
    /// URL de base de l'API (configurée dans APIConfig.swift)
    private var baseURL: String {
        return APIConfig.baseURL
    }
    
    /// Session URL pour les requêtes réseau
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfig.requestTimeout
        configuration.timeoutIntervalForResource = APIConfig.requestTimeout
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        return URLSession(configuration: configuration)
    }()
    
    /// Token d'authentification (récupéré depuis AuthService)
    private var authToken: String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    // MARK: - Helper Methods
    
    /// Crée une requête avec les headers appropriés
    private func createRequest(url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let token = authToken else {
            throw ChatError.notAuthenticated
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    /// Crée une requête multipart/form-data pour l'upload de fichiers
    private func createMultipartRequest(url: URL, method: String, boundary: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let token = authToken else {
            throw ChatError.notAuthenticated
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    private func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = formatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Format de date invalide: \(dateString)"
            )
        }
        return decoder
    }
    
    // MARK: - Chat CRUD Methods
    
    /// Crée un nouveau chat ou récupère un chat existant
    func createOrGetChat(_ request: CreateChatRequest) async throws -> Chat {
        guard let url = URL(string: APIConfig.createChatEndpoint) else {
            throw ChatError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "POST")
        httpRequest.httpBody = try JSONEncoder().encode(request)
        
        print("🔵 Create/Get Chat - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        print("🔵 Create/Get Chat - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw ChatError.notFound
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        let chat = try makeJSONDecoder().decode(Chat.self, from: data)
        print("✅ Create/Get Chat - Success: ID: \(chat.id)")
        return chat
    }
    
    /// Récupère tous les chats de l'utilisateur
    func getMyChats() async throws -> [Chat] {
        guard let url = URL(string: APIConfig.getMyChatsEndpoint) else {
            throw ChatError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get My Chats - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        print("🔵 Get My Chats - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        let chats = try makeJSONDecoder().decode([Chat].self, from: data)
        print("✅ Get My Chats - Success: \(chats.count) chats")
        return chats
    }
    
    /// Récupère un chat par ID
    func getChatById(_ chatId: String) async throws -> Chat {
        guard let url = URL(string: APIConfig.getChatByIdEndpoint(chatId: chatId)) else {
            throw ChatError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Chat By ID - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        print("🔵 Get Chat By ID - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw ChatError.notFound
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        let chat = try makeJSONDecoder().decode(Chat.self, from: data)
        return chat
    }
    
    /// Met à jour un chat
    func updateChat(chatId: String, _ request: UpdateChatRequest) async throws -> Chat {
        guard let url = URL(string: APIConfig.getChatByIdEndpoint(chatId: chatId)) else {
            throw ChatError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "PATCH")
        httpRequest.httpBody = try JSONEncoder().encode(request)
        
        print("🔵 Update Chat - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        print("🔵 Update Chat - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw ChatError.notFound
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        let chat = try makeJSONDecoder().decode(Chat.self, from: data)
        print("✅ Update Chat - Success")
        return chat
    }
    
    /// Supprime un chat
    func deleteChat(_ chatId: String) async throws {
        guard let url = URL(string: APIConfig.deleteChatEndpoint(chatId: chatId)) else {
            throw ChatError.networkError
        }
        
        let request = try createRequest(url: url, method: "DELETE")
        
        print("🔵 Delete Chat - URL: \(url.absoluteString)")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw ChatError.notFound
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        print("✅ Delete Chat - Success")
    }
    
    // MARK: - Chat Actions (Entreprise only)
    
    /// Bloque un chat (Entreprise seulement)
    func blockChat(_ chatId: String) async throws -> Chat {
        guard let url = URL(string: APIConfig.blockChatEndpoint(chatId: chatId)) else {
            throw ChatError.networkError
        }
        
        let request = try createRequest(url: url, method: "PATCH")
        
        print("🔵 Block Chat - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            } else if httpResponse.statusCode == 403 {
                throw ChatError.forbidden
            } else if httpResponse.statusCode == 404 {
                throw ChatError.notFound
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        let chat = try makeJSONDecoder().decode(Chat.self, from: data)
        print("✅ Block Chat - Success")
        return chat
    }
    
    /// Débloque un chat (Entreprise seulement)
    func unblockChat(_ chatId: String) async throws -> Chat {
        guard let url = URL(string: APIConfig.unblockChatEndpoint(chatId: chatId)) else {
            throw ChatError.networkError
        }
        
        let request = try createRequest(url: url, method: "PATCH")
        
        print("🔵 Unblock Chat - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            } else if httpResponse.statusCode == 403 {
                throw ChatError.forbidden
            } else if httpResponse.statusCode == 404 {
                throw ChatError.notFound
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        let chat = try makeJSONDecoder().decode(Chat.self, from: data)
        print("✅ Unblock Chat - Success")
        return chat
    }
    
    /// Accepte un candidat (Entreprise seulement)
    func acceptChat(_ chatId: String) async throws -> Chat {
        guard let url = URL(string: APIConfig.acceptChatEndpoint(chatId: chatId)) else {
            throw ChatError.networkError
        }
        
        let request = try createRequest(url: url, method: "PATCH")
        
        print("🔵 Accept Chat - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            } else if httpResponse.statusCode == 403 {
                throw ChatError.forbidden
            } else if httpResponse.statusCode == 404 {
                throw ChatError.notFound
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        let chat = try makeJSONDecoder().decode(Chat.self, from: data)
        print("✅ Accept Chat - Success")
        return chat
    }
    
    /// Vérifie si un utilisateur peut appeler pour une offre
    func canCall(offerId: String) async throws -> CanCallResponse {
        guard let url = URL(string: APIConfig.canCallEndpoint(offerId: offerId)) else {
            throw ChatError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Can Call - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw ChatError.notFound
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        let canCallResponse = try makeJSONDecoder().decode(CanCallResponse.self, from: data)
        print("✅ Can Call - Success: \(canCallResponse.canCall)")
        return canCallResponse
    }
    
    // MARK: - Message Methods
    
    /// Envoie un message dans un chat
    func sendMessage(chatId: String, _ request: SendMessageRequest) async throws -> Message {
        guard let url = URL(string: APIConfig.sendMessageEndpoint(chatId: chatId)) else {
            throw ChatError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "POST")
        httpRequest.httpBody = try JSONEncoder().encode(request)
        
        print("🔵 Send Message - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        print("🔵 Send Message - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw ChatError.notFound
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        let message = try makeJSONDecoder().decode(Message.self, from: data)
        print("✅ Send Message - Success: \(message.content.prefix(50))")
        return message
    }
    
    /// Récupère les messages d'un chat avec pagination
    func getChatMessages(chatId: String, page: Int? = nil, limit: Int? = nil) async throws -> PaginatedMessagesResponse {
        guard let url = URL(string: APIConfig.getChatMessagesEndpoint(chatId: chatId, page: page, limit: limit)) else {
            throw ChatError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Chat Messages - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        print("🔵 Get Chat Messages - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw ChatError.notFound
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        // Le backend peut renvoyer soit un tableau de messages, soit un objet paginé
        // On essaie d'abord l'objet paginé, sinon on crée un objet paginé à partir du tableau
        if let paginatedResponse = try? makeJSONDecoder().decode(PaginatedMessagesResponse.self, from: data) {
            print("✅ Get Chat Messages - Success: \(paginatedResponse.messages.count) messages")
            return paginatedResponse
        } else if let messages = try? makeJSONDecoder().decode([Message].self, from: data) {
            // Si c'est juste un tableau, on crée une réponse paginée
            let paginatedResponse = PaginatedMessagesResponse(
                messages: messages,
                total: messages.count,
                page: page ?? 1,
                limit: limit ?? messages.count,
                hasMore: false
            )
            print("✅ Get Chat Messages - Success: \(messages.count) messages")
            return paginatedResponse
        } else {
            throw ChatError.decodingError
        }
    }
    
    /// Marque les messages d'un chat comme lus
    func markMessagesAsRead(chatId: String) async throws {
        guard let url = URL(string: APIConfig.markMessagesReadEndpoint(chatId: chatId)) else {
            throw ChatError.networkError
        }
        
        let request = try createRequest(url: url, method: "PATCH")
        
        print("🔵 Mark Messages Read - URL: \(url.absoluteString)")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw ChatError.notFound
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        print("✅ Mark Messages Read - Success")
    }
    
    // MARK: - Media Upload
    
    /// Upload un fichier média pour un chat
    func uploadChatMedia(_ fileData: Data, fileName: String, mimeType: String) async throws -> String {
        guard let url = URL(string: APIConfig.uploadChatMediaEndpoint) else {
            throw ChatError.networkError
        }
        
        let boundary = UUID().uuidString
        var httpRequest = try createMultipartRequest(url: url, method: "POST", boundary: boundary)
        
        // Construire le body multipart/form-data
        var body = Data()
        
        // Ajouter le fichier
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Fermer le boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        httpRequest.httpBody = body
        
        print("🔵 Upload Chat Media - URL: \(url.absoluteString)")
        print("🔵 Upload Chat Media - File size: \(fileData.count) bytes")
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        print("🔵 Upload Chat Media - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ChatError.notAuthenticated
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        // Le backend peut renvoyer soit directement l'URL, soit un objet avec l'URL
        if let urlString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           urlString.hasPrefix("http") {
            print("✅ Upload Chat Media - Success: \(urlString)")
            return urlString
        } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let urlString = json["url"] as? String ?? json["mediaUrl"] as? String {
            print("✅ Upload Chat Media - Success: \(urlString)")
            return urlString
        } else {
            throw ChatError.invalidResponse
        }
    }
}

// MARK: - Chat Errors
enum ChatError: LocalizedError {
    case invalidData
    case invalidResponse
    case serverError(Int)
    case networkError
    case notAuthenticated
    case notFound
    case forbidden
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Données invalides"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .serverError(let code):
            return "Erreur serveur: \(code)"
        case .networkError:
            return "Erreur de connexion réseau"
        case .notAuthenticated:
            return "Vous devez être connecté pour effectuer cette action"
        case .notFound:
            return "Chat ou message introuvable"
        case .forbidden:
            return "Vous n'avez pas la permission d'effectuer cette action"
        case .decodingError:
            return "Erreur lors du décodage de la réponse"
        }
    }
}

