//
//  MediaPickerView.swift
//  Taleb_5edma
//
//  Created by Enhanced Chat Features
//

import SwiftUI
import PhotosUI

struct PendingMedia: Identifiable {
    let id = UUID()
    let data: Data
    let type: MessageType
    let fileName: String
}

/// SwiftUI wrapper for PHPickerViewController
struct MediaPickerView: UIViewControllerRepresentable {
    @Binding var selectedMedia: [PendingMedia]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = 10 // Allow up to 10 items
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MediaPickerView
        
        init(_ parent: MediaPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard !results.isEmpty else { return }
            
            for result in results {
                let itemProvider = result.itemProvider
                
                // Check for images
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        guard let self = self, let image  = image as? UIImage else { return }
                        
                        if let data = image.jpegData(compressionQuality: 0.8) {
                            let fileName = "image_\(Date().timeIntervalSince1970).jpg"
                            let media = PendingMedia(data: data, type: .image, fileName: fileName)
                            
                            DispatchQueue.main.async {
                                self.parent.selectedMedia.append(media)
                            }
                        }
                    }
                }
                // Check for videos
                else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                        guard let self = self, let url = url else { return }
                        
                        do {
                            let data = try Data(contentsOf: url)
                            let fileName = "video_\(Date().timeIntervalSince1970).mp4"
                            let media = PendingMedia(data: data, type: .video, fileName: fileName)
                            
                            DispatchQueue.main.async {
                                self.parent.selectedMedia.append(media)
                            }
                        } catch {
                            print("❌ Failed to load video: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}
