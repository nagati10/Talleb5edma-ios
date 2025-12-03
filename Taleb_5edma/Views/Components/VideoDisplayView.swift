//
//  VideoDisplayView.swift
//  Taleb_5edma
//
//  Displays video frames from Base64 strings
//

import SwiftUI

struct VideoDisplayView: View {
    let base64Frame: String?
    let contentMode: ContentMode
    
    var body: some View {
        Group {
            if let frameString = base64Frame,
               let image = decodeBase64ToImage(frameString) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.black
            }
        }
    }
    
    private func decodeBase64ToImage(_ base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}

// Preview for SwiftUI Canvas
struct VideoDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        VideoDisplayView(base64Frame: nil, contentMode: .fill)
            .previewLayout(.fixed(width: 300, height: 400))
    }
}
