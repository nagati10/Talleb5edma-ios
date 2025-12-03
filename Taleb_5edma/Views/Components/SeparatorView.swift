//
//  SeparatorView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Séparateur réutilisable avec texte au centre (ex: "OR")
struct SeparatorView: View {
    let text: String
    let color: Color
    
    init(
        text: String = "OR",
        color: Color = AppColors.lightGray
    ) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(height: 1)
            
            Text(text)
                .foregroundColor(AppColors.black.opacity(0.5))
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
            
            Rectangle()
                .fill(color)
                .frame(height: 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

#Preview {
    SeparatorView()
        .padding()
}

