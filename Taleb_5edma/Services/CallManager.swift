//
//  CallManager.swift
//  Taleb_5edma
//
//  Centralized call manager coordinating WebSocket signaling
//

import Foundation
import Combine

/// Manages call state and coordinates WebSocket communication
class CallManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = CallManager()
    
    // MARK: - Published Properties
    
    @Published var callState: CallState = .idle
    @Published var currentCallData: CallData?
    @Published var localVideoFrame: String? // Base64 encoded JPEG
    @Published var remoteVideoFrame: String? // Base64 encoded JPEG
    @Published var isConnected = false
    @Published var isVideoStreaming = false
    @Published var isAudioStreaming = false
    
    // MARK: - Private Properties
    
    private let webSocketManager: WebSocketManager
    private var cancellables = Set<AnyCancellable>()
    private var callTimeoutTask: Task<Void, Never>?
    
    // Media managers
    private var cameraManager: CameraManager?
    private var audioCaptureManager: AudioCaptureManager?
    private var audioPlaybackManager: CallAudioPlaybackManager?
    
    // MARK: - User Info
    
    private var currentUserId: String?
    private var currentUserName: String?
    
    // MARK: - Initialization
    
    private init() {
        webSocketManager = WebSocketManager()
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind WebSocket connection state
        webSocketManager.$isConnected
            .assign(to: &$isConnected)
        
        // Bind WebSocket call state
        webSocketManager.$callState
            .assign(to: &$callState)
        
        // Setup WebSocket callbacks
        webSocketManager.onIncomingCall = { [weak self] callData in
            self?.handleIncomingCall(callData)
        }
        
        webSocketManager.onCallStarted = { [weak self] callData in
            self?.handleCallStarted(callData)
        }
        
        webSocketManager.onCallResponse = { [weak self] callId, accepted in
            self?.handleCallResponse(callId: callId, accepted: accepted)
        }
        
        webSocketManager.onCallEnded = { [weak self] callId, reason in
            self?.handleCallEnded(reason: reason)
        }
        
        webSocketManager.onCallCancelled = { [weak self] callId in
            self?.handleCallCancelled()
        }
        
        webSocketManager.onJoinCallRoom = { [weak self] roomId, callId in
            self?.handleJoinCallRoom(roomId: roomId, callId: callId)
        }
        
        // Media frame handler
        webSocketManager.onMediaFrame = { [weak self] type, frameData, audioData in
            if type == "video", let video = frameData {
                DispatchQueue.main.async {
                    self?.remoteVideoFrame = video
                }
            } else if type == "audio", let audio = audioData {
                self?.audioPlaybackManager?.playAudioData(audio)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Connect to call server with user credentials
    func connect(userId: String, userName: String) {
        currentUserId = userId
        currentUserName = userName
        webSocketManager.connect(userId: userId, userName: userName)
        print("📞 CallManager: Connecting user \(userName)")
    }
    
    /// Disconnect from call server
    func disconnect() {
        webSocketManager.disconnect()
        callState = .idle
        currentCallData = nil
    }
    
    /// Make an outgoing call
    func makeCall(toUserId: String, toUserName: String, isVideoCall: Bool, chatId: String?) {
        guard isConnected else {
            print("❌ Cannot make call: not connected")
            callState = .callFailed(reason: "Not connected to server")
            return
        }
        
        print("📞 Making call to \(toUserName)")
        
        // Create temporary call data
        let roomId = "room_\(Date().timeIntervalSince1970)"
        let callData = CallData(
            callId: "temp_\(UUID().uuidString)",
            roomId: roomId,
            fromUserId: currentUserId ?? "",
            fromUserName: currentUserName ?? "",
            toUserId: toUserId,
            isVideoCall: isVideoCall,
            chatId: chatId,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
        
        currentCallData = callData
        callState = .outgoingCall(callId: callData.callId)
        
        // Send call request via WebSocket
        webSocketManager.makeCall(
            toUserId: toUserId,
            toUserName: toUserName,
            isVideoCall: isVideoCall,
            chatId: chatId
        )
        
        // Set timeout for call (30 seconds)
        startCallTimeout()
    }
    
    /// Accept an incoming call
    func acceptCall() {
        guard case .incomingCall(let callData) = callState else {
            print("❌ No incoming call to accept")
            return
        }
        
        print("✅ Accepting call: \(callData.callId)")
        webSocketManager.acceptCall(callId: callData.callId)
        
        // Update state
        callState = .inCall(callData: callData)
        currentCallData = callData
    }
    
    /// Reject an incoming call
    func rejectCall() {
        guard case .incomingCall(let callData) = callState else {
            print("❌ No incoming call to reject")
            return
        }
        
        print("❌ Rejecting call: \(callData.callId)")
        webSocketManager.rejectCall(callId: callData.callId)
        
        // Reset state
        callState = .idle
        currentCallData = nil
    }
    
    /// Cancel an outgoing call
    func cancelCall() {
        guard case .outgoingCall(let callId) = callState else {
            print("❌ No outgoing call to cancel")
            return
        }
        
        print("❌ Cancelling call: \(callId)")
        webSocketManager.cancelCall(callId: callId)
        
        // Reset state
        callState = .idle
        currentCallData = nil
        cancelCallTimeout()
    }
    
    /// End the current call
    func endCall() {
        guard let callData = currentCallData else {
            print("❌ No active call to end")
            callState = .idle
            return
        }
        
        print("🔚 Ending call: \(callData.callId)")
        webSocketManager.endCall(
            roomId: callData.roomId,
            callId: callData.callId,
            reason: "Call ended by user"
        )
        
        // Reset state
        callState = .ended
        currentCallData = nil
        cancelCallTimeout()
        
        // Reset to idle after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.callState = .idle
        }
    }
    
    /// Join call room after acceptance
    func joinCallRoom(roomId: String) {
        guard let userId = currentUserId,
              let userName = currentUserName else {
            print("❌ Cannot join room: user info missing")
            return
        }
        
        print("🚪 Joining call room: \(roomId)")
        webSocketManager.joinCallRoom(
            roomId: roomId,
            userId: userId,
            userName: userName
        )
    }
    
    // MARK: - Private Handlers
    
    private func handleIncomingCall(_ callData: CallData) {
        print("📞 Incoming call from: \(callData.fromUserName)")
        
        currentCallData = callData
        callState = .incomingCall(callData: callData)
        
        // Auto-timeout incoming call after 30 seconds
        startCallTimeout()
    }
    
    private func handleCallStarted(_ callData: CallData) {
        print("📞 Call started: \(callData.callId)")
        currentCallData = callData
    }
    
    private func handleCallResponse(callId: String, accepted: Bool) {
        print("📞 Call response - accepted: \(accepted)")
        
        if accepted {
            // Other user accepted, wait for room join signal
            print(" ✅ Call accepted, waiting to join room...")
        } else {
            // Call was rejected
            print("❌ Call was rejected")
            callState = .callFailed(reason: "Call rejected")
            currentCallData = nil
            
            // Reset to idle after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.callState = .idle
            }
        }
        
        cancelCallTimeout()
    }
    
    private func handleCallEnded(reason: String) {
        print("🔚 Call ended: \(reason)")
        
        stopMediaStreams()
        callState = .ended
        currentCallData = nil
        cancelCallTimeout()
        
        // Reset to idle after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.callState = .idle
        }
    }
    
    private func handleCallCancelled() {
        print("❌ Call was cancelled")
        
        stopMediaStreams()
        callState = .ended
        currentCallData = nil
        cancelCallTimeout()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.callState = .idle
        }
    }
    
    private func handleJoinCallRoom(roomId: String, callId: String) {
        print("🚪 Received join-call-room signal for: \(roomId)")
        
        // Join the room
        joinCallRoom(roomId: roomId)
        
        // Update state to in-call
        if let callData = currentCallData {
            callState = .inCall(callData: callData)
            
            // Start media streaming
            startMediaStreams()
        }
    }
    
    // MARK: - Timeout Management
    
    private func startCallTimeout() {
        cancelCallTimeout()
        
        callTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            
            await MainActor.run {
                guard let self = self else { return }
                
                // Check if still in ringing state
                switch self.callState {
                case .outgoingCall, .incomingCall:
                    print("⏰ Call timeout")
                    self.callState = .callFailed(reason: "Call timeout")
                    self.currentCallData = nil
                    
                    // Reset to idle after brief delay
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        self.callState = .idle
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func cancelCallTimeout() {
        callTimeoutTask?.cancel()
        callTimeoutTask = nil
    }
    
    // MARK: - Media Streaming
    
    private func startMediaStreams() {
        print("📸 Starting media streams...")
        
        // Initialize camera manager
        cameraManager = CameraManager()
        cameraManager?.onFrameCaptured = { [weak self] base64Frame in
            guard let self = self else { return }
            
            // Update local video for UI
            DispatchQueue.main.async {
                self.localVideoFrame = base64Frame
            }
            
            // Send to other user via WebSocket
            if let roomId = self.currentCallData?.roomId {
                self.webSocketManager.sendMediaFrame(
                    roomId: roomId,
                    type: "video",
                    frameData: base64Frame,
                    audioData: nil
                )
            }
        }
        
        cameraManager?.onError = { error in
            print("❌ Camera error: \(error)")
        }
        
        cameraManager?.onStateChanged = { state in
            print("📸 Camera: \(state)")
        }
        
        cameraManager?.startCapture()
        isVideoStreaming = true
        
        // Initialize audio capture manager
        audioCaptureManager = AudioCaptureManager()
        audioCaptureManager?.onAudioData = { [weak self] base64Audio in
            guard let self = self,
                  let roomId = self.currentCallData?.roomId else { return }
            
            self.webSocketManager.sendMediaFrame(
                roomId: roomId,
                type: "audio",
                frameData: nil,
                audioData: base64Audio
            )
        }
        
        audioCaptureManager?.onError = { error in
            print("❌ Audio capture error: \(error)")
        }
        
        audioCaptureManager?.onSpeakingStateChanged = { isSpeaking in
            print("🎤 Speaking: \(isSpeaking)")
        }
        
        audioCaptureManager?.startCapture()
        isAudioStreaming = true
        
        // Initialize audio playback manager
        audioPlaybackManager = CallAudioPlaybackManager()
        audioPlaybackManager?.setup()
        
        print("✅ All media streams started")
    }
    
    private func stopMediaStreams() {
        print("⏹️ Stopping media streams...")
        
        cameraManager?.stopCapture()
        cameraManager = nil
        
        audioCaptureManager?.stopCapture()
        audioCaptureManager = nil
        
        audioPlaybackManager?.stop()
        audioPlaybackManager = nil
        
        DispatchQueue.main.async {
            self.localVideoFrame = nil
            self.remoteVideoFrame = nil
            self.isVideoStreaming = false
            self.isAudioStreaming = false
        }
        
        print("✅ All media streams stopped")
    }
}

