//
//  AudioCaptureManager.swift
//  Taleb_5edma
//
//  Audio capture matching Android MediaStreamManager
//

import AVFoundation
import Foundation

class AudioCaptureManager {
    
    // MARK: - Properties
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var isRecording = false
    
    // Voice Activity Detection (VAD)
    private var isSpeaking = false
    private var silenceFrames = 0
    private let silenceThreshold = 5
    private let voiceThreshold: Float = 10.0
    
    // Callbacks
    var onAudioData: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onSpeakingStateChanged: ((Bool) -> Void)?
    
    // MARK: - Setup
    
    func startCapture() {
        guard !isRecording else { return }
        
        checkPermissions { [weak self] granted in
            guard granted else {
                self?.onError?("Microphone permission required")
                return
            }
            self?.setupAudioEngine()
        }
    }
    
    private func checkPermissions(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission(completion)
    }
    
    private func setupAudioEngine() {
        do {
            // Configure audio session with settings compatible with AVAudioEngine
            let audioSession = AVAudioSession.sharedInstance()
            
            // Use .playAndRecord with .voiceChat mode - this is more compatible with AVAudioEngine
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
            
            // Explicitly set preferred sample rate to match Android (16kHz)
            try audioSession.setPreferredSampleRate(16000.0)
            
            // Prefer mono to match Android
            try audioSession.setPreferredInputNumberOfChannels(1)
            
            try audioSession.setActive(true)
            
            print("✅ Audio session configured: \(audioSession.sampleRate)Hz, \(audioSession.inputNumberOfChannels) channels")
            
            // Setup audio engine
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { 
                onError?("Failed to create audio engine")
                return 
            }
            
            inputNode = audioEngine.inputNode
            guard let inputNode = inputNode else { 
                onError?("Failed to get input node")
                return 
            }
            
            // Remove any existing tap
            inputNode.removeTap(onBus: 0)
            
            // Get the format the hardware will provide
            let hardwareFormat = inputNode.outputFormat(forBus: 0)
            print("📊 Hardware format: \(hardwareFormat.sampleRate)Hz, \(hardwareFormat.channelCount) ch")
            print("🎧 Installing tap with engine's default format")
            
            // Install tap with nil format - let the engine choose
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, time in
                self?.processAudioBuffer(buffer)
            }
            
            // Prepare and start
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            
            print("✅ Audio capture started successfully")
            
        } catch let error as NSError {
            let errorMsg = "Audio setup failed: \(error.localizedDescription) (Code: \(error.code))"
            print("❌ \(errorMsg)")
            onError?(errorMsg)
            
            // Clean up on error
            audioEngine?.stop()
            audioEngine = nil
            inputNode = nil
            isRecording = false
        }
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Get float channel data (hardware format is usually Float32)
        guard let floatChannelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let inputSampleRate = buffer.format.sampleRate
        let targetSampleRate = 16000.0
        
        // If sample rates match, no conversion needed
        let floatSamples: [Float]
        if inputSampleRate == targetSampleRate {
            floatSamples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
        } else {
            // Resample from hardware rate (e.g., 48kHz) to 16kHz
            floatSamples = resampleAudio(
                Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength)),
                fromRate: inputSampleRate,
                toRate: targetSampleRate
            )
        }
        
        // Convert Float32 (-1.0 to 1.0) to Int16 (-32768 to 32767)
        let int16Samples: [Int16] = floatSamples.map { floatSample in
            let clampedValue = max(-1.0, min(1.0, floatSample))
            return Int16(clampedValue * 32767.0)
        }
        
        // Voice Activity Detection
        let voiceDetected = detectVoice(in: int16Samples)
        
        if voiceDetected {
            sendAudioData(samples: int16Samples)
        }
    }
    
    // Simple linear resampling
    private func resampleAudio(_ samples: [Float], fromRate: Double, toRate: Double) -> [Float] {
        if fromRate == toRate { return samples }
        
        let ratio = fromRate / toRate
        let outputLength = Int(Double(samples.count) / ratio)
        var resampled = [Float]()
        resampled.reserveCapacity(outputLength)
        
        for i in 0..<outputLength {
            let sourceIndex = Double(i) * ratio
            let lower = Int(sourceIndex)
            let upper = min(lower + 1, samples.count - 1)
            let fraction = Float(sourceIndex - Double(lower))
            
            // Linear interpolation
            let interpolated = samples[lower] * (1.0 - fraction) + samples[upper] * fraction
            resampled.append(interpolated)
        }
        
        return resampled
    }
    
    private func detectVoice(in samples: [Int16]) -> Bool {
        // Calculate RMS (Root Mean Square)
        var sum: Float = 0.0
        for sample in samples {
            let normalized = Float(sample)
            sum += normalized * normalized
        }
        
        let rms = sqrt(sum / Float(samples.count))
        
        let wasSpeaking = isSpeaking
        
        if rms > voiceThreshold {
            isSpeaking = true
            silenceFrames = 0
        } else {
            if isSpeaking {
                silenceFrames += 1
                if silenceFrames > silenceThreshold {
                    isSpeaking = false
                }
            }
        }
        
        if wasSpeaking != isSpeaking {
            onSpeakingStateChanged?(isSpeaking)
        }
        
        return isSpeaking
    }
    
    private func sendAudioData(samples: [Int16]) {
        // Convert Int16 array to Data
        let data = Data(bytes: samples, count: samples.count * MemoryLayout<Int16>.size)
        
        // Encode to Base64 (match Android)
        let base64String = data.base64EncodedString()
        
        onAudioData?(base64String)
    }
    
    // MARK: - Control
    
    func stopCapture() {
        guard isRecording else { return }
        
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        isRecording = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
        
        print("⏹️ Audio capture stopped")
    }
    
    func setVoiceSensitivity(_ threshold: Float) {
        // Allow adjusting voice detection threshold
    }
}
