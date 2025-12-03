//
//  CallAudioPlaybackManager.swift
//  Taleb_5edma
//
//  Plays received audio from Base64 (for video calls)
//

import AVFoundation
import Foundation

class CallAudioPlaybackManager {
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    
    func setup() {
        do {
            // Configure audio session first
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true)
            
            audioEngine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            
            guard let engine = audioEngine, let player = playerNode else { 
                print("❌ Failed to create audio engine or player node")
                return 
            }
            
            engine.attach(player)
            
            // Connect using nil format - let the engine choose compatible format
            // We'll convert received audio to match the engine's format
            engine.connect(player, to: engine.mainMixerNode, format: nil)
            
            // Store the format the engine is actually using
            audioFormat = player.outputFormat(forBus: 0)
            
            print("✅ Audio playback format: \(audioFormat?.sampleRate ?? 0)Hz, \(audioFormat?.channelCount ?? 0) ch")
            
            engine.prepare()
            try engine.start()
            player.play()
            
            print("✅ Audio playback ready")
            
        } catch let error as NSError {
            print("❌ Audio playback setup error: \(error.localizedDescription) (Code: \(error.code))")
            
            // Clean up on error
            audioEngine?.stop()
            audioEngine = nil
            playerNode = nil
            audioFormat = nil
        }
    }
    
    func playAudioData(_ base64String: String) {
        guard let data = Data(base64Encoded: base64String),
              let format = audioFormat,
              let player = playerNode else {
            return
        }
        
        // Create audio buffer from data
        let frameCount = UInt32(data.count / MemoryLayout<Int16>.size)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return
        }
        
        buffer.frameLength = frameCount
        
        // Copy data to buffer
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            guard let baseAddress = bytes.baseAddress else { return }
            let int16Pointer = baseAddress.assumingMemoryBound(to: Int16.self)
            buffer.int16ChannelData?.pointee.update(from: int16Pointer, count: Int(frameCount))
        }
        
        // Schedule and play
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    
    func stop() {
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        audioFormat = nil
    }
}
