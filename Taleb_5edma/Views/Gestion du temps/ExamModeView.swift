//
//  ExamModeView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

//
//  ExamModeView.swift
//  Taleb_5edma
//

import SwiftUI

struct ExamModeView: View {
    @Environment(\.presentationMode) var presentationMode
    // Modèle métier représentant les préférences d'examen
    @State private var examMode: ExamMode = ExamMode()
    // Contrôle l'affichage de l'alerte de confirmation
    @State private var showingSaveAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
                    // Période d'examens
                    periodSection
                    
                    // Options de personnalisation
                    customizationSection
                    
                    // Bouton d'activation
                    activationButton
                }
                .padding()
            }
            .background(AppColors.backgroundGray)
            .navigationTitle("Mode Examens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
            }
            .alert("Mode examens activé", isPresented: $showingSaveAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Le mode examens est maintenant activé jusqu'au \(formattedEndDate). Vos préférences ont été enregistrées.")
            }
        }
    }
    
    // MARK: - Sections de l'interface
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.primaryRed)
                
                Text("Taleb Sedma - Mode Examens")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryRed)
            }
            
            Text("Configurez vos préférences pour la période d'examens")
                .font(.subheadline)
                .foregroundColor(AppColors.mediumGray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var periodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Période d'examens")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            VStack(spacing: 12) {
                DatePicker("Du:", selection: $examMode.startDate, displayedComponents: .date)
                    .onChange(of: examMode.startDate) { oldValue, newValue in
                        if newValue > examMode.endDate {
                            examMode.endDate = newValue.addingTimeInterval(86400 * 11)
                        }
                    }
                
                DatePicker("Au:", selection: $examMode.endDate, in: examMode.startDate..., displayedComponents: .date)
                
                HStack {
                    Text("Durée:")
                    Spacer()
                    Text("\(examMode.duration) jours")
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryRed)
                }
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tu peux personnaliser")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            VStack(spacing: 16) {
                ToggleOption(
                    isOn: $examMode.blockNewOffers,
                    title: "Bloquer nouvelles offres",
                    subtitle: "Ne reçois pas de nouvelles offres de job"
                )
                
                ToggleOption(
                    isOn: $examMode.hideJobNotifications,
                    title: "Masquer notifications jobs",
                    subtitle: "Désactive les notifications liées aux jobs"
                )
                
                ToggleOption(
                    isOn: $examMode.keepAcceptedJobs,
                    title: "Conserver jobs acceptés",
                    subtitle: "Maintient les jobs déjà acceptés"
                )
                
                ToggleOption(
                    isOn: $examMode.revisionReminders,
                    title: "Rappels révision",
                    subtitle: "Active les rappels pour tes séances de révision"
                )
                
                ToggleOption(
                    isOn: $examMode.breakSuggestions,
                    title: "Suggestions pauses",
                    subtitle: "Reçois des suggestions pour tes pauses"
                )
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var activationButton: some View {
        Button(action: {
            // Sauvegarder les préférences et activer le mode
            examMode.isActive = true
            saveExamModePreferences()
            showingSaveAlert = true
        }) {
            Text("Activer le Mode Examens")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(examMode.isValid ? AppColors.primaryRed : AppColors.mediumGray)
                .cornerRadius(12)
        }
        .disabled(!examMode.isValid)
        .padding(.top, 20)
    }
    
    // MARK: - Helper Methods
    
    private var formattedEndDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: examMode.endDate)
    }
    
    private func saveExamModePreferences() {
        // Ici vous sauvegarderez les préférences plus tard
        // Pour l'instant, on simule la sauvegarde
        print("Mode examens sauvegardé: \(examMode)")
        
        // Exemple de sauvegarde dans UserDefaults
        if let encoded = try? JSONEncoder().encode(examMode) {
            UserDefaults.standard.set(encoded, forKey: "examModePreferences")
        }
    }
}

// Extension pour la validation
extension ExamMode {
    var isValid: Bool {
        return endDate > startDate
    }
}

// Composant réutilisable pour les options Toggle
struct ToggleOption: View {
    @Binding var isOn: Bool
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: $isOn) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.black)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppColors.mediumGray)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: AppColors.primaryRed))
        }
    }
}

#Preview {
    ExamModeView()
}
