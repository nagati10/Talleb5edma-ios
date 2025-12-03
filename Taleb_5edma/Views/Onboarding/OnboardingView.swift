//
//  OnboardingView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Écran d'onboarding pour collecter les préférences utilisateur après la première connexion
struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var currentSection = 0
    
    // Préférences utilisateur
    @State private var selectedEducationLevel: EducationLevel?
    @State private var selectedStudyField: StudyField?
    @State private var selectedSearchTypes: Set<SearchType> = []
    @State private var selectedMotivation: Motivation?
    @State private var selectedSoftSkills: Set<SoftSkill> = []
    @State private var languageLevels: [LanguageLevel] = [
        LanguageLevel(language: .arabic, level: .beginner),
        LanguageLevel(language: .french, level: .beginner),
        LanguageLevel(language: .english, level: .beginner)
    ]
    @State private var selectedInterests: Set<Interest> = []
    @State private var hasSecondHobby: Bool? = nil
    
    var body: some View {
        Group {
            // Vérifier que l'utilisateur est bien authentifié avant d'afficher l'onboarding
            if authService.isAuthenticated && authService.currentUser != nil && authService.authToken != nil {
                ZStack {
                    AppColors.backgroundGray
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Header avec progression
                        headerSection
                        
                        // Contenu scrollable
                        ScrollView {
                            VStack(spacing: 24) {
                                switch currentSection {
                                case 0:
                                    educationSection
                                case 1:
                                    searchPreferencesSection
                                case 2:
                                    skillsSection
                                case 3:
                                    languagesSection
                                case 4:
                                    interestsSection
                                default:
                                    educationSection
                                }
                            }
                            .padding()
                            .padding(.bottom, 100)
                        }
                        
                        // Boutons de navigation
                        navigationButtons
                    }
                }
                .onAppear {
                    // Vérifier à nouveau l'authentification au chargement
                    verifyAuthentication()
                    // Charger les préférences sauvegardées pour pré-remplir le formulaire
                    loadSavedPreferences()
                }
            } else {
                // L'utilisateur n'est pas authentifié : afficher un message et rediriger
                VStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primaryRed)
                    
                    Text("Authentification requise")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.black)
                    
                    Text("Vous devez vous connecter pour accéder à l'onboarding")
                        .font(.body)
                        .foregroundColor(AppColors.mediumGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        // Déclencher une déconnexion pour forcer l'affichage de l'écran de login
                        authService.logout()
                    }) {
                        Text("Se connecter")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primaryRed)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.backgroundGray)
            }
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue")
        }
    }
    
    // MARK: - Authentication Verification
    
    /// Vérifie que l'utilisateur est bien authentifié avant de permettre l'accès à l'onboarding
    private func verifyAuthentication() {
        // Vérifier que l'utilisateur a un token ET un profil utilisateur
        guard authService.authToken != nil,
              authService.currentUser != nil,
              authService.currentUser?.id != nil else {
            // Si l'utilisateur n'est pas authentifié, afficher une erreur
            viewModel.errorMessage = "Vous devez être connecté pour effectuer cette action"
            viewModel.showError = true
            print("⚠️ OnboardingView - Utilisateur non authentifié")
            return
        }
        print("✅ OnboardingView - Utilisateur authentifié: \(authService.currentUser?.email ?? "N/A")")
    }
    
    // MARK: - Load Saved Preferences
    
    /// Charge les préférences sauvegardées et pré-remplit le formulaire
    private func loadSavedPreferences() {
        Task {
            // S'assurer que l'authService est configuré
            viewModel.authService = authService
            
            // Charger les préférences
            await viewModel.loadPreferencesForEditing()
            
            // Pré-remplir les champs avec les préférences chargées
            if let preferences = viewModel.loadedPreferences {
                await MainActor.run {
                    selectedEducationLevel = preferences.educationLevel
                    selectedStudyField = preferences.studyField
                    selectedSearchTypes = Set(preferences.searchTypes)
                    selectedMotivation = preferences.mainMotivation
                    selectedSoftSkills = Set(preferences.softSkills)
                    
                    // Mettre à jour les niveaux de langue
                    if let arabicLevel = preferences.languageLevels.first(where: { $0.language == .arabic }) {
                        if let index = languageLevels.firstIndex(where: { $0.language == .arabic }) {
                            languageLevels[index].level = arabicLevel.level
                        }
                    }
                    if let frenchLevel = preferences.languageLevels.first(where: { $0.language == .french }) {
                        if let index = languageLevels.firstIndex(where: { $0.language == .french }) {
                            languageLevels[index].level = frenchLevel.level
                        }
                    }
                    if let englishLevel = preferences.languageLevels.first(where: { $0.language == .english }) {
                        if let index = languageLevels.firstIndex(where: { $0.language == .english }) {
                            languageLevels[index].level = englishLevel.level
                        }
                    }
                    
                    selectedInterests = Set(preferences.interests)
                    hasSecondHobby = preferences.hasSecondHobby
                    
                    print("✅ Formulaire pré-rempli avec les préférences sauvegardées")
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Barre de progression
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.lightGray)
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(AppColors.primaryRed)
                        .frame(width: geometry.size.width * CGFloat(currentSection + 1) / 5.0, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal)
            
            HStack {
                Text("Étape \(currentSection + 1) sur 5")
                    .font(.subheadline)
                    .foregroundColor(AppColors.mediumGray)
                
                Spacer()
                
                Text(viewModel.getSectionTitle(currentSection))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.black)
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
        .background(AppColors.white)
    }
    
    // MARK: - Education Section
    
    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Informations académiques")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.black)
            
            // Niveau d'étude
            VStack(alignment: .leading, spacing: 12) {
                Text("Niveau d'étude")
                    .font(.headline)
                    .foregroundColor(AppColors.black)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(EducationLevel.allCases, id: \.self) { level in
                        SelectionChip(
                            title: level.rawValue,
                            isSelected: selectedEducationLevel == level,
                            action: {
                                selectedEducationLevel = level
                            }
                        )
                    }
                }
            }
            
            // Domaine d'étude
            VStack(alignment: .leading, spacing: 12) {
                Text("Domaine d'étude")
                    .font(.headline)
                    .foregroundColor(AppColors.black)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(StudyField.allCases, id: \.self) { field in
                        SelectionChip(
                            title: field.rawValue,
                            isSelected: selectedStudyField == field,
                            action: {
                                selectedStudyField = field
                            }
                        )
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Search Preferences Section
    
    private var searchPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Vos préférences de recherche")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.black)
            
            // Type recherché
            VStack(alignment: .leading, spacing: 12) {
                Text("Que cherchez-vous ?")
                    .font(.headline)
                    .foregroundColor(AppColors.black)
                
                VStack(spacing: 12) {
                    ForEach(SearchType.allCases, id: \.self) { type in
                        SelectionChip(
                            title: type.rawValue,
                            isSelected: selectedSearchTypes.contains(type),
                            action: {
                                if selectedSearchTypes.contains(type) {
                                    selectedSearchTypes.remove(type)
                                } else {
                                    selectedSearchTypes.insert(type)
                                }
                            }
                        )
                    }
                }
            }
            
            // Motivation principale
            VStack(alignment: .leading, spacing: 12) {
                Text("Motivation principale")
                    .font(.headline)
                    .foregroundColor(AppColors.black)
                
                VStack(spacing: 12) {
                    ForEach(Motivation.allCases, id: \.self) { motivation in
                        SelectionChip(
                            title: motivation.rawValue,
                            isSelected: selectedMotivation == motivation,
                            action: {
                                selectedMotivation = motivation
                            }
                        )
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Skills Section
    
    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Vos compétences")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.black)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Sélectionnez 2 soft skills")
                    .font(.headline)
                    .foregroundColor(AppColors.black)
                
                Text("Vous pouvez sélectionner jusqu'à 2 compétences")
                    .font(.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(SoftSkill.allCases, id: \.self) { skill in
                        SelectionChip(
                            title: skill.rawValue,
                            isSelected: selectedSoftSkills.contains(skill),
                            isDisabled: !selectedSoftSkills.contains(skill) && selectedSoftSkills.count >= 2,
                            action: {
                                if selectedSoftSkills.contains(skill) {
                                    selectedSoftSkills.remove(skill)
                                } else if selectedSoftSkills.count < 2 {
                                    selectedSoftSkills.insert(skill)
                                }
                            }
                        )
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Languages Section
    
    private var languagesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Niveaux linguistiques")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.black)
            
            VStack(spacing: 20) {
                ForEach(languageLevels.indices, id: \.self) { index in
                    LanguageLevelRow(
                        language: languageLevels[index].language,
                        selectedLevel: $languageLevels[index].level
                    )
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Interests Section
    
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Centres d'intérêt")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.black)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Sélectionnez vos centres d'intérêt")
                    .font(.headline)
                    .foregroundColor(AppColors.black)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Interest.allCases, id: \.self) { interest in
                        SelectionChip(
                            title: interest.rawValue,
                            isSelected: selectedInterests.contains(interest),
                            action: {
                                if selectedInterests.contains(interest) {
                                    selectedInterests.remove(interest)
                                } else {
                                    selectedInterests.insert(interest)
                                }
                            }
                        )
                    }
                }
            }
            
            // Deuxième hobby
            VStack(alignment: .leading, spacing: 12) {
                Text("Avez-vous un deuxième hobby ?")
                    .font(.headline)
                    .foregroundColor(AppColors.black)
                
                HStack(spacing: 20) {
                    Button(action: {
                        hasSecondHobby = true
                    }) {
                        HStack {
                            Image(systemName: hasSecondHobby == true ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(hasSecondHobby == true ? AppColors.primaryRed : AppColors.mediumGray)
                            Text("Oui")
                                .foregroundColor(AppColors.black)
                        }
                    }
                    
                    Button(action: {
                        hasSecondHobby = false
                    }) {
                        HStack {
                            Image(systemName: hasSecondHobby == false ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(hasSecondHobby == false ? AppColors.primaryRed : AppColors.mediumGray)
                            Text("Non")
                                .foregroundColor(AppColors.black)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentSection > 0 {
                Button(action: {
                    withAnimation {
                        currentSection -= 1
                    }
                }) {
                    Text("Précédent")
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
                if currentSection < 4 {
                    withAnimation {
                        currentSection += 1
                    }
                } else {
                    // Valider et sauvegarder
                    savePreferences()
                }
            }) {
                HStack {
                    Text(currentSection < 4 ? "Suivant" : "Terminer")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if currentSection == 4 {
                        Image(systemName: "checkmark")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isCurrentSectionValid ? AppColors.primaryRed : AppColors.lightGray)
                .cornerRadius(12)
            }
            .disabled(!isCurrentSectionValid)
        }
        .padding()
        .background(AppColors.white)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
    }
    
    // MARK: - Validation
    
    private var isCurrentSectionValid: Bool {
        switch currentSection {
        case 0:
            return selectedEducationLevel != nil && selectedStudyField != nil
        case 1:
            return !selectedSearchTypes.isEmpty && selectedMotivation != nil
        case 2:
            return selectedSoftSkills.count == 2
        case 3:
            return true // Les langues ont toujours une valeur par défaut
        case 4:
            return true // Les intérêts sont optionnels
        default:
            return false
        }
    }
    
    // MARK: - Save Preferences
    
    private func savePreferences() {
        // Vérifier d'abord que l'utilisateur est authentifié
        guard authService.isAuthenticated,
              authService.authToken != nil,
              authService.currentUser != nil else {
            viewModel.errorMessage = "Vous devez être connecté pour effectuer cette action"
            viewModel.showError = true
            return
        }
        
        // Valider que tous les champs requis sont remplis
        guard let educationLevel = selectedEducationLevel else {
            viewModel.errorMessage = "Veuillez sélectionner un niveau d'étude"
            viewModel.showError = true
            return
        }
        
        guard let studyField = selectedStudyField else {
            viewModel.errorMessage = "Veuillez sélectionner un domaine d'étude"
            viewModel.showError = true
            return
        }
        
        guard !selectedSearchTypes.isEmpty else {
            viewModel.errorMessage = "Veuillez sélectionner au moins un type de recherche"
            viewModel.showError = true
            return
        }
        
        guard let motivation = selectedMotivation else {
            viewModel.errorMessage = "Veuillez sélectionner une motivation principale"
            viewModel.showError = true
            return
        }
        
        guard selectedSoftSkills.count == 2 else {
            viewModel.errorMessage = "Veuillez sélectionner exactement 2 compétences douces"
            viewModel.showError = true
            return
        }
        
        // S'assurer que hasSecondHobby est défini (pas nil)
        let finalHasSecondHobby = hasSecondHobby ?? false
        
        var preferences = UserPreferences()
        preferences.educationLevel = educationLevel
        preferences.studyField = studyField
        preferences.searchTypes = Array(selectedSearchTypes)
        preferences.mainMotivation = motivation
        preferences.softSkills = Array(selectedSoftSkills)
        preferences.languageLevels = languageLevels
        preferences.interests = Array(selectedInterests)
        preferences.hasSecondHobby = finalHasSecondHobby
        
        viewModel.savePreferences(preferences)
    }
}

// MARK: - Selection Chip Component

struct SelectionChip: View {
    let title: String
    let isSelected: Bool
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppColors.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected ? AppColors.primaryRed : AppColors.white
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? AppColors.primaryRed : AppColors.lightGray,
                            lineWidth: 1
                        )
                )
                .cornerRadius(8)
                .opacity(isDisabled ? 0.5 : 1.0)
        }
        .disabled(isDisabled)
    }
}

// MARK: - Language Level Row

struct LanguageLevelRow: View {
    let language: Language
    @Binding var selectedLevel: LanguageProficiency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(language.rawValue)
                .font(.headline)
                .foregroundColor(AppColors.black)
            
            HStack(spacing: 12) {
                ForEach(LanguageProficiency.allCases, id: \.self) { level in
                    Button(action: {
                        selectedLevel = level
                    }) {
                        Text(level.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedLevel == level ? .white : AppColors.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedLevel == level ? AppColors.primaryRed : AppColors.white
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        selectedLevel == level ? AppColors.primaryRed : AppColors.lightGray,
                                        lineWidth: 1
                                    )
                            )
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.backgroundGray)
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthService())
        .environmentObject(OnboardingViewModel())
}

