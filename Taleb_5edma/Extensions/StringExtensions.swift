//
//  StringExtensions.swift
//  Taleb_5edma
//
//  Created by Enhanced Chat Features
//

import Foundation

extension String {
    /// Detects if the string contains only emojis (1-10 emojis allowed)
    func isEmojiOnly() -> Bool {
        guard !self.isEmpty else { return false }
        
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        // Remove all whitespace to count emojis
        let noWhitespace = trimmed.filter { !$0.isWhitespace }
        
        // Count should be between 1 and 10
        guard (1...10).contains(noWhitespace.count) else { return false }
        
        // Check if all non-whitespace characters are emojis
        return trimmed.allSatisfy { char in
            char.isWhitespace || char.isEmoji
        }
    }
}

extension Character {
    /// Check if character is an emoji
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}
