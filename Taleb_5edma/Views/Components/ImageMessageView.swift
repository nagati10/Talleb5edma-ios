//
//  ImageMessageView.swift
//  Taleb_5edma
//
//  Created by Enhanced Chat Features
//

import SwiftUI

/// View for displaying image messages
struct ImageMessageView: View {
    let message: Message
    let isSent: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            if isSent {
                Spacer()
            }
            
            VStack(alignment: isSent ? .trailing : .leading, spacing: 4) {
                if let mediaUrl = message.mediaUrl {
                    let imageUrl = buildImageURL(from: mediaUrl)
                    
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                ProgressView()
                            }
                            .frame(width: 250, height: 200)
                            .cornerRadius(12)
                            
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 250, height: 200)
                                .clipped()
                                .cornerRadius(12)
                                .onTapGesture {
                                    onTap()
                                }
                            
                        case .failure:
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 250, height: 200)
                            .cornerRadius(12)
                            
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 250, height: 200)
                    .cornerRadius(12)
                }
            }
            
            if !isSent {
                Spacer()
            }
        }
    }
    
    private func buildImageURL(from urlString: String) -> String {
        if urlString.starts(with: "http") {
            return urlString
        } else if urlString.starts(with: "/") {
            return APIConfig.baseURL + urlString
        } else if urlString.starts(with: "uploads/") {
            return APIConfig.baseURL + "/" + urlString
        } else {
            return APIConfig.baseURL + "/" + urlString
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ImageMessageView(
            message: Message(
                id: "1",
                chatId: "chat1",
                senderId: "user1",
                content: nil,
                type: .image,
                mediaUrl: "uploads/chat/image.jpg",
                fileName: "image.jpg",
                fileSize: nil,
                duration: nil,
                thumbnail: nil,
                replyTo: nil,
                isRead: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            isSent: true,
            onTap: {}
        )
        
        ImageMessageView(
            message: Message(
                id: "2",
                chatId: "chat1",
                senderId: "user2",
                content: nil,
                type: .image,
                mediaUrl: "uploads/chat/image2.jpg",
                fileName: "image2.jpg",
                fileSize: nil,
                duration: nil,
                thumbnail: nil,
                replyTo: nil,
                isRead: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            isSent: false,
            onTap: {}
        )
    }
    .padding()
}
