//
//  EmojiMessageView.swift
//  Taleb_5edma
//
//  Created by Enhanced Chat Features
//

import SwiftUI

/// View for displaying emoji-only messages (large size, no bubble)
struct EmojiMessageView: View {
    let message: Message
    let isSent: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            if isSent {
                Spacer()
            }
            
            Text(message.content ?? "")
                .font(.system(size: 48)) // Large emoji display
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            if !isSent {
                Spacer()
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        EmojiMessageView(
            message: Message(
                id: "1",
                chatId: "chat1",
                senderId: "user1",
                content: "😀👍",
                type: .emoji,
                mediaUrl: nil,
                fileName: nil,
                fileSize: nil,
                duration: nil,
                thumbnail: nil,
                replyTo: nil,
                isRead: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            isSent: true
        )
        
        EmojiMessageView(
            message: Message(
                id: "2",
                chatId: "chat1",
                senderId: "user2",
                content: "❤️🎉",
                type: .emoji,
                mediaUrl: nil,
                fileName: nil,
                fileSize: nil,
                duration: nil,
                thumbnail: nil,
                replyTo: nil,
                isRead: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            isSent: false
        )
    }
    .padding()
}
