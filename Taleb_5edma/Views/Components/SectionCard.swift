//
//  SectionCard.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Carte de section réutilisable avec titre et style cohérent
struct SectionCard<Content: View>: View {
    let title: String
    let titleColor: Color
    let content: Content
    let spacing: CGFloat
    
    init(
        title: String,
        titleColor: Color = AppColors.primaryRed,
        spacing: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleColor = titleColor
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(titleColor)
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    VStack {
        SectionCard(title: "Titre de Section") {
            Text("Contenu de la section")
        }
        .padding()
    }
    .background(AppColors.backgroundGray)
}

