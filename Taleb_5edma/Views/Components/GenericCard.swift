//
//  GenericCard.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Carte générique réutilisable avec style cohérent
/// Utilise la palette de couleurs de Taleb 5edma
struct GenericCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color
    var cornerRadius: CGFloat
    var shadowOpacity: Double
    var padding: CGFloat
    
    init(
        backgroundColor: Color = AppColors.white,
        cornerRadius: CGFloat = 12,
        shadowOpacity: Double = 0.1,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowOpacity = shadowOpacity
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(shadowOpacity), radius: 2, x: 0, y: 1)
    }
}

/// Carte avec titre et contenu
struct TitledCard<Content: View>: View {
    let title: String
    let titleColor: Color
    let content: Content
    var spacing: CGFloat
    
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
        GenericCard {
            VStack(alignment: .leading, spacing: spacing) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(titleColor)
                
                content
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GenericCard {
            Text("Contenu simple")
        }
        
        TitledCard(title: "Titre de Section") {
            Text("Contenu avec titre")
        }
        
        GenericCard(backgroundColor: AppColors.backgroundGray) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(AppColors.primaryRed)
                Text("Carte avec fond gris")
            }
        }
    }
    .padding()
    .background(AppColors.backgroundGray)
}

