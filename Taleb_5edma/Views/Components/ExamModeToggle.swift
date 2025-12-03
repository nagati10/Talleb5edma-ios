//
//  ExamModeToggle.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Toggle switch large pour activer/désactiver le mode examens
struct ExamModeToggle: View {
    @Binding var isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    init(isEnabled: Binding<Bool>, onToggle: @escaping (Bool) -> Void = { _ in }) {
        self._isEnabled = isEnabled
        self.onToggle = onToggle
    }
    
    var body: some View {
        GenericCard {
            VStack(spacing: 16) {
                // En-tête avec état
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mode Examens")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.black)
                        
                        Text("Protège votre temps d'études")
                            .font(.caption)
                            .foregroundColor(AppColors.mediumGray)
                    }
                    
                    Spacer()
                    
                    // État ON/OFF dans une box centrale
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isEnabled ? AppColors.primaryRed.opacity(0.2) : AppColors.lightGray.opacity(0.2))
                        
                        Text(isEnabled ? "ON" : "OFF")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(isEnabled ? AppColors.primaryRed : AppColors.mediumGray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                }
                
                // Toggle switch large
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .toggleStyle(CustomToggleStyle())
                    .onChange(of: isEnabled) { _, newValue in
                        onToggle(newValue)
                    }
            }
        }
    }
}

/// Style personnalisé pour le toggle
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                configuration.isOn.toggle()
            }
        }) {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                // Background
                RoundedRectangle(cornerRadius: 25)
                    .fill(configuration.isOn ? AppColors.primaryRed : AppColors.lightGray)
                    .frame(width: 60, height: 32)
                
                // Cercle
                Circle()
                    .fill(AppColors.white)
                    .frame(width: 26, height: 26)
                    .padding(3)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ExamModeToggle(isEnabled: .constant(false))
        ExamModeToggle(isEnabled: .constant(true))
    }
    .padding()
    .background(AppColors.backgroundGray)
}

