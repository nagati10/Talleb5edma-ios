//
//  EditReclamationView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

struct EditReclamationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @ObservedObject var reclamationService: ReclamationService
    
    let reclamation: Reclamation
    
    @State private var selectedType: ReclamationType
    @State private var text: String
    @State private var date: String
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    init(reclamation: Reclamation, reclamationService: ReclamationService) {
        self.reclamation = reclamation
        self.reclamationService = reclamationService
        _selectedType = State(initialValue: reclamation.type)
        _text = State(initialValue: reclamation.text)
        
        // Formater la date au format YYYY-MM-DD si elle existe
        let initialDate: String
        if let dateString = reclamation.date {
            // Si la date contient "T" (format ISO), extraire seulement la partie date
            if dateString.contains("T") {
                initialDate = String(dateString.prefix(10))
            } else {
                initialDate = dateString
            }
        } else {
            // Si pas de date, utiliser la date du jour
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            initialDate = dateFormatter.string(from: Date())
        }
        _date = State(initialValue: initialDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Type de réclamation
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Type de réclamation")
                                .font(.headline)
                                .foregroundColor(AppColors.black)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(ReclamationType.allCases, id: \.self) { type in
                                    Button(action: {
                                        selectedType = type
                                    }) {
                                        HStack {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 16))
                                            Text(type.rawValue)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(selectedType == type ? .white : AppColors.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedType == type ? AppColors.primaryRed : AppColors.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedType == type ? AppColors.primaryRed : AppColors.lightGray, lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .cardStyle()
                        
                        // Texte de la réclamation
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(AppColors.black)
                            
                            TextEditor(text: $text)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(AppColors.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.lightGray, lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }
                        .cardStyle()
                        
                        // Date
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date")
                                .font(.headline)
                                .foregroundColor(AppColors.black)
                            
                            TextField("YYYY-MM-DD", text: $date)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.default)
                        }
                        .cardStyle()
                    }
                    .padding()
                }
            }
            .navigationTitle("Modifier la réclamation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        saveReclamation()
                    }
                    .foregroundColor(AppColors.primaryRed)
                    .disabled(isSubmitting || text.isEmpty)
                }
            }
            .alert("Réclamation modifiée", isPresented: $showSuccess) {
                Button("OK") {
                    // Recharger la liste avant de fermer
                    Task {
                        await reclamationService.loadReclamations()
                    }
                    dismiss()
                }
            } message: {
                Text("Votre réclamation a été modifiée avec succès.")
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Une erreur est survenue")
            }
        }
    }
    
    private func saveReclamation() {
        guard !text.isEmpty else {
            errorMessage = "Le texte de la réclamation ne peut pas être vide"
            showError = true
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                // Formater la date au format YYYY-MM-DD si elle est fournie
                var formattedDate: String? = nil
                if !date.isEmpty {
                    // Si la date contient "T" (format ISO), extraire seulement la partie date
                    if date.contains("T") {
                        formattedDate = String(date.prefix(10))
                    } else {
                        // Vérifier que c'est au format YYYY-MM-DD
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        if dateFormatter.date(from: date) != nil {
                            formattedDate = date
                        } else {
                            // Essayer de parser et reformater
                            if let parsedDate = ISO8601DateFormatter().date(from: date) {
                                formattedDate = dateFormatter.string(from: parsedDate)
                            } else {
                                formattedDate = date
                            }
                        }
                    }
                }
                
                // Inclure le userId pour que le backend puisse vérifier la propriété
                let request = UpdateReclamationRequest(
                    type: selectedType,
                    text: text,
                    date: formattedDate,
                    userId: authService.currentUser?.id
                )
                
                _ = try await reclamationService.updateReclamation(reclamation.id, request: request)
                
                // Recharger la liste
                await reclamationService.loadReclamations()
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    if let reclamationError = error as? ReclamationError {
                        errorMessage = reclamationError.errorDescription
                    } else {
                        errorMessage = "Erreur lors de la modification: \(error.localizedDescription)"
                    }
                    showError = true
                }
            }
        }
    }
}

#Preview {
    EditReclamationView(
        reclamation: Reclamation(
            id: "1",
            userId: "user1",
            userName: "Test User",
            type: ReclamationType.technique,
            text: "Test reclamation",
            date: "2025-11-17",
            status: ReclamationStatus.pending,
            createdAt: Date(),
            updatedAt: Date()
        ),
        reclamationService: ReclamationService()
    )
}

