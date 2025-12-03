//
//  AppRootView.swift
//  Taleb_5edma
//
//  Wrapper view for global call system integration
//  Replace your current app root with this or integrate the ZStack pattern
//

import SwiftUI

struct AppRootView<Content: View>: View {
    @StateObject private var callCoordinator = CallCoordinator.shared
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Your main app content
            content
                .fullScreenCover(isPresented: $callCoordinator.showCallView) {
                    if let data = callCoordinator.outgoingCallData {
                        CallView(
                            toUserId: data.userId,
                            toUserName: data.userName,
                            isVideoCall: data.isVideo,
                            chatId: data.chatId
                        )
                        .onDisappear {
                            callCoordinator.dismissCallView()
                        }
                    }
                }
            
            // Global incoming call overlay - appears on top of everything
            if callCoordinator.showIncomingCallOverlay,
               let callData = callCoordinator.incomingCallData {
                IncomingCallOverlay(
                    callData: callData,
                    onAccept: {
                        callCoordinator.acceptCall()
                    },
                    onReject: {
                        callCoordinator.rejectCall()
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .onAppear {
            // Connect to call server when app launches (if user is logged in)
            connectToCallServerIfNeeded()
        }
    }
    
    private func connectToCallServerIfNeeded() {
        if let userId = UserDefaults.standard.string(forKey: "userId"),
           !userId.isEmpty {
            let userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
            callCoordinator.connectToCallServer(userId: userId, userName: userName)
        }
    }
}

