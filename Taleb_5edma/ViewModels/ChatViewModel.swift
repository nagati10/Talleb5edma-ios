//
//  ChatViewModel.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation
import Combine
import SwiftUI
import AVFoundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var messageText: String = ""
    @Published var showingCall: Bool = false
    @Published var isVideoCall: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showChatList: Bool = false
    @Published var userChats: [ChatModels.GetUserChatsResponse] = []
    
    // MARK: - Enhanced Chat Features
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var pendingMedia: [PendingMedia] = []
    @Published var showEmojiPicker = false
    @Published var selectedEmojiCategory = "Smileys"
    @Published var showMediaPicker = false
    @Published var currentlyPlayingAudioId: String?
    
    private let offre: Offre?
    private let currentUserId: String?
    private let chatService = ChatService()
    var currentChatId: String? // Made accessible for CallView
    
    // Audio managers
    private let audioRecorder = AudioRecordingManager()
    private let audioPlayer = AudioPlaybackManager()
    
    init(offre: Offre? = nil, currentUserId: String? = nil) {
        self.offre = offre
        self.currentUserId = currentUserId ?? UserDefaults.standard.string(forKey: "userId")
        
        // Observe audio managers
        setupAudioObservers()
    }
    
    // MARK: - Enhanced Chat Initialization
    
    func initializeChat() {
        guard let offre = offre else {
            errorMessage = "Informations de l'offre manquantes"
            return
        }
        
        // Check if current user is the offer creator
        if isCurrentUserOfferCreator(offre: offre) {
            // User owns the offer - show chat list instead of creating chat
            loadUserChatsForOffer()
        } else {
            // User doesn't own the offer - proceed with normal chat creation
            loadChatHistory()
        }
    }
    
    private func isCurrentUserOfferCreator(offre: Offre) -> Bool {
        guard let currentUserId = currentUserId,
              let entrepriseId = offre.entrepriseId else {
            return false
        }
        return currentUserId == entrepriseId
    }
    
    private func loadUserChatsForOffer() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let chats = try await chatService.getMyChats()
                
                // Filter chats by this specific offer
                let filteredChats = chats.filter { chat in
                    return chat.offer == offre?.id
                }
                
                await MainActor.run {
                    self.userChats = filteredChats as! [ChatModels.GetUserChatsResponse]
                    self.showChatList = true
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors du chargement des conversations: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Chat List Management
    
    func selectChat(_ chatId: String) {
        currentChatId = chatId
        showChatList = false
        loadChatHistory()  // Load messages for selected chat
    }
    
    func createNewChat() {
        showChatList = false
        loadChatHistory()  // This will create a new chat
    }
    
    // MARK: - Chat History Loading
    
    func loadChatHistory() {
        print("🟡 Loading chat history...")
        print("🟡 Offre ID: \(offre?.id ?? "none")")
        print("🟡 Auth Token: \(UserDefaults.standard.string(forKey: "authToken") ?? "none")")
        print("🟡 Current User ID: \(currentUserId ?? "none")")
        
        // Check if we should prevent self-chat
        if let offre = offre, isCurrentUserOfferCreator(offre: offre) && currentChatId == nil {
            errorMessage = "Vous ne pouvez pas chatter avec vous-même"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // If we already have a chat ID (from chat list), use it directly
                if let chatId = currentChatId {
                    print("🟡 Loading existing chat: \(chatId)")
                    let messagesResponse = try await chatService.getChatMessages(chatId: chatId)
                    
                    await MainActor.run {
                        self.messages = self.convertToChatMessages(messagesResponse.messages)
                        self.isLoading = false
                        print("✅ Chat history loaded: \(self.messages.count) messages")
                    }
                } else {
                    // Otherwise, create or get a new chat
                    guard let offre = offre else {
                        throw NSError(domain: "Chat", code: 1, userInfo: [NSLocalizedDescriptionKey: "Offre information missing"])
                    }
                    
                    // 1. EXTRACT ENTREPRISE ID FROM OFFER DATA
                    print("🟡 Step 1: Extracting entreprise ID from offer...")
                    
                    // Debug: Print all available offer data
                    print("🟡 Offer Debug Info:")
                    print("   - Offer ID: \(offre.id)")
                    print("   - Title: \(offre.title)")
                    print("   - Company: \(offre.company)")
                    print("   - UserId: \(offre.userId ?? "nil")")
                    print("   - CreatedBy ID: \(offre.createdBy?.id ?? "nil")")
                    print("   - EntrepriseId (computed): \(offre.entrepriseId ?? "nil")")
                    
                    // Use the computed entrepriseId property
                    guard let entrepriseId = offre.entrepriseId else {
                        let errorMsg = "Cannot find entreprise ID in offer data. Available: userId=\(offre.userId ?? "nil"), createdBy.id=\(offre.createdBy?.id ?? "nil")"
                        print("🔴 \(errorMsg)")
                        throw NSError(domain: "Chat", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                    }
                    
                    print("🟡 Final entreprise ID: \(entrepriseId)")
                    
                    // 2. CREATE OR GET THE CHAT
                    let chatRequest = CreateChatRequest(
                        entreprise: entrepriseId,
                        offer: offre.id
                    )
                    
                    print("🟡 Sending chat request:")
                    print("   - Entreprise: \(entrepriseId)")
                    print("   - Offer: \(offre.id)")
                    
                    let chat = try await chatService.createOrGetChat(chatRequest)
                    currentChatId = chat.id
                    print("✅ Chat created/retrieved: \(chat.id)")
                    
                    // 3. LOAD MESSAGES FOR THIS CHAT
                    print("🟡 Step 2: Loading messages for chat \(chat.id)...")
                    let messagesResponse = try await chatService.getChatMessages(chatId: chat.id)
                    
                    // 4. CONVERT TO UI MESSAGES
                    await MainActor.run {
                        self.messages = self.convertToChatMessages(messagesResponse.messages)
                        self.isLoading = false
                        print("✅ Chat history loaded: \(self.messages.count) messages")
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Erreur lors du chargement du chat: \(error.localizedDescription)"
                    print("🔴 Chat Error: \(error)")
                    
                    // More detailed error information
                    print("🔴 Error details:")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .typeMismatch(let type, let context):
                            print("   - Type mismatch: expected \(type), context: \(context)")
                        case .valueNotFound(let type, let context):
                            print("   - Value not found: \(type), context: \(context)")
                        case .keyNotFound(let key, let context):
                            print("   - Key not found: \(key), context: \(context)")
                        case .dataCorrupted(let context):
                            print("   - Data corrupted: \(context)")
                        @unknown default:
                            print("   - Unknown decoding error")
                        }
                    }
                    
                    if let chatError = error as? ChatError {
                        print("🔴 ChatError: \(chatError.errorDescription ?? "unknown")")
                    }
                    
                    // Load default messages for demo
                    self.loadDefaultMessages()
                }
            }
        }
    }
    
    // MARK: - Message Sending
    
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let text = messageText
        messageText = ""
        
        // If chat not initialized, initialize first
        if currentChatId == nil {
            Task {
                await initializeChatAndSendMessage(text: text)
            }
        } else {
            sendMessageToChat(text: text, chatId: currentChatId!)
        }
    }
    
    private func initializeChatAndSendMessage(text: String) async {
        guard let offre = offre else {
            await MainActor.run {
                self.errorMessage = "Informations de l'offre manquantes"
                self.messageText = text // Restore text
            }
            return
        }
        
        do {
            // Get the entreprise ID from the offer's createdBy field
            guard let entrepriseId = offre.entrepriseId else {
                await MainActor.run {
                    self.errorMessage = "ID de l'entreprise non trouvé"
                    self.messageText = text // Restore text
                }
                return
            }
            
            // Create or get chat first
            let chatRequest = CreateChatRequest(
                entreprise: entrepriseId,
                offer: offre.id
            )
            
            let chat = try await chatService.createOrGetChat(chatRequest)
            
            await MainActor.run {
                self.currentChatId = chat.id
                self.errorMessage = nil
            }
            
            // Now send the message
            sendMessageToChat(text: text, chatId: chat.id)
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Erreur lors de l'initialisation du chat: \(error.localizedDescription)"
                self.messageText = text // Restore text
            }
        }
    }
    
    private func sendMessageToChat(text: String, chatId: String) {
        // Add message locally immediately for better UX
        let newMessage = ChatMessage(
            id: UUID().uuidString,
            text: text,
            isSent: true, // This message is always sent by current user
            timestamp: getCurrentTime(),
            showAvatar: false,
            type: .text,
            mediaUrl: nil,
            duration: nil,
            fileName: nil
        )
        messages.append(newMessage)
        
        // Send message via API
        Task {
            do {
                let request = SendMessageRequest(
                    content: text,
                    type: .text
                )
                
                let sentMessage = try await chatService.sendMessage(chatId: chatId, request)
                print("✅ Message sent successfully: \(sentMessage.content)")
                
            } catch {
                print("🔴 Error sending message: \(error)")
                await MainActor.run {
                    self.errorMessage = "Erreur lors de l'envoi du message"
                    // Remove local message if sending failed
                    if let index = self.messages.firstIndex(where: { $0.text == text && $0.isSent }) {
                        self.messages.remove(at: index)
                    }
                }
            }
        }
    }
    
    // MARK: - Call Management
    
    func initiateCall(isVideoCall: Bool) {
        guard let chatId = currentChatId else {
            errorMessage = "No active chat"
            return
        }
        
        guard let userId = currentUserId else {
            errorMessage = "User not logged in"
            return
        }
        
        // Get user info from offre (or you can add otherUserId/otherUserName properties)
        let toUserId = offre?.userId ?? "unknown_user"
        let toUserName = offre?.company ?? "Company"
        
        // Store for reference (but don't show CallView from ChatView)
        self.isVideoCall = isVideoCall
        // Removed: self.showingCall = true
        // CallCoordinator will handle navigation automatically
        
        // Initiate call via CallManager
        let callManager = CallManager.shared
        
        // Make sure we're connected
        if !callManager.isConnected {
            let userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
            callManager.connect(userId: userId, userName: userName)
        }
        
        // Make the call - CallCoordinator will show CallView automatically
        callManager.makeCall(
            toUserId: toUserId,
            toUserName: toUserName,
            isVideoCall: isVideoCall,
            chatId: chatId
        )
        
        print("📞 Initiating \(isVideoCall ? "video" : "audio") call to \(toUserName)")
    }
    
    func endCall() {
        // Don't set showingCall = false here
        // CallCoordinator handles dismissal
        CallManager.shared.endCall()
    }
    
    // MARK: - Helper Methods
    
    private func convertToChatMessages(_ serviceMessages: [Message]) -> [ChatMessage] {
        // Get current user ID with proper fallback chain
        let currentUserId = (self.currentUserId ?? UserDefaults.standard.string(forKey: "userId") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🟡 Converting \(serviceMessages.count) service messages to UI messages")
        print("🟡 Current User ID for comparison: '\(currentUserId)'")
        
        return serviceMessages.map { message in
            // Get sender ID and trim whitespace
            let senderId = (message.senderId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Determine if message was sent by current user
            let isSentByCurrentUser: Bool
            if currentUserId.isEmpty {
                // If we don't have a current user ID, default to received message (left)
                print("⚠️ Warning: No current user ID available")
                isSentByCurrentUser = false
            } else if senderId.isEmpty {
                // If message doesn't have a sender ID, default to received message (left)
                print("⚠️ Warning: Message \(message.id) has no sender ID")
                isSentByCurrentUser = false
            } else {
                // Compare sender ID with current user ID
                isSentByCurrentUser = senderId == currentUserId
            }
            
            // Format duration if present
            var durationString: String? = nil
            if let duration = message.duration {
                durationString = "\(Int(duration))s"
            }
            
            return ChatMessage(
                id: message.id,
                text: message.content,
                isSent: isSentByCurrentUser,
                timestamp: formatDate(message.createdAt ?? Date()),
                showAvatar: !isSentByCurrentUser, // Show avatar only for received messages
                type: message.type,
                mediaUrl: message.mediaUrl,
                duration: durationString,
                fileName: message.fileName
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func loadDefaultMessages() {
        let defaultMessages = [
            ChatMessage(
                id: UUID().uuidString,
                text: "Bonjour ! Je suis intéressé par le poste \"\(offre?.title ?? "")\".",
                isSent: true, // This should be from current user
                timestamp: getCurrentTime(),
                showAvatar: false,
                type: .text,
                mediaUrl: nil,
                duration: nil,
                fileName: nil
            ),
            ChatMessage(
                id: UUID().uuidString,
                text: "Bonjour ! Merci pour votre intérêt. Comment puis-je vous aider ?",
                isSent: false, // This should be from the other person
                timestamp: getCurrentTime(),
                showAvatar: true,
                type: .text,
                mediaUrl: nil,
                duration: nil,
                fileName: nil
            )
        ]
        
        messages = defaultMessages
    }
    
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    // MARK: - Chat List Helper Methods
    
    func getChatCandidateName(_ chat: ChatModels.GetUserChatsResponse) -> String {
        return chat.candidate?.nom ?? "Candidat inconnu"
    }
    
    func getLastMessagePreview(_ chat: ChatModels.GetUserChatsResponse) -> String {
        return chat.lastMessage ?? "Aucun message"
    }
    
    func getUnreadCount(_ chat: ChatModels.GetUserChatsResponse) -> Int {
        return chat.unreadEntreprise ?? 0
    }
    
    func formatLastActivity(_ isoDate: String?) -> String {
        guard let isoDate = isoDate else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        guard let date = formatter.date(from: isoDate) else { return "" }
        
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "Il y a \(days) j"
        } else if let hours = components.hour, hours > 0 {
            return "Il y a \(hours) h"
        } else if let minutes = components.minute, minutes > 0 {
            return "Il y a \(minutes) min"
        } else {
            return "À l'instant"
        }
    }
    
    // MARK: - Enhanced Chat Features
    
    private func setupAudioObservers() {
        // Observe audio recorder state
        audioRecorder.$isRecording
            .assign(to: &$isRecording)
        
        audioRecorder.$recordingDuration
            .assign(to: &$recordingDuration)
        
        // Observe audio player state
        audioPlayer.$currentlyPlayingId
            .assign(to: &$currentlyPlayingAudioId)
    }
    
    // MARK: - Audio Recording
    
    func startRecording() {
        if audioRecorder.hasPermission {
            do {
                let success = try audioRecorder.startRecording()
                if !success {
                    errorMessage = "Impossible de démarrer l'enregistrement"
                }
            } catch {
                errorMessage = "Erreur d'enregistrement: \(error.localizedDescription)"
            }
        } else {
            // Request permission
            audioRecorder.requestPermission { [weak self] granted in
                if granted {
                    self?.startRecording()
                } else {
                    self?.errorMessage = "Permission microphone requise"
                }
            }
        }
    }
    
    func stopRecordingAndSend() {
        guard let result = audioRecorder.stopRecording() else {
            errorMessage = "Erreur lors de l'arrêt de l'enregistrement"
            return
        }
        
        // Upload and send audio message
        Task {
            do {
                let audioData = try Data(contentsOf: result.url)
                let fileName = result.url.lastPathComponent
                
                // Upload audio file
                let uploadedUrl = try await chatService.uploadChatMedia(
                    audioData,
                    fileName: fileName,
                    mimeType: "audio/m4a"
                )
                
                // Send message
                try await sendMessage(
                    type: .audio,
                    mediaUrl: uploadedUrl,
                    fileName: fileName,
                    duration: "\(Int(result.duration))s"
                )
                
                // Clean up temp file
                try? FileManager.default.removeItem(at: result.url)
                
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur d'envoi: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func cancelRecording() {
        audioRecorder.cancelRecording()
    }
    
    // MARK: - Audio Playback
    
    func playAudio(url audioString: String, messageId: String) {
        var urlToPlay: URL?
        
        if audioString.hasPrefix("http") || audioString.hasPrefix("file://") {
            urlToPlay = URL(string: audioString)
        } else {
            // Relative path - prepend base URL
            // Remove leading slash if present to avoid double slashes
            let cleanPath = audioString.hasPrefix("/") ? String(audioString.dropFirst()) : audioString
            let fullString = "\(APIConfig.baseURL)/\(cleanPath)"
            urlToPlay = URL(string: fullString)
        }
        
        guard let url = urlToPlay else {
            print("❌ Invalid URL string for audio playback: \(audioString)")
            return
        }
        
        print("▶️ Playing audio from URL: \(url.absoluteString)")
        audioPlayer.play(url: url, messageId: messageId)
    }
    
    func stopAudio() {
        audioPlayer.stop()
    }
    
    // MARK: - Media Selection
    
    func removePendingMedia(_ media: PendingMedia) {
        pendingMedia.removeAll { $0.id == media.id }
    }
    
    func sendPendingMedia(_ media: PendingMedia) {
        Task {
            do {
                // Upload media
                let mimeType = media.type == .image ? "image/jpeg" : "video/mp4"
                let uploadedUrl = try await chatService.uploadChatMedia(
                    media.data,
                    fileName: media.fileName,
                    mimeType: mimeType
                )
                
                // Send message
                try await sendMessage(
                    type: media.type,
                    mediaUrl: uploadedUrl,
                    fileName: media.fileName
                )
                
                // Remove from pending
                await MainActor.run {
                    removePendingMedia(media)
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur d'envoi: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func sendAllPendingMedia() {
        let mediaCopy = pendingMedia
        for media in mediaCopy {
            sendPendingMedia(media)
        }
    }
    
    // MARK: - Emoji
    
    func insertEmoji(_ emoji: String) {
        messageText += emoji
    }
    
    func toggleEmojiPicker() {
        showEmojiPicker.toggle()
    }
    
    // MARK: - Enhanced Message Sending
    
    private func sendMessage(
        type: MessageType,
        content: String? = nil,
        mediaUrl: String? = nil,
        fileName: String? = nil,
        duration: String? = nil
    ) async throws {
        guard let chatId = currentChatId else {
            throw NSError(domain: "ChatViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active chat"])
        }
        
        let request = SendMessageRequest(
            content: content ?? "",
            type: type,
            mediaUrl: mediaUrl,
            fileName: fileName,
            fileSize: nil,
            duration: duration,
            thumbnail: nil,
            replyTo: nil
        )
        
        let response = try await chatService.sendMessage(chatId: chatId, request)
        
        // Add message to local list
        await MainActor.run {
            let newMessage = ChatMessage(
                id: response.id,
                text: response.content ?? "",
                isSent: true,
                timestamp: formatDate(response.createdAt ?? Date()),
                showAvatar: false,
                type: response.type,
                mediaUrl: response.mediaUrl,
                duration: response.duration,
                fileName: response.fileName
            )
            messages.append(newMessage)
        }
    }
    
    func sendTextMessage() {
        guard !messageText.isEmpty else { return }
        
        // Detect message type
        let type: MessageType = messageText.isEmojiOnly() ? .emoji : .text
        let content = messageText
        
        Task {
            messageText = "" // Clear immediately
            
            do {
                try await sendMessage(type: type, content: content)
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur d'envoi: \(error.localizedDescription)"
                }
            }
        }
    }
}

