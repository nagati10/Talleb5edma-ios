//
//  CallView.swift
//  Taleb_5edma
//
//  Enhanced call view with WebSocket integration
//

import SwiftUI

struct CallView: View {
    @StateObject private var viewModel: CallViewModel
    @Environment(\.dismiss) var dismiss
    
    // Call parameters
    let toUserId: String
    let toUserName: String
    let isVideoCall: Bool
    let chatId: String?
    
    init(toUserId: String, toUserName: String, isVideoCall: Bool, chatId: String? = nil) {
        self.toUserId = toUserId
        self.toUserName = toUserName
        self.isVideoCall = isVideoCall
        self.chatId = chatId
        _viewModel = StateObject(wrappedValue: CallViewModel())
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background
            backgroundView
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                Spacer()
                
                // User Info (when video is off or connecting)
                if !viewModel.isVideoEnabled || viewModel.isConnecting {
                    userInfoView
                }
                
                Spacer()
                
                // Call Controls
                callControls
            }
            
            // Self View Preview - separate overlay, only show when remote video is visible
            if viewModel.isVideoEnabled && !viewModel.isConnecting && viewModel.callState != .idle && viewModel.remoteVideoFrame != nil {
                selfViewPreview
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .onAppear {
            // Only set initial values if needed, but DO NOT initiate a call here
            // Call initiation is handled by ChatViewModel or CallCoordinator
            if viewModel.toUserName.isEmpty {
                viewModel.toUserName = toUserName
                viewModel.toUserId = toUserId
                viewModel.chatId = chatId
                viewModel.isVideoEnabled = isVideoCall
            }
        }
        .onChange(of: viewModel.callState) { newState in
            // Auto-dismiss on call end or failure
            if case .ended = newState {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
            } else if case .callFailed = newState {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundView: some View {
        Group {
            if let remoteFrame = viewModel.remoteVideoFrame {
                VideoDisplayView(base64Frame: remoteFrame, contentMode: .fill)
                    .ignoresSafeArea()
            } else {
                Color.gray
                    .ignoresSafeArea()
                    .blur(radius: viewModel.isVideoEnabled ? 0 : 25)
                    .overlay(
                        Color.black.opacity(viewModel.isVideoEnabled ? 0.3 : 0.6)
                    )
            }
        }
    }
    
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.callStatusText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                // Connection status
                if viewModel.isConnecting {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Connecting...")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    Text(statusSubtext)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Chat button
            Button(action: {
                // TODO: Show chat overlay
            }) {
                Image(systemName: "message")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    private var userInfoView: some View {
        VStack(spacing: 24) {
            // Avatar
            Circle()
                .fill(Color.gray)
                .frame(width: 120, height: 120)
                .overlay(
                    Text(toUserName.prefix(2).uppercased())
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Name and status
            VStack(spacing: 8) {
                Text(toUserName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(callStateDescription)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.bottom, 100)
    }
    
    private var callControls: some View {
        HStack(spacing: 20) {
            // Video toggle (only for video calls)
            if isVideoCall {
                CallControlButton(
                    icon: viewModel.isVideoEnabled ? "video.fill" : "video.slash.fill",
                    backgroundColor: viewModel.isVideoEnabled ? .white : Color.black.opacity(0.4),
                    contentColor: viewModel.isVideoEnabled ? .black : .white
                ) {
                    viewModel.toggleVideo()
                }
            }
            
            // Camera switch (only when video is on)
            if isVideoCall && viewModel.isVideoEnabled {
                CallControlButton(
                    icon: "arrow.triangle.2.circlepath.camera.fill",
                    backgroundColor: Color.black.opacity(0.4),
                    contentColor: .white
                ) {
                    viewModel.switchCamera()
                }
            }
            
            // Microphone toggle
            CallControlButton(
                icon: viewModel.isAudioEnabled ? "mic.fill" : "mic.slash.fill",
                backgroundColor: viewModel.isAudioEnabled ? Color.black.opacity(0.4) : .white,
                contentColor: viewModel.isAudioEnabled ? .white : .black
            ) {
                viewModel.toggleAudio()
            }
            
            // Hang up button
            CallControlButton(
                icon: "phone.down.fill",
                backgroundColor: Color(hex: 0xFF3B30),
                contentColor: .white
            ) {
                viewModel.endCall()
                dismiss()
            }
        }
        .padding(.bottom, 50)
    }
    
    private var selfViewPreview: some View {
        Group {
            if let localFrame = viewModel.localVideoFrame {
                VideoDisplayView(base64Frame: localFrame, contentMode: .fill)
                    .frame(width: 120, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
            } else {
                SelfViewPreview()
                    .frame(width: 120, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 10)
        .padding(.trailing, 120)
    }
    
    // MARK: - Helper Properties
    
    private var statusSubtext: String {
        switch viewModel.callState {
        case .outgoingCall:
            return "Ringing..."
        case .inCall:
            return isVideoCall ? "Video call" : "Voice call"
        default:
            return ""
        }
    }
    
    private var callStateDescription: String {
        switch viewModel.callState {
        case .idle:
            return "Ready"
        case .connecting:
            return "Connecting..."
        case .outgoingCall:
            return "Calling..."
        case .incomingCall:
            return "Incoming call"
        case .inCall:
            return "Connected"
        case .callFailed(let reason):
            return reason
        case .ended:
            return "Call ended"
        }
    }
}

// MARK: - Supporting Views

struct SelfViewPreview: View {
    var body: some View {
        ZStack {
            Color.gray
            
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
            
            // TODO: Replace with actual camera preview when MediaStreamManager is added
        }
    }
}

struct CallControlButton: View {
    let icon: String
    let backgroundColor: Color
    let contentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(contentColor)
                .frame(width: 56, height: 56)
                .background(backgroundColor)
                .clipShape(Circle())
        }
    }
}

// MARK: - Preview

#Preview {
    CallView(
        toUserId: "test123",
        toUserName: "Martha Craig",
        isVideoCall: true,
        chatId: "chat123"
    )
}
