//
//  NouvelleReclamationView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

//
//  NouvelleReclamationView.swift
//  Taleb_5edma
//

import SwiftUI

struct NouvelleReclamationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @ObservedObject var reclamationService: ReclamationService
    
    // Étape du parcours multi-écrans (0 à 3)
    @State private var currentStep = 0
    // Type de réclamation sélectionné par l'utilisateur
    @State private var selectedType: ReclamationType = .autre
    // Note de satisfaction (1 à 5)
    @State private var rating = 0
    // Commentaire libre associé à la réclamation
    @State private var comment = ""
    // Empêche les interactions pendant l'envoi
    @State private var isSubmitting = false
    // Déclenche l'alerte de confirmation à la fin du processus
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGray
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header avec progression
                    headerSection
                    
                    // Contenu de l'étape actuelle
                    Group {
                        switch currentStep {
                        case 0:
                            typeSelectionStep
                        case 1:
                            ratingStep
                        case 2:
                            commentStep
                        case 3:
                            validationStep
                        default:
                            typeSelectionStep
                        }
                    }
                    .transition(.opacity)
                    
                    Spacer()
                    
                    // Boutons de navigation
                    navigationButtons
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
            }
            .alert("Réclamation envoyée", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Votre réclamation a bien été enregistrée. Nous la traiterons dans les plus brefs délais.")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Barre de progression
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentStep ? AppColors.primaryRed : AppColors.lightGray)
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            
            Text(stepTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.primaryRed)
            
            Text(stepSubtitle)
                .font(.system(size: 14))
                .foregroundColor(AppColors.mediumGray)
        }
        .padding()
        .background(AppColors.white)
    }
    
    private var typeSelectionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choisir une réclamation")
                    .sectionHeaderStyle()
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(ReclamationType.allCases, id: \.self) { type in
                        Button(action: {
                            withAnimation {
                                selectedType = type
                            }
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(type.color)
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(type.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.black)
                                    
                                    Text(type.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.mediumGray)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                if selectedType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.primaryRed)
                                        .font(.system(size: 20))
                                } else {
                                    Circle()
                                        .stroke(AppColors.lightGray, lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            .padding()
                            .background(selectedType == type ? AppColors.primaryRed.opacity(0.1) : AppColors.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedType == type ? AppColors.primaryRed : AppColors.lightGray,
                                        lineWidth: selectedType == type ? 2 : 1
                                    )
                            )
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private var ratingStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            GenericCard {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Donnez votre avis")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.black)
                        
                        Text("Comment évaluez-vous votre expérience ?")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.mediumGray)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Étoiles de notation
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    rating = star
                                }
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 44))
                                    .foregroundColor(star <= rating ? AppColors.primaryRed : AppColors.lightGray)
                                    .scaleEffect(star <= rating ? 1.1 : 1.0)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Labels descriptifs
                    VStack(spacing: 8) {
                        Text(ratingDescription)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.primaryRed)
                        
                        Text(ratingDetail)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mediumGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    private var commentStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Description")
                    .sectionHeaderStyle()
                    .padding(.horizontal)
                
                GenericCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Décrivez votre réclamation en détail")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mediumGray)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $comment)
                                .frame(minHeight: 200)
                                .foregroundColor(AppColors.black)
                                .scrollContentBackground(.hidden)
                                .background(AppColors.backgroundGray)
                            
                            if comment.isEmpty {
                                Text("Décrivez votre problème ou votre suggestion...")
                                    .foregroundColor(AppColors.mediumGray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(8)
                        .background(AppColors.backgroundGray)
                        .cornerRadius(12)
                        
                        Text("Votre description nous aide à mieux comprendre et résoudre votre problème.")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.mediumGray)
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
    }
    
    private var validationStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Récapitulatif")
                    .sectionHeaderStyle()
                
                // Type de réclamation
                validationRow(
                    title: "Type",
                    value: selectedType.rawValue,
                    icon: selectedType.icon,
                    color: selectedType.color
                )
                
                // Note
                validationRow(
                    title: "Note",
                    value: "\(rating)/5",
                    icon: "star.fill",
                    color: AppColors.primaryRed
                )
                
                // Commentaire
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundColor(AppColors.primaryRed)
                            .frame(width: 20)
                        
                        Text("Commentaire")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.black)
                        
                        Spacer()
                    }
                    
                    if comment.isEmpty {
                        Text("Aucun commentaire")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mediumGray)
                            .italic()
                    } else {
                        Text(comment)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.black)
                            .padding()
                            .background(AppColors.backgroundGray)
                            .cornerRadius(8)
                    }
                }
                .cardStyle()
            }
            .padding()
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    Text("Retour")
                        .font(.headline)
                        .foregroundColor(AppColors.primaryRed)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.primaryRed, lineWidth: 2)
                        )
                        .cornerRadius(12)
                }
            }
            
            Button(action: {
                if currentStep == 3 {
                    submitReclamation()
                } else {
                    withAnimation {
                        currentStep += 1
                    }
                }
            }) {
                Text(currentStep == 3 ? "Soumettre" : "Continuer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canProceed ? AppColors.primaryRed : AppColors.lightGray)
                    .cornerRadius(12)
            }
            .disabled(!canProceed || isSubmitting)
        }
        .padding()
        .background(AppColors.white)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
    }
    
    // MARK: - Helper Methods
    
    private var stepTitle: String {
        switch currentStep {
        case 0: return "Type de réclamation"
        case 1: return "Votre avis"
        case 2: return "Description"
        case 3: return "Validation"
        default: return "Nouvelle réclamation"
        }
    }
    
    private var stepSubtitle: String {
        switch currentStep {
        case 0: return "Choisissez le type de votre réclamation"
        case 1: return "Évaluez votre expérience"
        case 2: return "Décrivez votre problème en détail"
        case 3: return "Vérifiez les informations"
        default: return "Créez une nouvelle réclamation"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true // Toujours vrai pour le type
        case 1: return rating > 0
        case 2: return true // Le commentaire est optionnel
        case 3: return true
        default: return false
        }
    }
    
    private var ratingDescription: String {
        switch rating {
        case 1: return "Très mauvais"
        case 2: return "Mauvais"
        case 3: return "Moyen"
        case 4: return "Bon"
        case 5: return "Excellent"
        default: return "Sélectionnez une note"
        }
    }
    
    private var ratingDetail: String {
        switch rating {
        case 1: return "Nous sommes désolés pour cette mauvaise expérience"
        case 2: return "Nous allons améliorer cela"
        case 3: return "Merci pour votre retour"
        case 4: return "Content que vous soyez satisfait"
        case 5: return "Merci pour votre excellente évaluation !"
        default: return "Sélectionnez de 1 à 5 étoiles"
        }
    }
    
    private func validationRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.black)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.primaryRed)
        }
        .padding()
        .cardStyle()
    }
    
    private func submitReclamation() {
        isSubmitting = true
        
        Task {
            do {
                // Formater la date au format YYYY-MM-DD
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: Date())
                
                let request = CreateReclamationRequest(
                    type: selectedType,
                    text: comment, // Le commentaire devient le texte
                    date: dateString,
                    userId: authService.currentUser?.id
                )
                
                _ = try await reclamationService.createReclamation(request)
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    // Gérer l'erreur
                    print("❌ Erreur lors de la création de la réclamation: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    NouvelleReclamationView(reclamationService: ReclamationService())
        .environmentObject(AuthService())
}
