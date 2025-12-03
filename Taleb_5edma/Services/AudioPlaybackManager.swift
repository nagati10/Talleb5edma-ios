//
//  AudioPlaybackManager.swift
//  Taleb_5edma
//
//  Audio playback for chat voice messages
//

import Foundation
import Combine
import AVFoundation

class AudioPlaybackManager: ObservableObject {
    @Published var currentlyPlayingId: String?
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var cancellables = Set<AnyCancellable>()
    
    func play(url: URL, messageId: String) {
        // Stop current playback
        stop()
        
        print("🎵 Attempting to play audio from: \(url.absoluteString)")
        
        // Validate the asset first
        let asset = AVAsset(url: url)
        
        // Check if asset is playable
        asset.loadValuesAsynchronously(forKeys: ["playable", "tracks"]) { [weak self] in
            guard let self = self else { return }
            
            var error: NSError?
            let status = asset.statusOfValue(forKey: "playable", error: &error)
            
            DispatchQueue.main.async {
                if status == .loaded {
                    if asset.isPlayable {
                        print("✅ Asset is playable, starting playback...")
                        self.startPlayback(url: url, messageId: messageId)
                    } else {
                        print("❌ Asset is not playable")
                        print("   Duration: \(asset.duration.seconds)")
                        print("   Tracks: \(asset.tracks.count)")
                    }
                } else {
                    print("❌ Failed to load asset")
                    print("   Status: \(status.rawValue)")
                    print("   Error: \(error?.localizedDescription ?? "Unknown")")
                    print("   URL: \(url.absoluteString)")
                    
                    // Try direct playback anyway as fallback
                    print("⚠️ Attempting direct playback as fallback...")
                    self.startPlayback(url: url, messageId: messageId)
                }
            }
        }
    }
    
    private func startPlayback(url: URL, messageId: String) {
        // Create player item
        playerItem = AVPlayerItem(url: url)
        
        // Observe status changes
        playerItem?.publisher(for: \.status)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    print("✅ Player ready to play")
                case .failed:
                    print("❌ Player failed to play")
                    if let error = self?.playerItem?.error {
                        print("   Error: \(error.localizedDescription)")
                        print("   Domain: \((error as NSError).domain)")
                        print("   Code: \((error as NSError).code)")
                    }
                case .unknown:
                    print("⏳ Player status unknown")
                @unknown default:
                    print("⚠️ Player unknown status: \(status.rawValue)")
                }
            }
            .store(in: &cancellables)
        
        // Create player
        player = AVPlayer(playerItem: playerItem)
        
        // Observe completion
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .sink { [weak self] _ in
                print("✅ Audio playback completed")
                self?.stop()
            }
            .store(in: &cancellables)
            
        player?.play()
        currentlyPlayingId = messageId
        
        print("▶️ Playing audio (AVPlayer): \(messageId)")
    }
    
    func stop() {
        player?.pause()
        player = nil
        playerItem = nil
        currentlyPlayingId = nil
        cancellables.removeAll()
    }
    
    func pause() {
        player?.pause()
    }
    
    func resume() {
        player?.play()
    }
}
