//
//  EmojiPickerView.swift
//  Taleb_5edma
//
//  Created by Enhanced Chat Features
//

import SwiftUI

/// Emoji picker with categorized emojis
struct EmojiPickerView: View {
    @Binding var selectedCategory: String
    let onEmojiSelected: (String) -> Void
    
    private let emojiCategories: [String: [String]] = [
        "Smileys": [
            "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙", "😚", "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎", "🤩", "🥳", "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "☹️", "😣", "😖", "😫", "😩", "🥺", "😢", "😭"
        ],
        "Hearts": [
            "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝"
        ],
        "Hands": [
            "👍", "👎", "👊", "✊", "🤛", "🤜", "🤞", "✌️", "🤟", "🤘", "👌", "👈", "👉", "👆", "👇", "☝️", "✋", "🤚", "🖐️", "🖖", "👋", "🤙", "💪", "🦾", "🖕", "✍️", "🙏"
        ],
        "Celebration": [
            "🎉", "🎊", "🎁", "🎈", "🎂", "🍰", "🧁", "🥳", "🍾", "🍻", "🥂", "🎇", "🎆", "✨", "🎄", "🎅", "🤶", "👼", "💫", "⭐", "🌟", "💥", "🔥", "💯"
        ]
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(emojiCategories.keys.sorted()), id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category)
                                .font(.system(size: 12, weight: selectedCategory == category ? .semibold : .regular))
                                .foregroundColor(selectedCategory == category ? AppColors.primaryRed : AppColors.mediumGray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    selectedCategory == category ?
                                    AppColors.primaryRed.opacity(0.1) : Color.clear
                                )
                        }
                    }
                }
            }
            .background(AppColors.white)
            
            Divider()
            
            // Emoji grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                    ForEach(emojiCategories[selectedCategory] ?? [], id: \.self) { emoji in
                        Button(action: {
                            onEmojiSelected(emoji)
                        }) {
                            Text(emoji)
                                .font(.system(size: 28))
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                .padding(8)
            }
            .frame(height: 200)
            .background(AppColors.white)
        }
    }
}

#Preview {
    EmojiPickerView(
        selectedCategory: .constant("Smileys"),
        onEmojiSelected: { emoji in
            print("Selected: \(emoji)")
        }
    )
}
