//
//  ChatRepository.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation
import UIKit

class ChatRepository {
    static let shared = ChatRepository()
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // MARK: - Chat Methods
    
    func createOrGetChat(token: String, request: ChatModels.CreateChatRequest) async throws -> ChatModels.CreateChatResponse {
        let url = URL(string: APIConfig.createOrGetChatEndpoint)!
        
        return try await networkService.request(
            url: url,
            method: "POST",
            body: request,
            token: token
        )
    }
    
    func getChatById(token: String, chatId: String) async throws -> ChatModels.GetChatByIdResponse {
        let url = URL(string: APIConfig.getChatByIdEndpoint(chatId: chatId))!
        
        return try await networkService.request(
            url: url,
            method: "GET",
            token: token
        )
    }
    
    func getMyChats(token: String) async throws -> [ChatModels.GetUserChatsResponse] {
        let url = URL(string: APIConfig.getMyChatsEndpoint)!
        
        return try await networkService.request(
            url: url,
            method: "GET",
            token: token
        )
    }
    
    func getMessages(token: String, chatId: String) async throws -> ChatModels.GetChatMessagesResponse {
        let url = URL(string: APIConfig.getMessagesEndpoint(chatId: chatId))!
        
        return try await networkService.request(
            url: url,
            method: "GET",
            token: token
        )
    }
    
    func sendMessage(token: String, chatId: String, request: ChatModels.SendMessageRequest) async throws -> ChatModels.SendMessageResponse {
        let url = URL(string: APIConfig.sendMessageEndpoint(chatId: chatId))!
        
        return try await networkService.request(
            url: url,
            method: "POST",
            body: request,
            token: token
        )
    }
    
    func blockChat(token: String, chatId: String, reason: String? = nil) async throws -> ChatModels.GetChatByIdResponse {
        let url = URL(string: APIConfig.blockChatEndpoint(chatId: chatId))!
        let request = ChatModels.BlockChatRequest(blockReason: reason)
        
        return try await networkService.request(
            url: url,
            method: "PATCH",
            body: request,
            token: token
        )
    }
    
    func unblockChat(token: String, chatId: String) async throws -> ChatModels.GetChatByIdResponse {
        let url = URL(string: APIConfig.unblockChatEndpoint(chatId: chatId))!
        
        return try await networkService.request(
            url: url,
            method: "PATCH",
            token: token
        )
    }
    
    func acceptCandidate(token: String, chatId: String) async throws -> ChatModels.GetChatByIdResponse {
        let url = URL(string: APIConfig.acceptCandidateEndpoint(chatId: chatId))!
        
        return try await networkService.request(
            url: url,
            method: "PATCH",
            token: token
        )
    }
    
    func markMessagesAsRead(token: String, chatId: String) async throws -> ChatModels.MarkMessagesReadResponse {
        let url = URL(string: APIConfig.markMessagesAsReadEndpoint(chatId: chatId))!
        
        return try await networkService.request(
            url: url,
            method: "PATCH",
            token: token
        )
    }
    
    func canMakeCall(token: String, offerId: String) async throws -> Bool {
        let url = URL(string: APIConfig.canMakeCallEndpoint(offerId: offerId))!
        
        do {
            let response: String = try await networkService.request(
                url: url,
                method: "GET",
                token: token
            )
            return Bool(response) ?? false
        } catch {
            return false
        }
    }
    
    func deleteChat(token: String, chatId: String) async throws -> ChatModels.DeleteChatResponse {
        let url = URL(string: APIConfig.deleteChatEndpoint(chatId: chatId))!
        
        return try await networkService.request(
            url: url,
            method: "DELETE",
            token: token
        )
    }
    
    // MARK: - Media Methods
    
    func uploadMedia(token: String, fileData: Data, fileName: String) async throws -> ChatModels.UploadMediaResponse {
        let url = URL(string: APIConfig.uploadMediaEndpoint)!
        
        return try await networkService.uploadFile(
            url: url,
            fileData: fileData,
            fileName: fileName,
            mimeType: getMimeType(for: fileName),
            token: token
        )
    }
    
    func sendVoiceMessage(token: String, chatId: String, audioData: Data, fileName: String, duration: String) async throws -> ChatModels.SendMessageResponse {
        let uploadResponse = try await uploadMedia(token: token, fileData: audioData, fileName: fileName)
        
        let request = ChatModels.SendMessageRequest(
            content: nil,
            type: ChatModels.MessageType.audio,
            mediaUrl: uploadResponse.url,
            fileName: fileName,
            fileSize: uploadResponse.fileSize,
            duration: duration
        )
        
        return try await sendMessage(token: token, chatId: chatId, request: request)
    }
    
    func sendImageMessage(token: String, chatId: String, imageData: Data, fileName: String) async throws -> ChatModels.SendMessageResponse {
        let uploadResponse = try await uploadMedia(token: token, fileData: imageData, fileName: fileName)
        
        let request = ChatModels.SendMessageRequest(
            content: nil,
            type: ChatModels.MessageType.image,
            mediaUrl: uploadResponse.url,
            fileName: fileName,
            fileSize: uploadResponse.fileSize,
            duration: nil
        )
        
        return try await sendMessage(token: token, chatId: chatId, request: request)
    }
    
    // MARK: - Helper Methods
    
    private func getMimeType(for fileName: String) -> String {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "mp4":
            return "video/mp4"
        case "avi":
            return "video/x-msvideo"
        case "mov":
            return "video/quicktime"
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        case "ogg":
            return "audio/ogg"
        default:
            return "application/octet-stream"
        }
    }
}

