//
//  StudentPreferencesRequest.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation

// MARK: - Create Student Preferences Request

/// Modèle de requête pour créer ou compléter les préférences étudiant
/// Correspond au DTO du backend pour POST /student-preferences
struct CreateStudentPreferencesRequest: Codable {
    let studyLevel: String
    let studyDomain: String
    let lookingFor: String
    let mainMotivation: String
    let softSkills: [String]
    let langueArabe: String
    let langueFrancais: String
    let langueAnglais: String
    let hobbies: [String]
    let hasSecondHobby: Bool
    let currentStep: Int
    let isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case studyLevel = "study_level"
        case studyDomain = "study_domain"
        case lookingFor = "looking_for"
        case mainMotivation = "main_motivation"
        case softSkills = "soft_skills"
        case langueArabe = "langue_arabe"
        case langueFrancais = "langue_francais"
        case langueAnglais = "langue_anglais"
        case hobbies
        case hasSecondHobby = "has_second_hobby"
        case currentStep = "current_step"
        case isCompleted = "is_completed"
    }
    
    /// Initialise la requête à partir d'un objet UserPreferences
    /// - Throws: Une erreur si les champs requis sont manquants
    init(from preferences: UserPreferences, currentStep: Int = 5, isCompleted: Bool = false) throws {
        // Valider et mapper les valeurs vers le format backend (snake_case, lowercase)
        guard let educationLevel = preferences.educationLevel else {
            throw StudentPreferencesValidationError.missingEducationLevel
        }
        self.studyLevel = educationLevel.toBackendValue()
        
        guard let studyField = preferences.studyField else {
            throw StudentPreferencesValidationError.missingStudyField
        }
        self.studyDomain = studyField.toBackendValue()
        
        // looking_for: prendre le premier searchType ou "job" par défaut
        guard let firstSearchType = preferences.searchTypes.first else {
            throw StudentPreferencesValidationError.missingSearchType
        }
        self.lookingFor = firstSearchType.toBackendValue()
        
        guard let motivation = preferences.mainMotivation else {
            throw StudentPreferencesValidationError.missingMotivation
        }
        self.mainMotivation = motivation.toBackendValue()
        
        guard !preferences.softSkills.isEmpty else {
            throw StudentPreferencesValidationError.missingSoftSkills
        }
        self.softSkills = preferences.softSkills.map { $0.toBackendValue() }
        
        // Mapper les niveaux de langue (toujours présents avec valeurs par défaut)
        let arabicLevel = preferences.languageLevels.first { $0.language == .arabic }?.level ?? .beginner
        self.langueArabe = arabicLevel.toBackendValue()
        
        let frenchLevel = preferences.languageLevels.first { $0.language == .french }?.level ?? .beginner
        self.langueFrancais = frenchLevel.toBackendValue()
        
        let englishLevel = preferences.languageLevels.first { $0.language == .english }?.level ?? .beginner
        self.langueAnglais = englishLevel.toBackendValue()
        
        self.hobbies = preferences.interests.map { $0.toBackendValue() }
        self.hasSecondHobby = preferences.hasSecondHobby ?? false
        self.currentStep = currentStep
        self.isCompleted = isCompleted
    }
}

// MARK: - Update Student Preferences Request

/// Modèle de requête pour mettre à jour les préférences étudiant
/// Correspond au UpdateStudentPreferenceDto du backend pour PATCH /student-preferences/my-preferences
struct UpdateStudentPreferencesRequest: Codable {
    let studyLevel: String?
    let studyDomain: String?
    let lookingFor: String?
    let mainMotivation: String?
    let softSkills: [String]?
    let langueArabe: String?
    let langueFrancais: String?
    let langueAnglais: String?
    let hobbies: [String]?
    let hasSecondHobby: Bool?
    let currentStep: Int?
    let isCompleted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case studyLevel = "study_level"
        case studyDomain = "study_domain"
        case lookingFor = "looking_for"
        case mainMotivation = "main_motivation"
        case softSkills = "soft_skills"
        case langueArabe = "langue_arabe"
        case langueFrancais = "langue_francais"
        case langueAnglais = "langue_anglais"
        case hobbies
        case hasSecondHobby = "has_second_hobby"
        case currentStep = "current_step"
        case isCompleted = "is_completed"
    }
    
    /// Initialise la requête à partir d'un objet UserPreferences (tous les champs optionnels)
    init(from preferences: UserPreferences, currentStep: Int? = nil, isCompleted: Bool? = nil) {
        self.studyLevel = preferences.educationLevel?.toBackendValue()
        self.studyDomain = preferences.studyField?.toBackendValue()
        self.lookingFor = preferences.searchTypes.first?.toBackendValue()
        self.mainMotivation = preferences.mainMotivation?.toBackendValue()
        self.softSkills = preferences.softSkills.isEmpty ? nil : preferences.softSkills.map { $0.toBackendValue() }
        
        let arabicLevel = preferences.languageLevels.first { $0.language == .arabic }?.level
        self.langueArabe = arabicLevel?.toBackendValue()
        
        let frenchLevel = preferences.languageLevels.first { $0.language == .french }?.level
        self.langueFrancais = frenchLevel?.toBackendValue()
        
        let englishLevel = preferences.languageLevels.first { $0.language == .english }?.level
        self.langueAnglais = englishLevel?.toBackendValue()
        
        self.hobbies = preferences.interests.isEmpty ? nil : preferences.interests.map { $0.toBackendValue() }
        self.hasSecondHobby = preferences.hasSecondHobby
        self.currentStep = currentStep
        self.isCompleted = isCompleted
    }
}

// MARK: - Update Step Request

/// Modèle de requête pour mettre à jour une étape spécifique
/// Correspond au UpdateStepDto du backend pour PATCH /student-preferences/step/{step}
struct UpdateStepRequest: Codable {
    let step: Int
    let data: [String: String]
    let markCompleted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case step
        case data
        case markCompleted = "mark_completed"
    }
    
    /// Initialise la requête pour mettre à jour une étape
    /// - Parameters:
    ///   - step: Le numéro de l'étape (1-5)
    ///   - data: Les données de l'étape sous forme de dictionnaire
    ///   - markCompleted: Si true, marque le formulaire comme complété
    init(step: Int, data: [String: String], markCompleted: Bool? = nil) {
        self.step = step
        self.data = data
        self.markCompleted = markCompleted
    }
}

// MARK: - Student Preferences Response

/// Modèle de réponse pour les préférences étudiant
/// Correspond à la réponse du backend
struct StudentPreferencesResponse: Codable {
    let id: String?
    let studyLevel: String?
    let studyDomain: String?
    let lookingFor: String?
    let mainMotivation: String?
    let softSkills: [String]?
    let langueArabe: String?
    let langueFrancais: String?
    let langueAnglais: String?
    let hobbies: [String]?
    let hasSecondHobby: Bool?
    let currentStep: Int?
    let isCompleted: Bool?
    let userId: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case studyLevel = "study_level"
        case studyDomain = "study_domain"
        case lookingFor = "looking_for"
        case mainMotivation = "main_motivation"
        case softSkills = "soft_skills"
        case langueArabe = "langue_arabe"
        case langueFrancais = "langue_francais"
        case langueAnglais = "langue_anglais"
        case hobbies
        case hasSecondHobby = "has_second_hobby"
        case currentStep = "current_step"
        case isCompleted = "is_completed"
        case userId = "user_id"
        case createdAt
        case updatedAt
    }
    
    /// Convertit la réponse en UserPreferences
    func toUserPreferences() -> UserPreferences {
        var preferences = UserPreferences()
        
        // Mapper depuis le format backend vers les enums Swift
        if let studyLevel = studyLevel {
            preferences.educationLevel = EducationLevel.fromBackendValue(studyLevel)
        }
        
        if let studyDomain = studyDomain {
            preferences.studyField = StudyField.fromBackendValue(studyDomain)
        }
        
        if let lookingFor = lookingFor {
            if let searchType = SearchType.fromBackendValue(lookingFor) {
                preferences.searchTypes = [searchType]
            }
        }
        
        if let mainMotivation = mainMotivation {
            preferences.mainMotivation = Motivation.fromBackendValue(mainMotivation)
        }
        
        if let softSkills = softSkills {
            preferences.softSkills = softSkills.compactMap { SoftSkill.fromBackendValue($0) }
        }
        
        // Mapper les niveaux de langue
        var languageLevels: [LanguageLevel] = []
        if let arabicLevel = langueArabe, let level = LanguageProficiency.fromBackendValue(arabicLevel) {
            languageLevels.append(LanguageLevel(language: .arabic, level: level))
        }
        if let frenchLevel = langueFrancais, let level = LanguageProficiency.fromBackendValue(frenchLevel) {
            languageLevels.append(LanguageLevel(language: .french, level: level))
        }
        if let englishLevel = langueAnglais, let level = LanguageProficiency.fromBackendValue(englishLevel) {
            languageLevels.append(LanguageLevel(language: .english, level: level))
        }
        preferences.languageLevels = languageLevels
        
        if let hobbies = hobbies {
            preferences.interests = hobbies.compactMap { Interest.fromBackendValue($0) }
        }
        
        preferences.hasSecondHobby = hasSecondHobby
        
        return preferences
    }
}

// MARK: - Progress Response

/// Modèle de réponse pour la progression du formulaire
struct StudentPreferencesProgressResponse: Codable {
    let currentStep: Int
    let totalSteps: Int
    let isCompleted: Bool
    let completedSteps: [Int]
    
    enum CodingKeys: String, CodingKey {
        case currentStep = "current_step"
        case totalSteps = "total_steps"
        case isCompleted = "is_completed"
        case completedSteps = "completed_steps"
    }
}

