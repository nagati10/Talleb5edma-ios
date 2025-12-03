//
//  OffreDetailView.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import SwiftUI

/// Vue de détail d'une offre d'emploi
/// Affiche toutes les informations d'une offre et permet les actions (like, postuler, etc.)
struct OffreDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    let offre: Offre
    @ObservedObject var viewModel: OffreViewModel
    
    @State private var isLiked = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section avec dégradé
                OffreHeaderSection(offre: offre, isLiked: $isLiked, onBack: { dismiss() }, onLike: {
                    Task {
                        let success = await viewModel.likeOffre(offre.id)
                        if success {
                            // Mettre à jour l'état local basé sur le likeCount mis à jour
                            if let updatedOffre = viewModel.offres.first(where: { $0.id == offre.id }) {
                                isLiked = (updatedOffre.likeCount ?? 0) > (offre.likeCount ?? 0)
                            }
                        }
                    }
                })
                
                // Content Section
                ScrollView {
                    VStack(spacing: 24) {
                        OffreDetailsSection(offre: offre)
                        OffreDescriptionSection(offre: offre)
                        if let exigences = offre.exigences, !exigences.isEmpty {
                            OffrePrerequisitesSection(exigences: exigences)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
            }
            
            // Bottom Action Buttons
            OffreBottomActionButtons(offre: offre)
                .environmentObject(authService)
                .padding(.horizontal)
                .padding(.bottom, 16)
                .background(AppColors.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Vérifier si l'offre est aimée (basé sur likeCount)
            isLiked = (offre.likeCount ?? 0) > 0
        }
    }
}

// MARK: - Header Section

struct OffreHeaderSection: View {
    let offre: Offre
    @Binding var isLiked: Bool
    let onBack: () -> Void
    let onLike: () -> Void
    
    var body: some View {
        ZStack {
            // Dégradé rouge-rose
            LinearGradient(
                gradient: Gradient(colors: [AppColors.primaryRed, AppColors.accentPink]),
                startPoint: .leading,
                endPoint: .trailing
            )
            
            VStack(spacing: 0) {
                // Navigation en haut
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Détails de l'offre")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: onLike) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { /* Partager */ }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Contenu principal avec icône, titre et tags
                HStack(alignment: .top, spacing: 16) {
                    // Icône carrée blanche
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(AppColors.primaryRed)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Titre
                        Text(offre.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        // Entreprise
                        Text(offre.company)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                        
                        // Tags
                        HStack(spacing: 8) {
                            if let salary = offre.salary {
                                OffreTag(text: salary)
                            }
                            if let jobType = offre.jobType {
                                OffreTag(text: jobType)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .frame(height: 240)
    }
}

struct OffreTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.primaryRed.opacity(0.8))
            .cornerRadius(12)
    }
}

// MARK: - Offre Details Section

struct OffreDetailsSection: View {
    let offre: Offre
    
    var body: some View {
        GenericCard {
            VStack(spacing: 16) {
                // Première ligne
                HStack(spacing: 20) {
                    OffreDetailRow(
                        icon: "location.fill",
                        label: "Localisation",
                        value: offre.location.address
                    )
                    
                    if let city = offre.location.city {
                        OffreDetailRow(
                            icon: "map.fill",
                            label: "Ville",
                            value: city
                        )
                    }
                }
                
                Divider()
                    .background(AppColors.separatorGray)
                
                // Deuxième ligne
                HStack(spacing: 20) {
                    if let salary = offre.salary {
                        OffreDetailRow(
                            icon: "briefcase.fill",
                            label: "Salaire",
                            value: salary
                        )
                    }
                    
                    if let expiresAt = offre.expiresAt {
                        OffreDetailRow(
                            icon: "calendar",
                            label: "Expire le",
                            value: formatDate(expiresAt)
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
}

struct OffreDetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primaryRed)
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mediumGray)
            }
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Offre Description Section

struct OffreDescriptionSection: View {
    let offre: Offre
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description du poste")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.black)
            
            Text(offre.description)
                .font(.system(size: 14))
                .foregroundColor(AppColors.black)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Prerequisites Section

struct OffrePrerequisitesSection: View {
    let exigences: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prérequis")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.black)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(exigences, id: \.self) { exigence in
                    OffrePrerequisiteItem(text: exigence)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct OffrePrerequisiteItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppColors.primaryRed)
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(AppColors.black)
        }
    }
}

// MARK: - Chat Navigation Helper

struct ChatToNavigate: Identifiable {
    let id: String  // This is the chatId
    let offer: Offre?
}

// MARK: - Bottom Action Buttons

struct OffreBottomActionButtons: View {
    let offre: Offre
    @EnvironmentObject var authService: AuthService
    @State private var showingMoreInfo = false
    @State private var showingApply = false
    
    // Chat list popup state for organizations
    @State private var showChatListPopup = false
    @State private var userChats: [ChatModels.GetUserChatsResponse] = []
    @State private var isLoadingChats = false
    @State private var chatLoadError: String?
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { showingMoreInfo = true }) {
                Text("Plus d'infos")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryRed)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.primaryRed, lineWidth: 2)
                    )
                    .cornerRadius(12)
            }
            .sheet(isPresented: $showingMoreInfo) {
                // Plus d'informations
                Text("Plus d'informations")
            }
            
            Button(action: {
                // Check if current user owns this offer
                let isOwner = offre.entrepriseId == authService.currentUser?.id
                
                if isOwner {
                    // Organization: Show chat list
                    loadUserChats()
                } else {
                    // Candidate: Open chat directly
                    showingApply = true
                }
            }) {
                Text("Discuter")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.primaryRed, AppColors.accentPink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .sheet(isPresented: $showingApply) {
                ChatView(
                    offre: offre,
                    currentUserId: authService.currentUser?.id ?? UserDefaults.standard.string(forKey: "userId")
                )
                .environmentObject(authService)
            }
            .sheet(isPresented: $showChatListPopup) {
                ChatListPopup(
                    chats: userChats,
                    loading: isLoadingChats,
                    error: chatLoadError,
                    offer: offre,
                    onDismiss: {
                        showChatListPopup = false
                    }
                )
                .environmentObject(authService)
            }
        }
        .padding(.horizontal)
    }
    
    // Load chats for organization's offer
    private func loadUserChats() {
        guard authService.authToken != nil else {
            chatLoadError = "Non authentifié"
            showChatListPopup = true
            return
        }
        
        // Show popup with loading state immediately
        isLoadingChats = true
        chatLoadError = nil
        showChatListPopup = true
        
        Task {
            do {
                let chatService = ChatService()
                // ChatService reads token from UserDefaults automatically
                
                let allChats = try await chatService.getMyChatsDetailed()
                
                // Filter chats by this offer ID
                let filteredChats = allChats.filter { chat in
                    chat.offer?.id == offre.id
                }
                
                await MainActor.run {
                    self.userChats = filteredChats
                    self.isLoadingChats = false
                }
                
                print("✅ Loaded \(filteredChats.count) chats for offer: \(offre.id)")
            } catch {
                await MainActor.run {
                    self.chatLoadError = "Erreur: \(error.localizedDescription)"
                    self.isLoadingChats = false
                }
                print("❌ Error loading chats: \(error)")
            }
        }
    }
}

// MARK: - Chat List Popup for Organizations

struct ChatListPopup: View {
    let chats: [ChatModels.GetUserChatsResponse]
    let loading: Bool
    let error: String?
    let offer: Offre?
    let onDismiss: () -> Void
    
    @EnvironmentObject var authService: AuthService
    @State private var chatToNavigate: ChatToNavigate? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGray.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Conversations")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppColors.black)
                            
                            Spacer()
                            
                            Button(action: onDismiss) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.mediumGray)
                            }
                        }
                        
                        if let offerTitle = offer?.title {
                            Text(offerTitle)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mediumGray)
                                .lineLimit(1)
                        }
                    }
                    .padding()
                    .background(AppColors.white)
                    
                    Divider()
                    
                    // Content
                    if loading {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Chargement des conversations...")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mediumGray)
                        }
                        Spacer()
                    } else if let error = error {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.primaryRed)
                            Text("Erreur")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppColors.black)
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mediumGray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Button(action: onDismiss) {
                                Text("Fermer")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(AppColors.primaryRed)
                                    .cornerRadius(12)
                            }
                        }
                        Spacer()
                    } else if chats.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.mediumGray)
                            Text("Aucune conversation")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppColors.black)
                            Text("Aucune conversation pour cette offre")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mediumGray)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(chats, id: \.id) { chat in
                                    OffreDetailChatItem(chat: chat, onTap: {
                                        print("🟦 Chat item tapped: \(chat.id)")
                                        print("🟦 Candidate: \(chat.candidate?.nom ?? "unknown")")
                                        print("🟦 Offer: \(chat.offer?.id ?? "unknown")")
                                        // Set navigation target as single state update
                                        chatToNavigate = ChatToNavigate(id: chat.id, offer: offer)
                                        print("🟦 Navigation state set: chatToNavigate.id=\(chatToNavigate?.id ?? "nil")")
                                    })
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $chatToNavigate) { chatInfo in
                // Find the full chat info to get candidate details
                let chatDetails = chats.first(where: { $0.id == chatInfo.id })
                ChatView(
                    offre: chatInfo.offer,
                    currentUserId: authService.currentUser?.id ?? UserDefaults.standard.string(forKey: "userId"),
                    chatId: chatInfo.id,
                    candidateInfo: chatDetails?.candidate
                )
                .environmentObject(authService)
            }
        }
    }
}

// MARK: - Offre Detail Chat Item (renamed to avoid conflict)

struct OffreDetailChatItem: View {
    let chat: ChatModels.GetUserChatsResponse
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Candidate Avatar with unread badge
            ZStack(alignment: .topTrailing) {
                if let imageUrl = chat.candidate?.image, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: "\(APIConfig.baseURL)/\(imageUrl)")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(AppColors.mediumGray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(AppColors.mediumGray)
                            )
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(AppColors.mediumGray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(AppColors.mediumGray)
                        )
                }
                
                // Unread badge
                if let unreadCount = chat.unreadEntreprise, unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryRed)
                            .frame(width: 20, height: 20)
                        Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 5, y: -5)
                }
            }
            
            // Chat Info
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.candidate?.nom ?? "Candidat inconnu")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.black)
                    .lineLimit(1)
                
                if let lastMessage = chat.lastMessage, !lastMessage.isEmpty {
                    Text(lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mediumGray)
                        .lineLimit(1)
                } else {
                    Text("Aucun message")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mediumGray.opacity(0.5))
                        .italic()
                }
                
                if let lastActivity = chat.lastActivity {
                    Text(formatLastActivity(lastActivity))
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mediumGray.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Message type indicator
            if let messageType = chat.lastMessageType {
                Image(systemName: getMessageTypeIcon(messageType))
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.mediumGray)
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Helper Functions

/// Formats ISO8601 date string to relative time (e.g., "Il y a 2h")
private func formatLastActivity(_ isoDate: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    guard let date = formatter.date(from: isoDate) else {
        // Try alternative format without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: isoDate) else {
            return ""
        }
        return formatRelativeTime(from: date)
    }
    
    return formatRelativeTime(from: date)
}

private func formatRelativeTime(from date: Date) -> String {
    let now = Date()
    let difference = now.timeIntervalSince(date)
    
    let minutes = Int(difference / 60)
    let hours = Int(difference / 3600)
    let days = Int(difference / 86400)
    
    if minutes < 1 {
        return "À l'instant"
    } else if minutes < 60 {
        return "Il y a \(minutes) min"
    } else if hours < 24 {
        return "Il y a \(hours) h"
    } else if days < 7 {
        return "Il y a \(days) j"
    } else {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        return dateFormatter.string(from: date)
    }
}

/// Returns SF Symbol name for message type
private func getMessageTypeIcon(_ type: String) -> String {
    switch type.lowercased() {
    case "text":
        return "text.bubble"
    case "image":
        return "photo"
    case "video":
        return "video.fill"
    case "audio":
        return "mic.fill"
    case "emoji":
        return "face.smiling"
    default:
        return "bubble.left"
    }
}

#Preview {
    OffreDetailView(
        offre: Offre(
            id: "1",
            title: "Développeur Web Junior",
            description: "Nous recherchons un développeur web junior passionné pour rejoindre notre équipe dynamique.",
            tags: ["CDI", "Télétravail"],
            exigences: ["JavaScript", "React", "HTML/CSS"],
            location: OffreLocation(
                address: "123 Rue de la République",
                city: "Tunis",
                country: "Tunisie",
                coordinates: Coordinates(lat: 36.8065, lng: 10.1815)
            ),
            category: "Informatique",
            salary: "500-800 DT/mois",
            company: "TechCorp",
            expiresAt: "2025-12-31",
            jobType: "job",
            shift: "jour",
            isActive: true,
            images: nil,
            viewCount: 10,
            likeCount: 5,
            userId: nil,
            createdAt: nil,
            updatedAt: nil
        ),
        viewModel: OffreViewModel()
    )
}

