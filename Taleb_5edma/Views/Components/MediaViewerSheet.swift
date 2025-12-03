//
//  MediaViewerSheet.swift
//  Taleb_5edma
//
//  Created by Enhanced Chat Features
//

import SwiftUI
import AVKit

/// Full-screen media viewer for images and videos
struct MediaViewerSheet: View {
    let mediaUrl: String
    let mediaType: MediaType
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    enum MediaType {
        case image
        case video
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Media content
            switch mediaType {
            case .image:
                imageView
            case .video:
                videoView
            }
            
            // Close button overlay (always on top)
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 44, height: 44)
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            let fullUrl = buildMediaURL()
            print("🖼️ MediaViewer - Opening \(mediaType): \(fullUrl)")
        }
    }
    
    private var imageView: some View {
        let fullUrl = buildMediaURL()
        
        return AsyncImage(url: URL(string: fullUrl)) { phase in
            switch phase {
            case .empty:
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("Loading image...")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(magnificationGesture.simultaneously(with: dragGesture))
            case .failure(let error):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    Text("Failed to load image")
                        .foregroundColor(.white)
                        .font(.headline)
                    Text(error.localizedDescription)
                        .foregroundColor(.gray)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text("URL: \(fullUrl)")
                        .foregroundColor(.gray)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var videoView: some View {
        let fullUrl = buildMediaURL()
        
        return Group {
            if let url = URL(string: fullUrl) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    Text("Invalid video URL")
                        .foregroundColor(.white)
                        .font(.headline)
                    Text("URL: \(fullUrl)")
                        .foregroundColor(.gray)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1), 4) // Limit zoom between 1x and 4x
            }
            .onEnded { _ in
                lastScale = 1.0
                // Reset to 1x if zoomed out too much
                if scale < 1 {
                    withAnimation {
                        scale = 1
                        offset = .zero
                    }
                }
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
                
                // Reset offset if scale is 1
                if scale == 1 {
                    withAnimation {
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }
    
    private func buildMediaURL() -> String {
        // If already a full URL, return as is
        if mediaUrl.starts(with: "http://") || mediaUrl.starts(with: "https://") {
            return mediaUrl
        }
        
        // Build full URL from relative path
        let baseURL = APIConfig.baseURL
        
        if mediaUrl.starts(with: "/") {
            // Absolute path on server
            return baseURL + mediaUrl
        } else if mediaUrl.starts(with: "uploads/") {
            // Relative path
            return baseURL + "/" + mediaUrl
        } else {
            // Default: treat as relative path
            return baseURL + "/" + mediaUrl
        }
    }
}

#Preview {
    MediaViewerSheet(
        mediaUrl: "https://picsum.photos/800/600",
        mediaType: .image
    )
}
