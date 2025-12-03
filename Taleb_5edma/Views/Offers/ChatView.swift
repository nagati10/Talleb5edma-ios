//
//  ChatView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ChatViewModel
    let offre: Offre?
    
    init(offre: Offre? = nil) {
        self.offre = offre
        self._viewModel = StateObject(wrappedValue: ChatViewModel(offre: offre))
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGray.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                ChatTopBar(
                    companyName: offre?.company ?? "Employeur",
                    onBack: { dismiss() },
                    onCall: { viewModel.initiateCall(isVideoCall: false) },
                    onVideoCall: { viewModel.initiateCall(isVideoCall: true) }
                )
                
                // Messages
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
                            viewModel.loadChatHistory()
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
                                    ChatMessageView(message: message)
                                        .id(message.id)
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
                }
                
                // Input Bar
                ChatInputBar(
                    text: $viewModel.messageText,
                    onSend: { viewModel.sendMessage() }
                )
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingCall) {
            ChatCallView(
                isVideoCall: viewModel.isVideoCall,
                companyName: offre?.company ?? "Employeur",
                onEndCall: { viewModel.endCall() }
            )
        }
        .onAppear {
            viewModel.loadChatHistory()
        }
    }
}

// MARK: - Chat Message View

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isSent: Bool
    let timestamp: String
    let showAvatar: Bool
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

struct ChatTopBar: View {
    let companyName: String
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
            
            Circle()
                .fill(AppColors.mediumGray)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(companyName)
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

struct ChatInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { /* Ajouter */ }) {
                Image(systemName: "plus.circle")
                    .foregroundColor(AppColors.primaryRed)
                    .font(.title2)
            }
            
            Button(action: { /* Camera */ }) {
                Image(systemName: "camera")
                    .foregroundColor(AppColors.primaryRed)
                    .font(.title2)
            }
            
            Button(action: { /* Micro */ }) {
                Image(systemName: "mic")
                    .foregroundColor(AppColors.primaryRed)
                    .font(.title2)
            }
            
            TextField("Aa", text: $text)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(AppColors.lightGray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .onSubmit(onSend)
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(AppColors.primaryRed)
                    .font(.title2)
            }
            
            Button(action: { /* Like */ }) {
                Image(systemName: "hand.thumbsup")
                    .foregroundColor(AppColors.primaryRed)
                    .font(.title2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppColors.white)
    }
}

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
