//
//  ChatView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI
import UIKit

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ChatViewModel
    let offre: Offre?
    let currentUserId: String?  // Add current user ID
    let chatId: String?  // Optional chat ID to load specific chat
    let candidateInfo: ChatModels.ChatUser?  // Optional candidate info for displaying profile
    
    // Media viewer state
    @State private var showMediaViewer = false
    @State private var selectedMediaUrl: String?
    @State private var selectedMediaType: MediaViewerSheet.MediaType = .image
    
    init(offre: Offre? = nil, currentUserId: String? = nil, chatId: String? = nil, candidateInfo: ChatModels.ChatUser? = nil) {
        self.offre = offre
        self.currentUserId = currentUserId
        self.chatId = chatId
        self.candidateInfo = candidateInfo
        self._viewModel = StateObject(wrappedValue: ChatViewModel(offre: offre, currentUserId: currentUserId))
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGray.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                ChatTopBar(
                    companyName: getChatTitle(),
                    candidateInfo: candidateInfo,
                    onBack: { dismiss() },
                    onCall: { viewModel.initiateCall(isVideoCall: false) },
                    onVideoCall: { viewModel.initiateCall(isVideoCall: true) }
                )
                
                // Messages or Chat List
                if viewModel.showChatList {
                    ChatListView(
                        chats: viewModel.userChats,
                        offerTitle: offre?.title,
                        onChatSelected: { chatId in
                            viewModel.selectChat(chatId)
                        },
                        onDismiss: {
                            viewModel.showChatList = false
                            dismiss()
                        }
                    )
                } else {
                    // Normal chat messages
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryRed))
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.primaryRed)
                            Text(error)
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.mediumGray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Réessayer") {
                                viewModel.initializeChat()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(AppColors.primaryRed)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        Spacer()
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.messages) { message in
                                        switch message.type {
                                        case .text:
                                            ChatMessageView(message: message)
                                                .id(message.id)
                                        case .audio:
                                            AudioMessageView(
                                                message: Message(
                                                    id: message.id,
                                                    chatId: nil,
                                                    senderId: nil,
                                                    content: message.text,
                                                    type: .audio,
                                                    mediaUrl: message.mediaUrl,
                                                    fileName: message.fileName,
                                                    duration: message.duration
                                                ),
                                                isSent: message.isSent,
                                                isPlaying: viewModel.currentlyPlayingAudioId == message.id,
                                                onPlayTapped: { viewModel.playAudio(url: message.mediaUrl ?? "", messageId: message.id) },
                                                onStopTapped: { viewModel.stopAudio() }
                                            )
                                            .id(message.id)
                                        case .image:
                                            ImageMessageView(
                                                message: Message(
                                                    id: message.id,
                                                    chatId: nil,
                                                    senderId: nil,
                                                    content: nil,
                                                    type: .image,
                                                    mediaUrl: message.mediaUrl
                                                ),
                                                isSent: message.isSent,
                                                onTap: {
                                                    selectedMediaUrl = message.mediaUrl
                                                    selectedMediaType = .image
                                                    showMediaViewer = true
                                                }
                                            )
                                            .id(message.id)
                                        case .video:
                                            VideoMessageView(
                                                message: Message(
                                                    id: message.id,
                                                    chatId: nil,
                                                    senderId: nil,
                                                    content: nil,
                                                    type: .video,
                                                    mediaUrl: message.mediaUrl,
                                                    duration: message.duration
                                                ),
                                                isSent: message.isSent,
                                                onTap: {
                                                    selectedMediaUrl = message.mediaUrl
                                                    selectedMediaType = .video
                                                    showMediaViewer = true
                                                }
                                            )
                                            .id(message.id)
                                        case .emoji:
                                            EmojiMessageView(
                                                message: Message(
                                                    id: message.id,
                                                    chatId: nil,
                                                    senderId: nil,
                                                    content: message.text,
                                                    type: .emoji
                                                ),
                                                isSent: message.isSent
                                            )
                                            .id(message.id)
                                        default:
                                            ChatMessageView(message: message)
                                                .id(message.id)
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 16)
                            }
                            .onChange(of: viewModel.messages.count) { _, _ in
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        
                        // Input Bar
                        ChatInputBar(viewModel: viewModel)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        // Removed .fullScreenCover for CallView - CallCoordinator handles navigation globally
        .fullScreenCover(isPresented: $showMediaViewer) {
            if let mediaUrl = selectedMediaUrl {
                MediaViewerSheet(
                    mediaUrl: mediaUrl,
                    mediaType: selectedMediaType
                )
            }
        }
        .onAppear {
            // If chatId is provided, select that specific chat
            if let chatId = chatId {
                print("📱 ChatView: Loading specific chat: \(chatId)")
                viewModel.selectChat(chatId)
            } else {
                // Otherwise, use normal initialization (create/get chat)
                viewModel.initializeChat()
            }
        }
    }
    
    private func getChatTitle() -> String {
        if viewModel.showChatList {
            return offre?.company ?? "Mes Conversations"
        } else {
            return offre?.company ?? "Employeur"
        }
    }
}

// MARK: - Chat List View

struct ChatListView: View {
    let chats: [ChatModels.GetUserChatsResponse]
    let offerTitle: String?
    let onChatSelected: (String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppColors.white)
                        .frame(width: 24, height: 24)
                }
                
                Spacer()
                
                Text("Conversations - \(offerTitle ?? "Cette offre")")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.white)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Invisible spacer for balance
                Image(systemName: "chevron.left")
                    .foregroundColor(.clear)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.primaryRed, AppColors.accentPink]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Chat List Content
            if chats.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.mediumGray)
                    
                    Text("Aucune conversation pour cette offre")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.mediumGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("Les candidats apparaîtront ici lorsqu'ils enverront des messages")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mediumGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chats, id: \.id) { chat in
                            ChatListItemView(chat: chat) {
                                onChatSelected(chat.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
    }
}

// MARK: - Chat List Item View

struct ChatListItemView: View {
    let chat: ChatModels.GetUserChatsResponse
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Candidate Avatar
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(AppColors.mediumGray)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(AppColors.white)
                        )
                    
                    // Unread badge
                    if let unreadCount = chat.unreadEntreprise, unreadCount > 0 {
                        Circle()
                            .fill(AppColors.primaryRed)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\(min(unreadCount, 9))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 5, y: -5)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.candidate?.nom ?? "Candidat inconnu")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.black)
                        .lineLimit(1)
                    
                    Text(chat.lastMessage ?? "Aucun message")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mediumGray)
                        .lineLimit(1)
                    
                    if let lastActivity = chat.lastActivity {
                        Text(formatLastActivity(lastActivity))
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.mediumGray)
                    }
                }
                
                Spacer()
                
                // Message type indicator
                if let messageType = chat.lastMessageType {
                    Image(systemName: getMessageTypeIcon(messageType))
                        .foregroundColor(AppColors.mediumGray)
                        .font(.system(size: 16))
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.mediumGray)
                    .font(.system(size: 14))
            }
            .padding(16)
            .background(AppColors.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getMessageTypeIcon(_ messageType: String) -> String {
        switch messageType {
        case "image": return "photo"
        case "video": return "video"
        case "audio": return "mic"
        case "emoji": return "face.smiling"
        default: return "text.bubble"
        }
    }
    
    private func formatLastActivity(_ isoDate: String) -> String {
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
}

// MARK: - Chat Message View

struct ChatMessage: Identifiable {
    let id: String
    let text: String
    let isSent: Bool
    let timestamp: String
    let showAvatar: Bool
    let type: MessageType
    let mediaUrl: String?
    let duration: String?
    let fileName: String?
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isSent && message.showAvatar {
                Circle()
                    .fill(AppColors.mediumGray)
                    .frame(width: 28, height: 28)
            } else if !message.isSent {
                Spacer().frame(width: 28)
            }
            
            VStack(alignment: message.isSent ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundColor(message.isSent ? AppColors.white : AppColors.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isSent ? AppColors.primaryRed : AppColors.lightGray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                
                Text(message.timestamp)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mediumGray)
            }
            .frame(maxWidth: .infinity, alignment: message.isSent ? .trailing : .leading)
            
            if message.isSent {
                Spacer().frame(width: 28)
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Chat Top Bar

struct ChatTopBar: View {
    let companyName: String
    let candidateInfo: ChatModels.ChatUser?
    let onBack: () -> Void
    let onCall: () -> Void
    let onVideoCall: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppColors.white)
                    .frame(width: 24, height: 24)
            }
            
            // Display candidate photo if available
            if let imageUrl = candidateInfo?.image, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: "\(APIConfig.baseURL)/\(imageUrl)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(AppColors.mediumGray)
                        .frame(width: 40, height: 40)
                }
            } else {
                Circle()
                    .fill(AppColors.mediumGray)
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading) {
                Text(candidateInfo?.nom ?? companyName)
                    .font(.headline)
                    .foregroundColor(AppColors.white)
                
                Text("En ligne")
                    .font(.subheadline)
                    .foregroundColor(AppColors.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: onCall) {
                Image(systemName: "phone")
                    .foregroundColor(AppColors.white)
                    .frame(width: 44, height: 44)
            }
            
            Button(action: onVideoCall) {
                Image(systemName: "video")
                    .foregroundColor(AppColors.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [AppColors.primaryRed, AppColors.accentPink]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Emoji Picker
            if viewModel.showEmojiPicker {
                EmojiPickerView(
                    selectedCategory: $viewModel.selectedEmojiCategory,
                    onEmojiSelected: { viewModel.insertEmoji($0) }
                )
                .frame(height: 250)
                .transition(.move(edge: .bottom))
            }
            
            // Pending Media
            if !viewModel.pendingMedia.isEmpty {
                PendingMediaRow(
                    media: viewModel.pendingMedia,
                    onRemove: { viewModel.removePendingMedia($0) },
                    onSendAll: { viewModel.sendAllPendingMedia() }
                )
            }
            
            // Input Area
            HStack(spacing: 12) {
                // Emoji Button
                Button(action: { 
                    withAnimation {
                        viewModel.toggleEmojiPicker()
                    }
                }) {
                    Image(systemName: "face.smiling")
                        .foregroundColor(viewModel.showEmojiPicker ? AppColors.primaryRed : AppColors.mediumGray)
                        .font(.title2)
                }
                
                // Attachment Button
                Button(action: { viewModel.showMediaPicker = true }) {
                    Image(systemName: "paperclip")
                        .foregroundColor(AppColors.mediumGray)
                        .font(.title2)
                }
                
                // Text Field
                TextField("Message...", text: $viewModel.messageText)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(AppColors.lightGray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .onSubmit { viewModel.sendTextMessage() }
                
                // Send / Mic Button
                if !viewModel.messageText.isEmpty {
                    Button(action: { viewModel.sendTextMessage() }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(AppColors.primaryRed)
                            .font(.title2)
                    }
                } else if viewModel.isRecording {
                    // Recording State
                    HStack {
                        Text(String(format: "%.0fs", viewModel.recordingDuration))
                            .foregroundColor(AppColors.primaryRed)
                            .font(.system(size: 14, weight: .bold))
                            
                        Button(action: { viewModel.stopRecordingAndSend() }) {
                            Image(systemName: "stop.circle.fill")
                                .foregroundColor(AppColors.primaryRed)
                                .font(.title2)
                        }
                    }
                } else {
                    // Mic Button
                    Button(action: { viewModel.startRecording() }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(AppColors.mediumGray)
                            .font(.title2)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.white)
        }
        .sheet(isPresented: $viewModel.showMediaPicker) {
            MediaPickerView(selectedMedia: $viewModel.pendingMedia)
        }
    }
}

// MARK: - Pending Media Row

struct PendingMediaRow: View {
    let media: [PendingMedia]
    let onRemove: (PendingMedia) -> Void
    let onSendAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(media.count) fichier(s) sélectionné(s)")
                    .font(.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                Spacer()
                
                Button(action: onSendAll) {
                    Text("Envoyer tout")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryRed)
                }
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(media) { item in
                        ZStack(alignment: .topTrailing) {
                            if item.type == .image, let image = UIImage(data: item.data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                            } else if item.type == .video {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.black)
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                    
                                    Image(systemName: "video.fill")
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Button(action: { onRemove(item) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .offset(x: 5, y: -5)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .background(AppColors.white)
    }
}

// MARK: - Chat Call View

struct ChatCallView: View {
    let isVideoCall: Bool
    let companyName: String
    let onEndCall: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [AppColors.primaryRed, AppColors.accentPink]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // En-tête
                HStack {
                    Button(action: {
                        onEndCall()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Text(isVideoCall ? "Appel Vidéo" : "Appel Audio")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "xmark")
                        .foregroundColor(.clear)
                        .font(.title2)
                }
                .padding()
                
                // Avatar/Image
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.7))
                    )
                
                // Informations de l'appel
                VStack(spacing: 8) {
                    Text(companyName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(isVideoCall ? "Appel vidéo en cours..." : "Appel audio en cours...")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("00:45")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                }
                
                Spacer()
                
                // Contrôles d'appel
                HStack(spacing: 30) {
                    Button(action: { /* Micro */ }) {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "mic.slash")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Button(action: {
                        onEndCall()
                        dismiss()
                    }) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "phone.down.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Button(action: { /* Haut-parleur */ }) {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    ChatView(offre: Offre(
        id: "1",
        title: "Développeur iOS",
        description: "Développement d'applications mobiles iOS avec SwiftUI",
        tags: ["Swift", "iOS", "Mobile"],
        exigences: ["SwiftUI", "UIKit", "API REST"],
        location: OffreLocation(
            address: "123 Rue de la Tech",
            city: "Tunis",
            country: "Tunisie",
            coordinates: Coordinates(lat: 36.8, lng: 10.1)
        ),
        salary: "2000-3000 DT",
        company: "TechCorp",
        expiresAt: "2025-12-31",
        jobType: "CDI",
        shift: "Temps plein",
        isActive: true,
        images: nil,
        viewCount: 150,
        likeCount: 25,
        userId: "user123",
        createdAt: nil,
        updatedAt: nil
    ))
}
