//
//  CalendarViewModel.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel pour gérer la logique métier du calendrier
/// Combine les événements et les disponibilités pour une vue unifiée
class CalendarViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// ViewModel pour les événements
    @Published var evenementViewModel: EvenementViewModel
    
    /// ViewModel pour les disponibilités
    @Published var availabilityViewModel: AvailabilityViewModel
    
    /// Date sélectionnée dans le calendrier
    @Published var selectedDate: Date = Date()
    
    /// Mois actuellement affiché
    @Published var currentMonth: Date = Date()
    
    /// ID de rafraîchissement pour forcer la mise à jour de la vue
    /// 
    /// PROBLÈME RÉSOLU : Après la création d'un événement, le calendrier ne se mettait pas à jour
    /// automatiquement pour afficher le nouvel événement. Ce refreshID force SwiftUI à re-rendre
    /// la vue quand il change.
    ///
    /// MODIFICATION : Ajout d'un @Published refreshID qui change quand la liste d'événements change,
    /// déclenchant ainsi une mise à jour de la vue CalendarView.
    @Published var refreshID = UUID()
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        evenementViewModel: EvenementViewModel = EvenementViewModel(),
        availabilityViewModel: AvailabilityViewModel = AvailabilityViewModel()
    ) {
        self.evenementViewModel = evenementViewModel
        self.availabilityViewModel = availabilityViewModel
        
        /// Observer les changements dans evenementViewModel.evenements
        /// 
        /// PROBLÈME RÉSOLU : Les nouveaux événements créés n'apparaissaient pas immédiatement
        /// dans le calendrier car la vue ne se mettait pas à jour automatiquement.
        ///
        /// MODIFICATION : Utilisation de Combine pour observer les changements dans la liste
        /// d'événements. Dès qu'un événement est ajouté/modifié/supprimé, refreshID est mis à jour,
        /// forçant SwiftUI à re-rendre CalendarView et afficher les nouveaux événements.
        evenementViewModel.$evenements
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshID = UUID()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Methods
    
    /// Charge toutes les données (événements et disponibilités)
    @MainActor
    func loadAllData() async {
        await evenementViewModel.loadEvenements()
        await availabilityViewModel.loadDisponibilites()
    }
    
    /// Récupère les événements pour une date spécifique
    /// 
    /// MODIFICATION : Ajout de logs détaillés pour déboguer le problème où les événements
    /// n'apparaissaient pas dans le calendrier après création. Ces logs permettent de vérifier
    /// que la comparaison de dates fonctionne correctement après la normalisation du format de date.
    ///
    /// NOTE : La normalisation des dates dans Evenement.init(from:) garantit que la comparaison
    /// fonctionne correctement en convertissant les dates ISO en format "yyyy-MM-dd".
    func getEvenementsForDate(_ date: Date) -> [Evenement] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Log des dates des événements pour déboguer
        // Ces logs ont aidé à identifier le problème de format de date (ISO vs yyyy-MM-dd)
        let eventDates = evenementViewModel.evenements.map { $0.date }
        print("🟢 GetEvenementsForDate - Recherche date: \(dateString)")
        print("🟢 GetEvenementsForDate - Dates des événements: \(eventDates)")
        
        let filtered = evenementViewModel.evenements.filter { $0.date == dateString }
        print("🟢 GetEvenementsForDate - Trouvés: \(filtered.count) sur \(evenementViewModel.evenements.count) total")
        return filtered
    }
    
    /// Récupère les disponibilités pour un jour spécifique
    func getDisponibilitesForDate(_ date: Date) -> [Disponibilite] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.dateFormat = "EEEE"
        let dayName = dateFormatter.string(from: date)
        
        // Capitaliser la première lettre
        let capitalizedDay = dayName.prefix(1).uppercased() + dayName.dropFirst()
        
        return availabilityViewModel.getDisponibilitesForDay(capitalizedDay)
    }
    
    /// Change le mois affiché
    func changeMonth(by months: Int) {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: months, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

