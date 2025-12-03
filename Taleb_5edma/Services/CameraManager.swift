//
//  CameraManager.swift
//  Taleb_5edma
//
//  Camera capture matching Android MediaStreamManager
//

import AVFoundation
import UIKit

class CameraManager: NSObject {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var currentCamera: AVCaptureDevice?
    private var isFrontCamera = true
    private var isCapturing = false
    
    // Frame rate control
    private var lastFrameTime: TimeInterval = 0
    private let minFrameInterval: TimeInterval = 0.1 // 10 FPS (100ms)
    
    // Quality settings
    private var compressionQuality: CGFloat = 0.6 // Match Android's 60%
    
    // Callbacks
    var onFrameCaptured: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onStateChanged: ((String) -> Void)?
    
    // MARK: - Setup
    
    func startCapture() {
        guard !isCapturing else { return }
        
        checkPermissions { [weak self] granted in
            guard granted else {
                self?.onError?("Camera permission required")
                return
            }
            self?.setupCaptureSession()
        }
    }
    
    private func checkPermissions(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
        default:
            completion(false)
        }
    }
    
    private func setupCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            session.sessionPreset = .medium // 480x360 to match Android
            
            // Get camera
            guard let camera = self.getCamera(front: self.isFrontCamera) else {
                self.onError?("No camera found")
                return
            }
            
            self.currentCamera = camera
            
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                // Video output
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                
                if session.canAddOutput(videoOutput) {
                    session.addOutput(videoOutput)
                }
                
                self.videoOutput = videoOutput
                self.captureSession = session
                
                session.startRunning()
                self.isCapturing = true
                
                DispatchQueue.main.async {
                    self.onStateChanged?("✅ Camera streaming started")
                }
                
            } catch {
                self.onError?("Camera setup failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func getCamera(front: Bool) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
        let position: AVCaptureDevice.Position = front ? .front : .back
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        )
        
        return discoverySession.devices.first
    }
    
    // MARK: - Camera Control
    
    func switchCamera() {
        guard isCapturing else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.stopCapture()
            self.isFrontCamera.toggle()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.startCapture()
            }
        }
    }
    
    func stopCapture() {
        guard isCapturing else { return }
        
        captureSession?.stopRunning()
        captureSession = nil
        videoOutput = nil
        currentCamera = nil
        isCapturing = false
        
        onStateChanged?("Camera stopped")
    }
    
    // MARK: - Preview Layer
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
    
    // MARK: - Quality Control
    
    func setCompressionQuality(_ quality: CGFloat) {
        compressionQuality = max(0.1, min(1.0, quality))
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Frame rate limiting (match Android's minFrameInterval)
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastFrameTime >= minFrameInterval else { return }
        lastFrameTime = currentTime
        
        // Convert to UIImage
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: nil)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        var image = UIImage(cgImage: cgImage)
        
        // Apply rotation correction for front camera
        if isFrontCamera {
            image = image.rotate(radians: .pi / 2) ?? image // 90 degrees
        }
        
        // Convert to JPEG → Base64 (match Android)
        guard let jpegData = image.jpegData(compressionQuality: compressionQuality) else { return }
        let base64String = jpegData.base64EncodedString()
        
        onFrameCaptured?(base64String)
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func rotate(radians: CGFloat) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: radians)).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        context.rotate(by: radians)
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
