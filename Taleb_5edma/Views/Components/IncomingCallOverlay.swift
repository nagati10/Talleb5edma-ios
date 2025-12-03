//
//  IncomingCallOverlay.swift
//  Taleb_5edma
//
//  Global overlay for incoming call notifications
//

import SwiftUI

struct IncomingCallOverlay: View {
    let callData: CallData
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // Call notification card
            VStack(spacing: 24) {
                // Caller info
                VStack(spacing: 16) {
                    // Avatar
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(callData.fromUserName.prefix(2).uppercased())
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    // Name
                    Text(callData.fromUserName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Call type
                    HStack(spacing: 8) {
                        Image(systemName: callData.isVideoCall ? "video.fill" : "phone.fill")
                            .font(.system(size: 16))
                        Text(callData.isVideoCall ? "Video Call" : "Voice Call")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 32)
                
                // Action buttons
                HStack(spacing: 40) {
                    // Decline button
                    Button(action: onReject) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: 0xFF3B30))
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Decline")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Accept button
                    Button(action: onAccept) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: 0x34C759))
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Accept")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.15))
            )
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    IncomingCallOverlay(
        callData: CallData(
            callId: "test123",
            roomId: "room123",
            fromUserId: "user456",
            fromUserName: "John Doe",
            toUserId: "currentUser",
            isVideoCall: true,
            chatId: "chat789",
            timestamp: ISO8601DateFormatter().string(from: Date())
        ),
        onAccept: { print("Accept") },
        onReject: { print("Reject") }
    )
}
