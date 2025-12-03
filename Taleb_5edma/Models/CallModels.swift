//
//  CallModels.swift
//  Taleb_5edma
//
//  Created by WebSocket Call System
//

import Foundation

// MARK: - Call State

enum CallState: Equatable {
    case idle
    case connecting
    case outgoingCall(callId: String)
    case incomingCall(callData: CallData)
    case inCall(callData: CallData)
    case callFailed(reason: String)
    case ended
    
    var description: String {
        switch self {
        case .idle: return "Idle"
        case .connecting: return "Connecting..."
        case .outgoingCall: return "Calling..."
        case .incomingCall: return "Incoming call"
        case .inCall: return "Connected"
        case .callFailed(let reason): return "Failed: \(reason)"
        case .ended: return "Call ended"
        }
    }
}

// MARK: - Call Data

struct CallData: Codable, Equatable {
    let callId: String
    let roomId: String
    let fromUserId: String
    let fromUserName: String
    let toUserId: String? // Made optional as server doesn't always send it
    let isVideoCall: Bool
    var chatId: String?
    let timestamp: String?
    
    static func == (lhs: CallData, rhs: CallData) -> Bool {
        return lhs.callId == rhs.callId
    }
}

// MARK: - WebSocket Events

enum WebSocketEvent: String {
    // Connection
    case register
    case registerSuccess = "register-success"
    case registerError = "register-error"
    
    // Call Management
    case callRequest = "call-request"
    case incomingCall = "incoming-call"
    case callStarted = "call-started"
    case callResponse = "call-response"
    case cancelCall = "cancel-call"
    case callCancelled = "call-cancelled"
    case endCall = "end-call"
    case callEnded = "call-ended"
    case callTimeout = "call-timeout"
    case callRequestFailed = "call-request-failed"
    case callResponseFailed = "call-response-failed"
    
    // Room Management
    case joinCall = "join-call"
    case joinCallRoom = "join-call-room"
    case leaveCall = "leave-call"
    case userJoined = "user-joined"
    case userLeft = "user-left"
    case roomParticipants = "room-participants"
    
    // WebRTC Signaling
    case offer
    case answer
    case iceCandidate = "ice-candidate"
    
    // Media Streaming (optional - for frame-by-frame if needed)
    case mediaFrame = "media-frame"
    
    // Connection Status
    case getConnectionStatus = "get-connection-status"
    case connectionStatus = "connection-status"
    case userOnlineStatus = "user-online-status"
    
    // Debug
    case getServerStats = "get-server-stats"
    case serverStats = "server-stats"
}

// MARK: - Network Quality

enum NetworkQuality {
    case poor      // 2G/Edge
    case fair      // 3G
    case good      // 4G/LTE
    case excellent // WiFi/5G
    
    var description: String {
        switch self {
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    var color: String {
        switch self {
        case .poor: return "red"
        case .fair: return "orange"
        case .good: return "yellow"
        case .excellent: return "green"
        }
    }
    
    // Recommended video quality settings
    var videoConfig: VideoQualityConfig {
        switch self {
        case .poor:
            return VideoQualityConfig(width: 0, height: 0, fps: 0, enabled: false) // Audio only
        case .fair:
            return VideoQualityConfig(width: 360, height: 240, fps: 15, enabled: true)
        case .good:
            return VideoQualityConfig(width: 480, height: 360, fps: 24, enabled: true)
        case .excellent:
            return VideoQualityConfig(width: 720, height: 480, fps: 30, enabled: true)
        }
    }
}

struct VideoQualityConfig {
    let width: Int
    let height: Int
    let fps: Int
    let enabled: Bool
}

// MARK: - WebSocket Request/Response Models

struct RegisterRequest: Codable {
    let userId: String
    let userName: String?
}

struct CallRequestData: Codable {
    let roomId: String
    let fromUserId: String
    let fromUserName: String
    let toUserId: String
    let isVideoCall: Bool
    let chatId: String?
}

struct CallResponseData: Codable {
    let callId: String
    let accepted: Bool
}

struct CancelCallData: Codable {
    let callId: String
}

struct EndCallData: Codable {
    let roomId: String?
    let callId: String?
    let reason: String?
}

struct JoinCallData: Codable {
    let roomId: String
    let userId: String
    let userName: String
}

struct WebRTCSignalingData: Codable {
    let roomId: String
    let offer: String?
    let answer: String?
    let candidate: String?
}

// MARK: - Error Types

enum CallError: Error, LocalizedError {
    case notConnected
    case alreadyInCall
    case userNotAvailable
    case callFailed(String)
    case webRTCError(String)
    case permissionDenied
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to call server"
        case .alreadyInCall:
            return "Already in an active call"
        case .userNotAvailable:
            return "User is not available"
        case .callFailed(let reason):
            return "Call failed: \(reason)"
        case .webRTCError(let reason):
            return "WebRTC error: \(reason)"
        case .permissionDenied:
            return "Camera or microphone permission denied"
        case .timeout:
            return "Call request timed out"
        }
    }
}
