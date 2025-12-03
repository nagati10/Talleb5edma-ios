//
//  ChatViewModel.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var messageText: String = ""
    @Published var showingCall: Bool = false
    @Published var isVideoCall: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let offre: Offre?
    private let chatRepository = ChatRepository.shared
    private var currentChatId: String?
    private var cancellables = Set<AnyCancellable>()
    
    // Token d'authentification
    private var authToken: String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    init(offre: Offre?) {
        self.offre = offre
    }
    
    func loadChatHistory() {
        guard let token = authToken else {
            errorMessage = "Vous devez être connecté pour accéder au chat"
            return
        }
        
        // Utiliser un userId par défaut si l'offre n'en a pas
        // Cela permet au chat de fonctionner même si l'offre n'a pas de créateur défini
        let entrepriseId = offre?.userId ?? "default-entreprise-id-\(offre?.id ?? "unknown")"
        
        guard let offerId = offre?.id else {
            errorMessage = "Informations de l'offre manquantes"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Créer ou obtenir le chat
                let chatRequest = ChatModels.CreateChatRequest(entreprise: entrepriseId, offer: offerId)
                let chatResponse = try await chatRepository.createOrGetChat(token: token, request: chatRequest)
                currentChatId = chatResponse.id
                
                // Charger les messages
                let messagesResponse = try await chatRepository.getMessages(token: token, chatId: chatResponse.id)
                
                // Convertir les messages API en ChatMessage pour l'UI
                await MainActor.run {
                    self.messages = messagesResponse.messages.map { apiMessage in
                        self.convertToChatMessage(apiMessage)
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Erreur lors du chargement du chat: \(error.localizedDescription)"
                    // Charger des messages par défaut en cas d'erreur
                    self.loadDefaultMessages()
                }
            }
        }
    }
    
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let token = authToken else {
            errorMessage = "Vous devez être connecté pour envoyer un message"
            return
        }
        
        let text = messageText
        messageText = ""
        
        // Si le chat n'est pas encore initialisé, l'initialiser d'abord
        if currentChatId == nil {
            Task {
                await initializeChatAndSendMessage(text: text, token: token)
            }
        } else {
            // Chat déjà initialisé, envoyer directement
            sendMessageToChat(text: text, token: token, chatId: currentChatId!)
        }
    }
    
    private func initializeChatAndSendMessage(text: String, token: String) async {
        // Utiliser un userId par défaut si l'offre n'en a pas
        let entrepriseId = offre?.userId ?? "default-entreprise-id-\(offre?.id ?? "unknown")"
        
        guard let offerId = offre?.id else {
            await MainActor.run {
                self.errorMessage = "Informations de l'offre manquantes"
                self.messageText = text // Remettre le texte
            }
            return
        }
        
        do {
            // Créer ou obtenir le chat
            let chatRequest = ChatModels.CreateChatRequest(entreprise: entrepriseId, offer: offerId)
            let chatResponse = try await chatRepository.createOrGetChat(token: token, request: chatRequest)
            
            await MainActor.run {
                self.currentChatId = chatResponse.id
                self.errorMessage = nil
            }
            
            // Charger les messages existants
            let messagesResponse = try await chatRepository.getMessages(token: token, chatId: chatResponse.id)
            await MainActor.run {
                self.messages = messagesResponse.messages.map { apiMessage in
                    self.convertToChatMessage(apiMessage)
                }
            }
            
            // Maintenant envoyer le message
            sendMessageToChat(text: text, token: token, chatId: chatResponse.id)
        } catch {
            await MainActor.run {
                self.errorMessage = "Erreur lors de l'initialisation du chat: \(error.localizedDescription)"
                self.messageText = text // Remettre le texte
            }
        }
    }
    
    private func sendMessageToChat(text: String, token: String, chatId: String) {
        // Ajouter le message localement immédiatement
        let newMessage = ChatMessage(
            text: text,
            isSent: true,
            timestamp: getCurrentTime(),
            showAvatar: false
        )
        messages.append(newMessage)
        
        // Envoyer le message via l'API
        Task {
            do {
                let request = ChatModels.SendMessageRequest(
                    content: text,
                    type: ChatModels.MessageType.text,
                    mediaUrl: nil,
                    fileName: nil,
                    fileSize: nil,
                    duration: nil
                )
                
                _ = try await chatRepository.sendMessage(token: token, chatId: chatId, request: request)
                print("✅ Message envoyé avec succès")
            } catch {
                print("❌ Erreur lors de l'envoi du message: \(error)")
                await MainActor.run {
                    self.errorMessage = "Erreur lors de l'envoi du message"
                    // Retirer le message local si l'envoi échoue
                    if let index = self.messages.firstIndex(where: { $0.text == text && $0.isSent }) {
                        self.messages.remove(at: index)
                    }
                }
            }
        }
    }
    
    func initiateCall(isVideoCall: Bool) {
        self.isVideoCall = isVideoCall
        self.showingCall = true
        
        // TODO: Implémenter l'appel via l'API si nécessaire
        // Pour l'instant, on affiche juste l'interface d'appel
    }
    
    func endCall() {
        showingCall = false
    }
    
    // MARK: - Helper Methods
    
    private func convertToChatMessage(_ apiMessage: ChatModels.APIChatMessage) -> ChatMessage {
        // Déterminer si le message est envoyé par l'utilisateur actuel
        let currentUserId = UserDefaults.standard.string(forKey: "userId")
        let isSent = apiMessage.sender?.id == currentUserId
        
        return ChatMessage(
            text: apiMessage.content ?? "",
            isSent: isSent,
            timestamp: apiMessage.displayTime,
            showAvatar: !isSent
        )
    }
    
    private func loadDefaultMessages() {
        let defaultMessages = [
            ChatMessage(
                text: "Bonjour ! Je suis intéressé par le poste \"\(offre?.title ?? "")\".",
                isSent: true,
                timestamp: getCurrentTime(),
                showAvatar: false
            ),
            ChatMessage(
                text: "Bonjour ! Merci pour votre intérêt. Comment puis-je vous aider ?",
                isSent: false,
                timestamp: getCurrentTime(),
                showAvatar: true
            )
        ]
        
        messages = defaultMessages
    }
    
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

