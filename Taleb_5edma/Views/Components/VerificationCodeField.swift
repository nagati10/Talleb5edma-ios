//
//  VerificationCodeField.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import SwiftUI

/// Champ de saisie pour le code de vérification à 6 chiffres
/// Inspiré du design Toktok avec des cases individuelles
struct VerificationCodeField: View {
    // Code saisi côté parent, mis à jour caractère par caractère
    @Binding var code: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    index < code.count ? AppColors.primaryRed : AppColors.lightGray,
                                    lineWidth: 2
                                )
                        )
                        .frame(width: 50, height: 60)
                    
                    if index < code.count {
                        Text(String(code[code.index(code.startIndex, offsetBy: index)]))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.black)
                    }
                }
            }
        }
        .overlay(
            // Champ de texte invisible pour la saisie
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .opacity(0)
                .frame(width: 0, height: 0)
        )
        .onChange(of: code) { oldValue, newValue in
            // Limiter à 6 chiffres
            if newValue.count > 6 {
                code = String(newValue.prefix(6))
            }
            // Filtrer uniquement les chiffres
            code = newValue.filter { $0.isNumber }
        }
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    VerificationCodeField(code: .constant("112836"))
        .padding()
}

