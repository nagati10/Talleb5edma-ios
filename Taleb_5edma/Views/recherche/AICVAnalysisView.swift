//
//  AICVAnalysisView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

//
//  AICVAnalysisView.swift
//  Taleb_5edma
//

import SwiftUI

struct AICVAnalysisView: View {
    @Environment(\.presentationMode) var presentationMode
    // Présente le sélecteur d'image pour importer un CV
    @State private var showingImagePicker = false
    // Stocke l'image du CV sélectionnée par l'utilisateur
    @State private var cvImage: UIImage?
    // Indicateur de progression pendant l'analyse IA
    @State private var isAnalyzing = false
    // Passe à l'écran de résultats une fois l'analyse terminée
    @State private var analysisComplete = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if !analysisComplete {
                        // Upload du CV
                        uploadSection
                    } else {
                        // Résultats de l'analyse
                        analysisResultsSection
                    }
                }
                .padding()
            }
            .background(AppColors.backgroundGray)
            .navigationTitle("Analyse CV IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                // Intégrer un sélecteur d'image réel
                Text("Sélecteur d'image à intégrer")
            }
        }
    }
    
    private var uploadSection: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primaryRed)
                
                Text("Analysez votre CV avec l'IA")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryRed)
                
                Text("Générez ou analysez votre CV avec l'intelligence artificielle")
                    .font(.subheadline)
                    .foregroundColor(AppColors.mediumGray)
                    .multilineTextAlignment(.center)
            }
            
            // Zone d'upload
            VStack(spacing: 16) {
                if let image = cvImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(AppColors.backgroundGray)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.mediumGray)
                                
                                Text("Ajoutez votre CV")
                                    .font(.headline)
                                    .foregroundColor(AppColors.mediumGray)
                            }
                        )
                        .cornerRadius(12)
                        .onTapGesture {
                            showingImagePicker = true
                        }
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("CV existant")
                        }
                        .font(.headline)
                        .foregroundColor(AppColors.primaryRed)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.primaryRed, lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        // Générer un CV avec IA
                        simulateAnalysis()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Générer CV IA")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryRed)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(AppColors.white)
            .cornerRadius(12)
            
            // Bouton d'analyse
            if cvImage != nil {
                Button(action: {
                    simulateAnalysis()
                }) {
                    if isAnalyzing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Analyser le CV")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primaryRed)
                .cornerRadius(12)
                .disabled(isAnalyzing)
            }
        }
    }
    
    private var analysisResultsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // En-tête du CV
            VStack(alignment: .leading, spacing: 8) {
                Text("DAVID MOREL")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.black)
                
                Text("DIRECTION TECHNIQUE")
                    .font(.title3)
                    .foregroundColor(AppColors.primaryRed)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(AppColors.white)
            .cornerRadius(12)
            
            // Compétences
            skillsSection
            
            // Langues
            languagesSection
            
            // Profil
            profileSection
            
            // Expériences
            experiencesSection
            
            // Bouton de nouvelle analyse
            Button(action: {
                resetAnalysis()
            }) {
                Text("Nouvelle Analyse")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primaryRed)
                    .cornerRadius(12)
            }
        }
    }
    
    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPÉTENCES")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Direction réduisive")
                    .font(.subheadline)
                Text("• Gestion de crise")
                    .font(.subheadline)
                Text("• Analyse d'entreprise")
                    .font(.subheadline)
                Text("• Gestion du produit technique")
                    .font(.subheadline)
                Text("• Résolution du problème")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var languagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LANGUES")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Anglais : Courant")
                    .font(.subheadline)
                Text("• Allemand : Intermédiaire (B1)")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROFIL")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            Text("Développeur technique, expérimenté, et qui a le sens de l'opportunité nouvelle. À l'écoute, je sais gérer une équipe et trouver des solutions adaptées aux besoins professionnels.")
                .font(.body)
                .foregroundColor(AppColors.black)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var experiencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXPÉRIENCES PROFESSIONNELLES")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            VStack(alignment: .leading, spacing: 16) {
                ExperienceRow(
                    title: "DIRECTEUR TECHNIQUE",
                    company: "Entreprise • Localisation",
                    duration: "2020 - Présent",
                    description: "Gestion d'une équipe de développement. Analyse des besoins clients et développement des solutions techniques."
                )
                
                ExperienceRow(
                    title: "DIRECTEUR TECHNIQUE INDUSTRIEL",
                    company: "Entreprise • Localisation",
                    duration: "2018 - 2020",
                    description: "Développement d'une équipe de 20 personnes. Gestion des équipements industriels et réalisation de budget."
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func simulateAnalysis() {
        isAnalyzing = true
        
        // Simuler le temps d'analyse
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isAnalyzing = false
            analysisComplete = true
        }
    }
    
    private func resetAnalysis() {
        cvImage = nil
        analysisComplete = false
    }
}

struct ExperienceRow: View {
    let title: String
    let company: String
    let duration: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.black)
            
            Text(company)
                .font(.caption)
                .foregroundColor(AppColors.mediumGray)
            
            Text(duration)
                .font(.caption2)
                .foregroundColor(AppColors.primaryRed)
            
            Text(description)
                .font(.caption)
                .foregroundColor(AppColors.black)
                .padding(.top, 4)
        }
        .padding()
        .background(AppColors.backgroundGray)
        .cornerRadius(8)
    }
}

#Preview {
    AICVAnalysisView()
}
