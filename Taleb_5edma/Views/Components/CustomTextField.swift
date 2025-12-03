//
//  CustomTextField.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import SwiftUI

/// Champ de texte personnalisé inspiré du design Toktok
/// Avec bordure en bas et style moderne
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    // Utilisé pour synchroniser l'état d'affichage du mot de passe avec la vue parente
    @Binding var isPasswordVisible: Bool
    var isSecure: Bool = false
    var showPasswordToggle: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                if showPasswordToggle {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(AppColors.mediumGray)
                    }
                }
            }
            .padding(.vertical, 12)
            
            // Ligne de bordure en bas avec gradient rouge bordeaux
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.primaryRed.opacity(0.6), AppColors.primaryRed],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)
        }
    }
}

#Preview {
    CustomTextField(
        placeholder: "Enter email",
        text: .constant(""),
        isPasswordVisible: .constant(false)
    )
    .padding()
}

