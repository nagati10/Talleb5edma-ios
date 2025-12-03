//
//  ManualActivityHoursView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Vue pour ajouter/modifier les heures d'activités manuelles
struct ManualActivityHoursView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var heures: String = ""
    @State private var isEditing: Bool = false
    
    let semaineDebut: String
    let heuresActuelles: Double
    let onSave: (Double) -> Void
    
    init(semaineDebut: String, heuresActuelles: Double = 0, onSave: @escaping (Double) -> Void) {
        self.semaineDebut = semaineDebut
        self.heuresActuelles = heuresActuelles
        self.onSave = onSave
        _heures = State(initialValue: heuresActuelles > 0 ? String(format: "%.1f", heuresActuelles) : "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header informatif
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(Color(hex: "#F39C12"))
                    
                    Text("Heures d'activités manuelles")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.black)
                    
                    Text("Ajoutez des heures d'activités personnelles qui ne sont pas liées à des événements spécifiques")
                        .font(.subheadline)
                        .foregroundColor(AppColors.mediumGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Afficher la semaine
                    Text("Semaine du \(formaterDate(semaineDebut))")
                        .font(.caption)
                        .foregroundColor(AppColors.mediumGray)
                        .padding(.top, 4)
                }
                .padding(.top, 20)
                
                // Champ de saisie
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nombre d'heures")
                        .font(.headline)
                        .foregroundColor(AppColors.black)
                    
                    HStack {
                        TextField("0.0", text: $heures)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.black)
                            .padding()
                            .background(AppColors.backgroundGray)
                            .cornerRadius(12)
                        
                        Text("heures")
                            .font(.headline)
                            .foregroundColor(AppColors.mediumGray)
                    }
                    
                    Text("Exemple: 5.5 pour 5 heures et 30 minutes")
                        .font(.caption)
                        .foregroundColor(AppColors.mediumGray)
                }
                .padding()
                .background(AppColors.white)
                .cornerRadius(16)
                
                // Bouton de sauvegarde
                Button(action: {
                    saveHours()
                }) {
                    Text(heuresActuelles > 0 ? "Mettre à jour" : "Ajouter")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryRed)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Bouton de suppression (si des heures existent)
                if heuresActuelles > 0 {
                    Button(action: {
                        deleteHours()
                    }) {
                        Text("Supprimer")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryRed)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primaryRed.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .background(AppColors.backgroundGray)
            .navigationTitle("Heures d'activités")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
            }
        }
    }
    
    private func saveHours() {
        guard let heuresValue = Double(heures.replacingOccurrences(of: ",", with: ".")),
              heuresValue >= 0 else {
            // Afficher une alerte d'erreur
            return
        }
        
        onSave(heuresValue)
        dismiss()
    }
    
    private func deleteHours() {
        onSave(0)
        dismiss()
    }
    
    private func formaterDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale(identifier: "fr_FR")
            displayFormatter.dateFormat = "d MMMM yyyy"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

#Preview {
    ManualActivityHoursView(
        semaineDebut: "2025-01-13",
        heuresActuelles: 5.5,
        onSave: { _ in }
    )
}

