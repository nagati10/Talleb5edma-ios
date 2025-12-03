//
//  WebSocketManager.swift
//  Taleb_5edma
//
//  Created by WebSocket Call System
//
//  IMPORTANT: This file requires Socket.IO-Client-Swift
//  Add via Swift Package Manager: https://github.com/socketio/socket.io-client-swift
//  Version: ~16.0.0
//

import Foundation
import Combine
import SocketIO

/// Manages WebSocket connection to the call server using Socket.IO
class WebSocketManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var callState: CallState = .idle
    
    // MARK: - Private Properties
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var currentUserId: String?
    private var currentUserName: String?
    
    // Callbacks
    var onIncomingCall: ((CallData) -> Void)?
    var onCallStarted: ((CallData) -> Void)?
    var onCallResponse: ((String, Bool) -> Void)?
    var onCallEnded: ((String?, String) -> Void)?
    var onCallCancelled: ((String) -> Void)?
    var onJoinCallRoom: ((String, String) -> Void)?
    
    // Media frame callback (for Base64 video/audio)
    var onMediaFrame: ((String, String?, String?) -> Void)? // (type, frameData, audioData)
    
    // MARK: - Initialization
    
    init() {
        setupSocketManager()
    }
    
    private func setupSocketManager() {
        // Get the WebSocket URL from APIConfig
        let baseURL = APIConfig.baseURL
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid WebSocket URL")
            return
        }
        
        // Configure Socket.IO
        manager = SocketManager(socketURL: url, config: [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectAttempts(-1), // Infinite reconnection attempts
            .reconnectWait(1),
            .forceWebsockets(true),
            .secure(baseURL.starts(with: "https"))
        ])
        
        socket = manager?.defaultSocket
        
        setupEventHandlers()
    }
    
    // MARK: - Connection Management
    
    func connect(userId: String, userName: String? = nil) {
        guard let socket = socket else {
            print("❌ Socket not initialized")
            return
        }
        
        currentUserId = userId
        currentUserName = userName
        
        print("🔌 Connecting to WebSocket server...")
        socket.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        isConnected = false
        print("🔌 Disconnected from WebSocket server")
    }
    
    private func registerUser() {
        guard let userId = currentUserId else {
            print("❌ Cannot register: userId is nil")
            return
        }
        
        let data: [String: Any] = [
            "userId": userId,
            "userName": currentUserName ?? ""
        ]
        
        socket?.emit(WebSocketEvent.register.rawValue, data)
        print("📝 Registering user: \(userId)")
    }
    
    // MARK: - Event Handlers Setup
    
    private func setupEventHandlers() {
        guard let socket = socket else { return }
        
        // Connection events
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            self?.handleConnect()
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            self?.handleDisconnect(data)
        }
        
        socket.on(clientEvent: .error) { [weak self] data, ack in
            self?.handleError(data)
        }
        
        // Registration
        socket.on(WebSocketEvent.registerSuccess.rawValue) { [weak self] data, ack in
            self?.handleRegisterSuccess(data)
        }
        
        socket.on(WebSocketEvent.registerError.rawValue) { [weak self] data, ack in
            self?.handleRegisterError(data)
        }
        
        // Call events
        socket.on(WebSocketEvent.incomingCall.rawValue) { [weak self] data, ack in
            self?.handleIncomingCall(data)
        }
        
        socket.on(WebSocketEvent.callStarted.rawValue) { [weak self] data, ack in
            self?.handleCallStarted(data)
        }
        
        socket.on(WebSocketEvent.callResponse.rawValue) { [weak self] data, ack in
            self?.handleCallResponse(data)
        }
        
        socket.on(WebSocketEvent.callEnded.rawValue) { [weak self] data, ack in
            self?.handleCallEnded(data)
        }
        
        socket.on(WebSocketEvent.callCancelled.rawValue) { [weak self] data, ack in
            self?.handleCallCancelled(data)
        }
        
        socket.on(WebSocketEvent.callTimeout.rawValue) { [weak self] data, ack in
            self?.handleCallTimeout(data)
        }
        
        socket.on(WebSocketEvent.callRequestFailed.rawValue) { [weak self] data, ack in
            self?.handleCallRequestFailed(data)
        }
        
        socket.on(WebSocketEvent.joinCallRoom.rawValue) { [weak self] data, ack in
            self?.handleJoinCallRoom(data)
        }
        
       // Media frame receiver
        socket.on("media-frame") { [weak self] data, ack in
            self?.handleMediaFrame(data)
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleConnect() {
        print("✅ Connected to WebSocket server")
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionError = nil
        }
        registerUser()
    }
    
    private func handleDisconnect(_ data: [Any]) {
        print("❌ Disconnected from WebSocket server: \(data)")
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    private func handleError(_ data: [Any]) {
        print("❌ WebSocket error: \(data)")
        DispatchQueue.main.async {
            self.connectionError = "Connection error"
        }
    }
    
    private func handleRegisterSuccess(_ data: [Any]) {
        print("✅ User registered successfully")
        guard let dict = data.first as? [String: Any],
              let userId = dict["userId"] as? String else {
            return
        }
        print("📝 Registered userId: \(userId)")
    }
    
    private func handleRegisterError(_ data: [Any]) {
        print("❌ Registration failed: \(data)")
        DispatchQueue.main.async {
            self.connectionError = "Registration failed"
        }
    }
    
    private func handleIncomingCall(_ data: [Any]) {
        print("📞 Incoming call received: \(data)")
        guard let dict = data.first as? [String: Any] else {
            print("❌ Invalid incoming call data")
            return
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let callData = try JSONDecoder().decode(CallData.self, from: jsonData)
            
            DispatchQueue.main.async {
                self.callState = .incomingCall(callData: callData)
                self.onIncomingCall?(callData)
            }
        } catch {
            print("❌ Failed to parse incoming call data: \(error)")
        }
    }
    
    private func handleCallStarted(_ data: [Any]) {
        print("📞 Call started: \(data)")
        guard let dict = data.first as? [String: Any] else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let callData = try JSONDecoder().decode(CallData.self, from: jsonData)
            
            DispatchQueue.main.async {
                self.onCallStarted?(callData)
            }
        } catch {
            print("❌ Failed to parse call started data: \(error)")
        }
    }
    
    private func handleCallResponse(_ data: [Any]) {
        print("📞 Call response: \(data)")
        guard let dict = data.first as? [String: Any],
              let callId = dict["callId"] as? String,
              let accepted = dict["accepted"] as? Bool else {
            return
        }
        
        DispatchQueue.main.async {
            self.onCallResponse?(callId, accepted)
        }
    }
    
    private func handleCallEnded(_ data: [Any]) {
        print("📞 Call ended: \(data)")
        guard let dict = data.first as? [String: Any] else { return }
        
        let callId = dict["callId"] as? String
        let reason = dict["reason"] as? String ?? "Call ended"
        
        DispatchQueue.main.async {
            self.callState = .ended
            self.onCallEnded?(callId, reason)
        }
    }
    
    private func handleCallCancelled(_ data: [Any]) {
        print("📞 Call cancelled: \(data)")
        guard let dict = data.first as? [String: Any],
              let callId = dict["callId"] as? String else {
            return
        }
        
        DispatchQueue.main.async {
            self.callState = .ended
            self.onCallCancelled?(callId)
        }
    }
    
    private func handleCallTimeout(_ data: [Any]) {
        print("⏰ Call timeout: \(data)")
        DispatchQueue.main.async {
            self.callState = .callFailed(reason: "Call timed out")
        }
    }
    
    private func handleCallRequestFailed(_ data: [Any]) {
        print("❌ Call request failed: \(data)")
        guard let dict = data.first as? [String: Any],
              let reason = dict["reason"] as? String else {
            return
        }
        
        DispatchQueue.main.async {
            self.callState = .callFailed(reason: reason)
        }
    }
    
    private func handleJoinCallRoom(_ data: [Any]) {
        print("🚪 Join call room: \(data)")
        guard let dict = data.first as? [String: Any],
              let roomId = dict["roomId"] as? String,
              let callId = dict["callId"] as? String else {
            return
        }
        
        DispatchQueue.main.async {
            self.onJoinCallRoom?(roomId, callId)
        }
    }
    
    
    private func handleMediaFrame(_ data: [Any]) {
        guard let dict = data.first as? [String: Any],
              let type = dict["type"] as? String else {
            return
        }
        
        let frameData = dict["frameData"] as? String
        let audioData = dict["audioData"] as? String
        
        DispatchQueue.main.async {
            self.onMediaFrame?(type, frameData, audioData)
        }
    }
    
    // MARK: - Call Actions
    
    func makeCall(toUserId: String, toUserName: String, isVideoCall: Bool, chatId: String?) {
        guard isConnected else {
            print("❌ Cannot make call: not connected")
            DispatchQueue.main.async {
                self.callState = .callFailed(reason: "Not connected to server")
            }
            return
        }
        
        guard let fromUserId = currentUserId else {
            print("❌ Cannot make call: userId is nil")
            return
        }
        
        let roomId = "room_\(Date().timeIntervalSince1970)"
        
        let data: [String: Any] = [
            "roomId": roomId,
            "fromUserId": fromUserId,
            "fromUserName": currentUserName ?? "",
            "toUserId": toUserId,
            "isVideoCall": isVideoCall,
            "chatId": chatId ?? ""
        ]
        
        print("📞 Making call to \(toUserName): \(data)")
        socket?.emit(WebSocketEvent.callRequest.rawValue, data)
        
        DispatchQueue.main.async {
            self.callState = .connecting
        }
    }
    
    func acceptCall(callId: String) {
        let data: [String: Any] = [
            "callId": callId,
            "accepted": true
        ]
        
        print("✅ Accepting call: \(callId)")
        socket?.emit(WebSocketEvent.callResponse.rawValue, data)
    }
    
    func rejectCall(callId: String) {
        let data: [String: Any] = [
            "callId": callId,
            "accepted": false
        ]
        
        print("❌ Rejecting call: \(callId)")
        socket?.emit(WebSocketEvent.callResponse.rawValue, data)
        
        DispatchQueue.main.async {
            self.callState = .ended
        }
    }
    
    func cancelCall(callId: String) {
        let data: [String: Any] = [
            "callId": callId
        ]
        
        print("❌ Cancelling call: \(callId)")
        socket?.emit(WebSocketEvent.cancelCall.rawValue, data)
        
        DispatchQueue.main.async {
            self.callState = .ended
        }
    }
    
    func endCall(roomId: String?, callId: String?, reason: String = "Call ended by user") {
        var data: [String: Any] = [
            "reason": reason
        ]
        
        if let roomId = roomId {
            data["roomId"] = roomId
        }
        if let callId = callId {
            data["callId"] = callId
        }
        
        print("🔚 Ending call: \(data)")
        socket?.emit(WebSocketEvent.endCall.rawValue, data)
        
        DispatchQueue.main.async {
            self.callState = .ended
        }
    }
    
    func joinCallRoom(roomId: String, userId: String, userName: String) {
        let data: [String: Any] = [
            "roomId": roomId,
            "userId": userId,
            "userName": userName
        ]
        
        print("🚪 Joining call room: \(roomId)")
        socket?.emit(WebSocketEvent.joinCall.rawValue, data)
    }
    
    // MARK: - Media Frame Sending
    
    func sendMediaFrame(roomId: String, type: String, frameData: String?, audioData: String?) {
        guard let userId = currentUserId,
              let userName = currentUserName else {
            print("⚠️ Cannot send media frame: user not registered")
            return
        }
        
        var data: [String: Any] = [
            "roomId": roomId,
            "type": type,
            "userId": userId,
            "userName": userName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let frameData = frameData {
            data["frameData"] = frameData
        }
        
        if let audioData = audioData {
            data["audioData"] = audioData
        }
        
        socket?.emit("media-frame", data)
    }
    
    // MARK: - Cleanup
    
    deinit {
        disconnect()
    }
}
