//
//  ExamMode.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

//
//  ExamMode.swift
//  Taleb_5edma
//

import Foundation

struct ExamMode: Codable {
    // Indique si le mode révision est activé pour l'étudiant
    var isActive: Bool
    // Début de la période de révision
    var startDate: Date
    // Fin de la période de révision
    var endDate: Date
    // Paramètres de personnalisation du mode examen
    var blockNewOffers: Bool
    var hideJobNotifications: Bool
    var keepAcceptedJobs: Bool
    var revisionReminders: Bool
    var breakSuggestions: Bool
    
    init() {
        self.isActive = false
        self.startDate = Date()
        self.endDate = Date().addingTimeInterval(86400 * 11) // 11 jours par défaut
        self.blockNewOffers = true
        self.hideJobNotifications = true
        self.keepAcceptedJobs = true
        self.revisionReminders = true
        self.breakSuggestions = true
    }
    
    var duration: Int {
        // Calcule le nombre de jours couverts par la période de révision
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1 // Inclure le jour de début
    }
}
