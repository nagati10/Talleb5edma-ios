//
//  RoutineBalance.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation

/// Modèle représentant une analyse de routine équilibrée générée par l'IA
struct RoutineBalance: Codable, Identifiable {
    let id: String
    let dateAnalyse: Date
    let scoreEquilibre: Double // 0-100
    let recommandations: [Recommandation]
    let analyseHebdomadaire: AnalyseHebdomadaire
    let suggestionsOptimisation: [SuggestionOptimisation]
    
    enum CodingKeys: String, CodingKey {
        case id
        case dateAnalyse
        case scoreEquilibre
        case recommandations
        case analyseHebdomadaire
        case suggestionsOptimisation
    }
}

/// Recommandation pour améliorer l'équilibre de vie
struct Recommandation: Codable, Identifiable {
    let id: String
    let type: TypeRecommandation
    let titre: String
    let description: String
    let priorite: Priorite
    let actionSuggeree: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case titre
        case description
        case priorite
        case actionSuggeree
    }
}

/// Type de recommandation
enum TypeRecommandation: String, Codable {
    case travail = "Travail"
    case etudes = "Études"
    case repos = "Repos"
    case activites = "Activités personnelles"
    case sante = "Santé"
    case social = "Social"
    case optimisation = "Optimisation"
}

/// Priorité d'une recommandation
enum Priorite: String, Codable {
    case haute = "Haute"
    case moyenne = "Moyenne"
    case basse = "Basse"
    
    var color: String {
        switch self {
        case .haute: return "#FF5733"
        case .moyenne: return "#F39C12"
        case .basse: return "#2ECC71"
        }
    }
}

/// Analyse hebdomadaire des activités
struct AnalyseHebdomadaire: Codable {
    let heuresTravail: Double
    let heuresEtudes: Double
    let heuresRepos: Double
    let heuresActivites: Double
    let heuresTotales: Double
    let repartition: RepartitionActivites
    
    struct RepartitionActivites: Codable {
        let pourcentageTravail: Double
        let pourcentageEtudes: Double
        let pourcentageRepos: Double
        let pourcentageActivites: Double
    }
}

/// Suggestion d'optimisation du planning
struct SuggestionOptimisation: Codable, Identifiable {
    let id: String
    let jour: String
    let type: TypeOptimisation
    let description: String
    let avantage: String
    let impact: ImpactOptimisation
    
    enum CodingKeys: String, CodingKey {
        case id
        case jour
        case type
        case description
        case avantage
        case impact
    }
}

/// Type d'optimisation
enum TypeOptimisation: String, Codable {
    case deplacement = "Déplacement d'activité"
    case ajout = "Ajout d'activité"
    case suppression = "Suppression d'activité"
    case regroupement = "Regroupement"
    case pause = "Pause suggérée"
}

/// Impact d'une optimisation
enum ImpactOptimisation: String, Codable {
    case tresPositif = "Très positif"
    case positif = "Positif"
    case neutre = "Neutre"
    
    var color: String {
        switch self {
        case .tresPositif: return "#2ECC71"
        case .positif: return "#3498DB"
        case .neutre: return "#95A5A6"
        }
    }
}

/// Données d'entrée pour l'analyse IA
struct RoutineInputData: Codable {
    let evenements: [EvenementDTO]
    let disponibilites: [DisponibiliteDTO]
    let preferences: UserPreferencesDTO?
    let dateDebut: String // Format: "yyyy-MM-dd"
    let dateFin: String // Format: "yyyy-MM-dd"
    
    init(
        evenements: [EvenementDTO],
        disponibilites: [DisponibiliteDTO],
        preferences: UserPreferences?,
        dateDebut: String,
        dateFin: String
    ) {
        self.evenements = evenements
        self.disponibilites = disponibilites
        self.preferences = preferences.map { UserPreferencesDTO(from: $0) }
        self.dateDebut = dateDebut
        self.dateFin = dateFin
    }
}

/// DTO simplifié pour UserPreferences
struct UserPreferencesDTO: Codable {
    let educationLevel: String?
    let studyField: String?
    let searchTypes: [String]?
    let mainMotivation: String?
    let softSkills: [String]?
    let interests: [String]?
    let hasSecondHobby: Bool?
    
    init(from preferences: UserPreferences) {
        self.educationLevel = preferences.educationLevel?.rawValue
        self.studyField = preferences.studyField?.rawValue
        self.searchTypes = preferences.searchTypes.isEmpty ? nil : preferences.searchTypes.map { $0.rawValue }
        self.mainMotivation = preferences.mainMotivation?.rawValue
        self.softSkills = preferences.softSkills.isEmpty ? nil : preferences.softSkills.map { $0.rawValue }
        self.interests = preferences.interests.isEmpty ? nil : preferences.interests.map { $0.rawValue }
        self.hasSecondHobby = preferences.hasSecondHobby
    }
    
    /// Encodage personnalisé pour exclure les champs nil et les arrays vides
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let educationLevel = educationLevel {
            try container.encode(educationLevel, forKey: .educationLevel)
        }
        if let studyField = studyField {
            try container.encode(studyField, forKey: .studyField)
        }
        if let searchTypes = searchTypes, !searchTypes.isEmpty {
            try container.encode(searchTypes, forKey: .searchTypes)
        }
        if let mainMotivation = mainMotivation {
            try container.encode(mainMotivation, forKey: .mainMotivation)
        }
        if let softSkills = softSkills, !softSkills.isEmpty {
            try container.encode(softSkills, forKey: .softSkills)
        }
        if let interests = interests, !interests.isEmpty {
            try container.encode(interests, forKey: .interests)
        }
        if let hasSecondHobby = hasSecondHobby {
            try container.encode(hasSecondHobby, forKey: .hasSecondHobby)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case educationLevel
        case studyField
        case searchTypes
        case mainMotivation
        case softSkills
        case interests
        case hasSecondHobby
    }
}

/// DTO simplifié pour l'envoi d'événements au backend
struct EvenementDTO: Codable {
    let id: String
    let titre: String
    let type: String
    let date: String
    let heureDebut: String
    let heureFin: String
    let lieu: String?
    let tarifHoraire: Double?
    let couleur: String?
    
    init(from evenement: Evenement) {
        self.id = evenement.id
        self.titre = evenement.titre
        self.type = evenement.type
        self.date = evenement.date
        self.heureDebut = evenement.heureDebut
        self.heureFin = evenement.heureFin
        self.lieu = evenement.lieu
        self.tarifHoraire = evenement.tarifHoraire
        self.couleur = evenement.couleur
    }
    
    /// Encodage personnalisé pour exclure les champs nil
    /// Le backend peut rejeter les champs null, donc on ne les envoie que s'ils ont une valeur
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(titre, forKey: .titre)
        try container.encode(type, forKey: .type)
        try container.encode(date, forKey: .date)
        try container.encode(heureDebut, forKey: .heureDebut)
        try container.encode(heureFin, forKey: .heureFin)
        
        // N'encoder les champs optionnels que s'ils ne sont pas nil
        if let lieu = lieu {
            try container.encode(lieu, forKey: .lieu)
        }
        if let tarifHoraire = tarifHoraire {
            try container.encode(tarifHoraire, forKey: .tarifHoraire)
        }
        if let couleur = couleur {
            try container.encode(couleur, forKey: .couleur)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case titre
        case type
        case date
        case heureDebut
        case heureFin
        case lieu
        case tarifHoraire
        case couleur
    }
}

/// DTO simplifié pour l'envoi de disponibilités au backend
struct DisponibiliteDTO: Codable {
    let id: String
    let jour: String
    let heureDebut: String
    let heureFin: String?
    
    init(from disponibilite: Disponibilite) {
        self.id = disponibilite.id
        self.jour = disponibilite.jour
        self.heureDebut = disponibilite.heureDebut
        self.heureFin = disponibilite.heureFin
    }
    
    /// Encodage personnalisé pour exclure heureFin si nil
    /// Le backend peut rejeter les champs null
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(jour, forKey: .jour)
        try container.encode(heureDebut, forKey: .heureDebut)
        
        // N'encoder heureFin que s'il n'est pas nil
        if let heureFin = heureFin {
            try container.encode(heureFin, forKey: .heureFin)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case jour
        case heureDebut
        case heureFin
    }
}

/// Wrapper pour la réponse du backend
struct AIResponseWrapper: Codable {
    let success: Bool
    let data: RoutineBalance
}

/// Erreurs possibles lors de l'analyse IA
enum AIError: LocalizedError {
    case networkError
    case notAuthenticated
    case serverError(Int)
    case rateLimitExceeded
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Erreur de connexion réseau"
        case .notAuthenticated:
            return "Vous devez être connecté pour utiliser cette fonctionnalité"
        case .serverError(let code):
            return "Erreur serveur (\(code))"
        case .rateLimitExceeded:
            return "Trop de requêtes. Veuillez réessayer plus tard"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .decodingError:
            return "Erreur lors du décodage de la réponse"
        }
    }
}

