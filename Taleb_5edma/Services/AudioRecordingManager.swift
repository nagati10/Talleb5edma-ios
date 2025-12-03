//
//  AudioRecordingManager.swift
//  Taleb_5edma
//
//  Created by Enhanced Chat Features
//

import Foundation
import AVFoundation
import Combine

/// Manager for audio recording functionality
class AudioRecordingManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasPermission = false
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var currentRecordingURL: URL?
    
    // MARK: - Initialization
    override init() {
        super.init()
        checkPermission()
    }
    
    // MARK: - Permission Handling
    func checkPermission() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                hasPermission = true
            case .denied:
                hasPermission = false
            case .undetermined:
                hasPermission = false
            @unknown default:
                hasPermission = false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                hasPermission = true
            case .denied:
                hasPermission = false
            case .undetermined:
                hasPermission = false
            @unknown default:
                hasPermission = false
            }
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.hasPermission = granted
                    completion(granted)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.hasPermission = granted
                    completion(granted)
                }
            }
        }
    }
    
    // MARK: - Recording Functions
    func startRecording() throws -> Bool {
        guard hasPermission else {
            print("❌ No microphone permission")
            return false
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        
        // Create recording URL with timestamp
        let fileName = "voice_message_\(Date().timeIntervalSince1970).m4a"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        currentRecordingURL = fileURL
        
        // Configure recorder settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.prepareToRecord()
        
        guard audioRecorder?.record() == true else {
            print("❌ Failed to start recording")
            return false
        }
        
        // Start tracking duration
        isRecording = true
        recordingStartTime = Date()
        recordingDuration = 0
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.recordingDuration = Date().timeIntervalSince(startTime)
        }
        
        print("✅ Recording started: \(fileURL.lastPathComponent)")
        return true
    }
    
    func stopRecording() -> (url: URL, duration: TimeInterval)? {
        guard isRecording, let recorder = audioRecorder else {
            return nil
        }
        
        recorder.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        
        let duration = recordingDuration
        recordingDuration = 0
        recordingStartTime = nil
        
        guard let url = currentRecordingURL else {
            return nil
        }
        
        print("✅ Recording stopped: \(url.lastPathComponent), duration: \(duration)s")
        return (url, duration)
    }
    
    func cancelRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        recordingDuration = 0
        recordingStartTime = nil
        
        // Delete the file
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
            print("🗑️ Recording cancelled and deleted")
        }
        
        currentRecordingURL = nil
    }
    
    // MARK: - Cleanup
    deinit {
        cancelRecording()
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecordingManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("❌ Recording failed")
            cancelRecording()
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ Recording encode error: \(error?.localizedDescription ?? "unknown")")
        cancelRecording()
    }
}
