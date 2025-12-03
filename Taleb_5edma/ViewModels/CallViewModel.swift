//
//  CallViewModel.swift
//  Taleb_5edma
//
//  ViewModel for call screen
//

import Foundation
import Combine

class CallViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var callState: CallState = .idle
    @Published var isVideoEnabled = true
    @Published var isAudioEnabled = true
    @Published var callDuration: TimeInterval = 0
    @Published var toUserName: String = ""
    @Published var toUserId: String = ""
    @Published var chatId: String?
    @Published var isConnecting = false
    
    @Published var localVideoFrame: String? // Base64 encoded JPEG
    @Published var remoteVideoFrame: String? // Base64 encoded JPEG
    
    // MARK: - Private Properties
    
    private let callManager: CallManager
    private var cancellables = Set<AnyCancellable>()
    private var durationTimer: Timer?
    private var callStartTime: Date?
    
    // MARK: - Initialization
    
    init(callManager: CallManager = .shared) {
        self.callManager = callManager
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe call state changes
        callManager.$callState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleCallStateChange(state)
            }
            .store(in: &cancellables)
        
        // Observe video frames (Base64)
        callManager.$localVideoFrame
            .receive(on: DispatchQueue.main)
            .assign(to: \.localVideoFrame, on: self)
            .store(in: &cancellables)
            
        callManager.$remoteVideoFrame
            .receive(on: DispatchQueue.main)
            .assign(to: \.remoteVideoFrame, on: self)
            .store(in: &cancellables)
        
        // Observe current call data
        callManager.$currentCallData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callData in
                guard let self = self, let callData = callData else { return }
                
                // Determine if we are the caller or receiver
                let currentUserId = UserDefaults.standard.string(forKey: "userId")
                
                if callData.fromUserId == currentUserId {
                    // We are the caller (Outgoing)
                    // We want to show the TO user info
                    // But CallData might not have the TO user name if we didn't pass it fully
                    // However, for outgoing calls, we passed it to makeCall
                    // Let's rely on what was passed to init/makeCall if possible, or fallback
                    
                    // If we have a stored name from makeCall, keep it.
                    // Otherwise try to use what's in CallData (which might be nil for toUserName if not stored)
                    
                    // Actually, CallManager.makeCall stores toUserName in CallData
                    // But CallData struct doesn't have toUserName property? Let's check.
                    // CallData has: fromUserId, fromUserName, toUserId. NO toUserName.
                    
                    // So for outgoing calls, we must rely on what was passed to the View
                    // The View sets self.toUserName via makeCall() or init
                    
                } else {
                    // We are the receiver (Incoming)
                    // We want to show the FROM user info
                    self.toUserName = callData.fromUserName
                    self.toUserId = callData.fromUserId
                    self.chatId = callData.chatId
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Call Actions
    
    /// Initiate an outgoing call
    func makeCall(toUserId: String, toUserName: String, isVideoCall: Bool, chatId: String?) {
        self.toUserId = toUserId
        self.toUserName = toUserName
        self.chatId = chatId
        self.isVideoEnabled = isVideoCall
        self.isConnecting = true
        
        callManager.makeCall(
            toUserId: toUserId,
            toUserName: toUserName,
            isVideoCall: isVideoCall,
            chatId: chatId
        )
    }
    
    /// Accept incoming call
    func acceptCall() {
        callManager.acceptCall()
    }
    
    /// Reject incoming call
    func rejectCall() {
        callManager.rejectCall()
    }
    
    /// End current call
    func endCall() {
        stopDurationTimer()
        callManager.endCall()
    }
    
    /// Cancel outgoing call
    func cancelCall() {
        callManager.cancelCall()
    }
    
    // MARK: - Media Controls
    
    /// Toggle video on/off
    func toggleVideo() {
        isVideoEnabled.toggle()
        print("📹 Video \(isVideoEnabled ? "enabled" : "disabled")")
        // TODO: Implement actual video toggle when WebRTC is added
    }
    
    /// Toggle audio on/off
    func toggleAudio() {
        isAudioEnabled.toggle()
        print("🎤 Audio \(isAudioEnabled ? "enabled" : "disabled")")
        // TODO: Implement actual audio toggle when WebRTC is added
    }
    
    /// Switch camera (front/back)
    func switchCamera() {
        print("🔄 Switching camera")
        // TODO: Implement camera switch when MediaStreamManager is added
    }
    
    // MARK: - Call State Handling
    
    private func handleCallStateChange(_ state: CallState) {
        callState = state
        
        switch state {
        case .idle:
            stopDurationTimer()
            isConnecting = false
            callDuration = 0
            
        case .connecting:
            isConnecting = true
            
        case .outgoingCall:
            isConnecting = true
            print("📞 Outgoing call...")
            
        case .incomingCall(let callData):
            toUserName = callData.fromUserName
            toUserId = callData.fromUserId
            chatId = callData.chatId
            isVideoEnabled = callData.isVideoCall
            isConnecting = false
            
        case .inCall:
            isConnecting = false
            startDurationTimer()
            print("✅ Call connected")
            
        case .callFailed(let reason):
            isConnecting = false
            stopDurationTimer()
            print("❌ Call failed: \(reason)")
            
        case .ended:
            isConnecting = false
            stopDurationTimer()
            print("🔚 Call ended")
        }
    }
    
    // MARK: - Duration Timer
    
    private func startDurationTimer() {
        callStartTime = Date()
        callDuration = 0
        
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.callStartTime else { return }
            self.callDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
        callStartTime = nil
    }
    
    // MARK: - Formatted Values
    
    var formattedDuration: String {
        let minutes = Int(callDuration) / 60
        let seconds = Int(callDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var callStatusText: String {
        switch callState {
        case .idle:
            return "Ready"
        case .connecting:
            return "Connecting..."
        case .outgoingCall:
            return "Calling..."
        case .incomingCall:
            return "Incoming call"
        case .inCall:
            return formattedDuration
        case .callFailed(let reason):
            return reason
        case .ended:
            return "Call ended"
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopDurationTimer()
    }
}
