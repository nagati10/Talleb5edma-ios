//
//  AudioMessageView.swift
//  Taleb_5edma
//
//  Created by Enhanced Chat Features
//

import SwiftUI

/// View for displaying audio message bubbles
struct AudioMessageView: View {
    let message: Message
    let isSent: Bool
    let isPlaying: Bool
    let onPlayTapped: () -> Void
    let onStopTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            if isSent {
                Spacer()
            }
            
            HStack(alignment: .center, spacing: 12) {
                // Play/Pause button (left for received, right for sent)
                if !isSent {
                    playPauseButton
                }
                
                // Duration text
                Text(formatDuration(message.duration))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSent ? .white : AppColors.black)
                
                // Waveform visualization
                waveformBars
                
                // Play/Pause button for sent messages
                if isSent {
                    playPauseButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSent ? AppColors.primaryRed : Color(hex: "F5F5F5"))
            .cornerRadius(20)
            
            if !isSent {
                Spacer()
            }
        }
    }
    
    private var playPauseButton: some View {
        Button(action: {
            if isPlaying {
                onStopTapped()
            } else {
                onPlayTapped()
            }
        }) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 16))
                .foregroundColor(isSent ? .white : AppColors.primaryRed)
                .frame(width: 24, height: 24)
        }
    }
    
    private var waveformBars: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSent ? Color.white : AppColors.primaryRed)
                    .frame(width: 3, height: CGFloat(10 + index * 4))
            }
        }
    }
    
    private func formatDuration(_ duration: String?) -> String {
        guard let duration = duration else { return "0:00" }
        // Duration might be in format "10s" or "0:10"
        if duration.hasSuffix("s") {
            let seconds = Int(duration.dropLast()) ?? 0
            let mins = seconds / 60
            let secs = seconds % 60
            return String(format: "%d:%02d", mins, secs)
        }
        return duration
    }
}

#Preview {
    VStack(spacing: 16) {
        // Sent audio message
        AudioMessageView(
            message: Message(
                id: "1",
                chatId: "chat1",
                senderId: "user1",
                content: "Voice message",
                type: .audio,
                mediaUrl: "audio.m4a",
                fileName: "voice.m4a",
                fileSize: nil,
                duration: "15s",
                thumbnail: nil,
                replyTo: nil,
                isRead: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            isSent: true,
            isPlaying: false,
            onPlayTapped: {},
            onStopTapped: {}
        )
        
        // Received audio message
        AudioMessageView(
            message: Message(
                id: "2",
                chatId: "chat1",
                senderId: "user2",
                content: "Voice message",
                type: .audio,
                mediaUrl: "audio.m4a",
                fileName: "voice.m4a",
                fileSize: nil,
                duration: "25s",
                thumbnail: nil,
                replyTo: nil,
                isRead: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            isSent: false,
            isPlaying: true,
            onPlayTapped: {},
            onStopTapped: {}
        )
    }
    .padding()
}
