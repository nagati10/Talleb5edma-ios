//
//  VideoMessageView.swift
//  Taleb_5edma
//
//  Created by Enhanced Chat Features
//

import SwiftUI

/// View for displaying video messages
struct VideoMessageView: View {
    let message: Message
    let isSent: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            if isSent {
                Spacer()
            }
            
            ZStack {
                // Black background
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 250, height: 150)
                    .cornerRadius(12)
                
                // Play icon overlay
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .onTapGesture {
                onTap()
            }
            
            if !isSent {
                Spacer()
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        VideoMessageView(
            message: Message(
                id: "1",
                chatId: "chat1",
                senderId: "user1",
                content: nil,
                type: .video,
                mediaUrl: "uploads/chat/video.mp4",
                fileName: "video.mp4",
                fileSize: nil,
                duration: "30s",
                thumbnail: nil,
                replyTo: nil,
                isRead: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            isSent: true,
            onTap: {}
        )
        
        VideoMessageView(
            message: Message(
                id: "2",
                chatId: "chat1",
                senderId: "user2",
                content: nil,
                type: .video,
                mediaUrl: "uploads/chat/video2.mp4",
                fileName: "video2.mp4",
                fileSize: nil,
                duration: "45s",
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
