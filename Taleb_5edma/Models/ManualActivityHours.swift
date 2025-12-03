//
//  ManualActivityHours.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation

/// Modèle pour stocker les heures d'activités manuelles ajoutées par l'utilisateur
/// Ces heures sont ajoutées en plus des événements calculés automatiquement
struct ManualActivityHours: Codable, Identifiable {
    let id: String
    let semaineDebut: String // Format: "yyyy-MM-dd" (lundi de la semaine)
    let heures: Double // Nombre d'heures d'activités pour la semaine
    
    init(id: String = UUID().uuidString, semaineDebut: String, heures: Double) {
        self.id = id
        self.semaineDebut = semaineDebut
        self.heures = heures
    }
    
    /// Calcule le lundi de la semaine pour une date donnée
    static func lundiDeLaSemaine(pour date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday, .yearForWeekOfYear, .weekOfYear], from: date)
        let weekday = components.weekday ?? 1 // 1 = dimanche, 2 = lundi, etc.
        
        // Calculer le nombre de jours à soustraire pour arriver au lundi
        let joursDepuisLundi = (weekday == 1) ? -6 : (2 - weekday)
        
        guard let lundi = calendar.date(byAdding: .day, value: joursDepuisLundi, to: date) else {
            // Fallback: utiliser la date actuelle
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: lundi)
    }
}

/// Service pour gérer les heures d'activités manuelles (stockage local)
class ManualActivityHoursService {
    private let userDefaultsKey = "manualActivityHours"
    
    /// Charge toutes les heures manuelles stockées
    func loadAll() -> [ManualActivityHours] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let hours = try? JSONDecoder().decode([ManualActivityHours].self, from: data) else {
            return []
        }
        return hours
    }
    
    /// Sauvegarde toutes les heures manuelles
    func saveAll(_ hours: [ManualActivityHours]) {
        if let data = try? JSONEncoder().encode(hours) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    /// Récupère les heures manuelles pour une semaine spécifique
    func getHours(for semaineDebut: String) -> Double {
        let allHours = loadAll()
        return allHours.first(where: { $0.semaineDebut == semaineDebut })?.heures ?? 0.0
    }
    
    /// Ajoute ou met à jour les heures manuelles pour une semaine
    func setHours(_ heures: Double, for semaineDebut: String) {
        var allHours = loadAll()
        
        // Supprimer l'entrée existante si elle existe
        allHours.removeAll { $0.semaineDebut == semaineDebut }
        
        // Ajouter la nouvelle entrée
        if heures > 0 {
            let newHours = ManualActivityHours(semaineDebut: semaineDebut, heures: heures)
            allHours.append(newHours)
        }
        
        saveAll(allHours)
    }
    
    /// Supprime les heures manuelles pour une semaine
    func deleteHours(for semaineDebut: String) {
        var allHours = loadAll()
        allHours.removeAll { $0.semaineDebut == semaineDebut }
        saveAll(allHours)
    }
}

