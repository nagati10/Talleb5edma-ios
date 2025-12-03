//
//  UserPreferences.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation

/// Modèle pour les préférences et informations supplémentaires de l'utilisateur
struct UserPreferences: Codable {
    // Niveau d'étude
    var educationLevel: EducationLevel?
    
    // Domaine d'étude
    var studyField: StudyField?
    
    // Type recherché (peut être multiple)
    var searchTypes: [SearchType]
    
    // Motivation principale
    var mainMotivation: Motivation?
    
    // Soft skills (2 sélectionnées)
    var softSkills: [SoftSkill]
    
    // Niveaux linguistiques
    var languageLevels: [LanguageLevel]
    
    // Centres d'intérêt (peut être multiple)
    var interests: [Interest]
    
    // Présence d'un deuxième hobby
    var hasSecondHobby: Bool?
    
    init() {
        self.searchTypes = []
        self.softSkills = []
        self.languageLevels = []
        self.interests = []
    }
}

// MARK: - Education Level
enum EducationLevel: String, Codable, CaseIterable {
    case licence1 = "Licence 1"
    case licence2 = "Licence 2"
    case licence3 = "Licence 3"
    case engineering = "Ingénierie"
    case master = "Mastère"
    case other = "Autre"
    
    /// Convertit la valeur Swift vers le format backend (snake_case, lowercase)
    func toBackendValue() -> String {
        switch self {
        case .licence1: return "licence_1"
        case .licence2: return "licence_2"
        case .licence3: return "licence_3"
        case .engineering: return "ingénierie"
        case .master: return "mastère"
        case .other: return "autre"
        }
    }
    
    /// Convertit la valeur backend vers l'enum Swift
    static func fromBackendValue(_ value: String) -> EducationLevel? {
        switch value.lowercased() {
        case "licence_1": return .licence1
        case "licence_2": return .licence2
        case "licence_3": return .licence3
        case "ingénierie": return .engineering
        case "mastère": return .master
        case "autre": return .other
        default: return nil
        }
    }
}

// MARK: - Study Field
enum StudyField: String, Codable, CaseIterable {
    case computerScience = "Informatique"
    case nursing = "Infirmier"
    case medicine = "Médecine"
    case mechanical = "Mécanique"
    case electrical = "Électrique"
    case other = "Autre"
    
    /// Convertit la valeur Swift vers le format backend (lowercase)
    func toBackendValue() -> String {
        switch self {
        case .computerScience: return "informatique"
        case .nursing: return "infirmier"
        case .medicine: return "médecine"
        case .mechanical: return "mécanique"
        case .electrical: return "électrique"
        case .other: return "autre"
        }
    }
    
    /// Convertit la valeur backend vers l'enum Swift
    static func fromBackendValue(_ value: String) -> StudyField? {
        switch value.lowercased() {
        case "informatique": return .computerScience
        case "infirmier": return .nursing
        case "médecine": return .medicine
        case "mécanique": return .mechanical
        case "électrique": return .electrical
        case "autre": return .other
        default: return nil
        }
    }
}

// MARK: - Search Type
enum SearchType: String, Codable, CaseIterable {
    case job = "Job"
    case internship = "Stage"
    case freelance = "Mission freelance"
    
    /// Convertit la valeur Swift vers le format backend (lowercase)
    func toBackendValue() -> String {
        switch self {
        case .job: return "job"
        case .internship: return "stage"
        case .freelance: return "freelance"
        }
    }
    
    /// Convertit la valeur backend vers l'enum Swift
    static func fromBackendValue(_ value: String) -> SearchType? {
        switch value.lowercased() {
        case "job": return .job
        case "stage": return .internship
        case "freelance": return .freelance
        default: return nil
        }
    }
}

// MARK: - Motivation
enum Motivation: String, Codable, CaseIterable {
    case money = "Argent"
    case experience = "Expérience"
    case cvEnrichment = "Enrichissement du CV"
    
    /// Convertit la valeur Swift vers le format backend (lowercase)
    func toBackendValue() -> String {
        switch self {
        case .money: return "argent"
        case .experience: return "experience"
        case .cvEnrichment: return "enrichissement_cv"
        }
    }
    
    /// Convertit la valeur backend vers l'enum Swift
    static func fromBackendValue(_ value: String) -> Motivation? {
        switch value.lowercased() {
        case "argent": return .money
        case "experience": return .experience
        case "enrichissement_cv", "cv_enrichment", "enrichissement du cv": return .cvEnrichment
        default: return nil
        }
    }
}

// MARK: - Soft Skill
enum SoftSkill: String, Codable, CaseIterable {
    case communication = "Communication"
    case organization = "Organisation"
    case seriousness = "Sérieux"
    case adaptability = "Adaptabilité"
    case teamwork = "Travail d'équipe"
    case leadership = "Leadership"
    case creativity = "Créativité"
    case problemSolving = "Résolution de problèmes"
    
    /// Convertit la valeur Swift vers le format backend (lowercase)
    func toBackendValue() -> String {
        switch self {
        case .communication: return "communication"
        case .organization: return "organisation"
        case .seriousness: return "sérieux"
        case .adaptability: return "adaptabilité"
        case .teamwork: return "travail_équipe"
        case .leadership: return "leadership"
        case .creativity: return "créativité"
        case .problemSolving: return "résolution_problèmes"
        }
    }
    
    /// Convertit la valeur backend vers l'enum Swift
    static func fromBackendValue(_ value: String) -> SoftSkill? {
        switch value.lowercased() {
        case "communication": return .communication
        case "organisation": return .organization
        case "sérieux": return .seriousness
        case "adaptabilité": return .adaptability
        case "travail_équipe", "travail d'équipe": return .teamwork
        case "leadership": return .leadership
        case "créativité": return .creativity
        case "résolution_problèmes", "résolution de problèmes": return .problemSolving
        default: return nil
        }
    }
}

// MARK: - Language Level
struct LanguageLevel: Codable, Identifiable, Equatable {
    let id: UUID
    let language: Language
    var level: LanguageProficiency
    
    init(language: Language, level: LanguageProficiency) {
        self.id = UUID()
        self.language = language
        self.level = level
    }
    
    enum CodingKeys: String, CodingKey {
        case id, language, level
    }
}

enum Language: String, Codable, CaseIterable {
    case arabic = "Arabe"
    case french = "Français"
    case english = "Anglais"
}

enum LanguageProficiency: String, Codable, CaseIterable {
    case beginner = "Débutant"
    case intermediate = "Intermédiaire"
    case advanced = "Avancé"
    case fluent = "Courant"
    
    /// Convertit la valeur Swift vers le format backend (lowercase)
    func toBackendValue() -> String {
        switch self {
        case .beginner: return "débutant"
        case .intermediate: return "intermédiaire"
        case .advanced: return "avancé"
        case .fluent: return "courant"
        }
    }
    
    /// Convertit la valeur backend vers l'enum Swift
    static func fromBackendValue(_ value: String) -> LanguageProficiency? {
        switch value.lowercased() {
        case "débutant": return .beginner
        case "intermédiaire": return .intermediate
        case "avancé": return .advanced
        case "courant": return .fluent
        default: return nil
        }
    }
}

// MARK: - Interest
enum Interest: String, Codable, CaseIterable {
    case sports = "Sport"
    case videoGames = "Jeux vidéo"
    case music = "Musique"
    case design = "Design"
    case reading = "Lecture"
    case travel = "Voyage"
    case cooking = "Cuisine"
    case photography = "Photographie"
    
    /// Convertit la valeur Swift vers le format backend (lowercase)
    func toBackendValue() -> String {
        switch self {
        case .sports: return "sport"
        case .videoGames: return "jeux_vidéo"
        case .music: return "musique"
        case .design: return "design"
        case .reading: return "lecture"
        case .travel: return "voyage"
        case .cooking: return "cuisine"
        case .photography: return "photographie"
        }
    }
    
    /// Convertit la valeur backend vers l'enum Swift
    static func fromBackendValue(_ value: String) -> Interest? {
        switch value.lowercased() {
        case "sport": return .sports
        case "jeux_vidéo", "jeux vidéo": return .videoGames
        case "musique": return .music
        case "design": return .design
        case "lecture": return .reading
        case "voyage": return .travel
        case "cuisine": return .cooking
        case "photographie": return .photography
        default: return nil
        }
    }
}

