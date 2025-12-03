//
//  CallCoordinator.swift
//  Taleb_5edma
//
//  Coordinates global call notifications and navigation
//

import SwiftUI
import Combine

/// Global coordinator for managing call UI across the entire app
class CallCoordinator: ObservableObject {
    // MARK: - Singleton
    
    static let shared = CallCoordinator()
    
    // MARK: - Published Properties
    
    @Published var showIncomingCallOverlay = false
    @Published var showCallView = false
    @Published var incomingCallData: CallData?
    @Published var outgoingCallData: (userId: String, userName: String, isVideo: Bool, chatId: String?)?
    
    // MARK: - Private Properties
    
    private let callManager = CallManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Monitor call state changes
        callManager.$callState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleCallStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Call State Handling
    
    private func handleCallStateChange(_ state: CallState) {
        switch state {
        case .incomingCall(let callData):
            // Show incoming call overlay globally
            incomingCallData = callData
            showIncomingCallOverlay = true
            print("📞 Showing incoming call overlay for: \(callData.fromUserName)")
            
        case .outgoingCall:
            // Navigate to call view for outgoing call
            if let data = callManager.currentCallData {
                outgoingCallData = (
                    data.toUserId ?? "unknown",
                    "Calling...", // Will be updated in CallView
                    data.isVideoCall,
                    data.chatId
                )
                showCallView = true
                print("📞 Navigating to call view for outgoing call")
            }
            
        case .idle, .ended, .callFailed:
            // Dismiss overlays
            showIncomingCallOverlay = false
            // Don't auto-dismiss call view here - let it handle its own dismissal
            
        default:
            break
        }
    }
    
    // MARK: - Public Actions
    
    /// Accept incoming call
    func acceptCall() {
        guard let callData = incomingCallData else { return }
        
        print("✅ Accepting call from: \(callData.fromUserName)")
        
        // Hide incoming call overlay
        showIncomingCallOverlay = false
        
        // Accept the call
        callManager.acceptCall()
        
        // Navigate to call view
        outgoingCallData = (
            callData.fromUserId,
            callData.fromUserName,
            callData.isVideoCall,
            callData.chatId
        )
        showCallView = true
    }
    
    /// Reject incoming call
    func rejectCall() {
        print("❌ Rejecting call")
        
        callManager.rejectCall()
        showIncomingCallOverlay = false
        incomingCallData = nil
    }
    
    /// Dismiss call view
    func dismissCallView() {
        showCallView = false
        outgoingCallData = nil
    }
    
    /// Connect to call server (should be called when user logs in)
    func connectToCallServer(userId: String, userName: String) {
        print("🔌 Connecting to call server for user: \(userName)")
        callManager.connect(userId: userId, userName: userName)
    }
    
    /// Disconnect from call server (should be called when user logs out)
    func disconnectFromCallServer() {
        print("🔌 Disconnecting from call server")
        callManager.disconnect()
    }
}
