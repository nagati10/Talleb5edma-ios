//
//  RoutineBalanceViewModel.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel pour gérer l'analyse de routine équilibrée par IA
class RoutineBalanceViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Analyse de routine actuelle
    @Published var routineBalance: RoutineBalance?
    
    /// Indicateur de chargement
    @Published var isLoading: Bool = false
    
    /// Message d'erreur
    @Published var errorMessage: String?
    
    /// Indique si une alerte d'erreur doit être affichée
    @Published var showError: Bool = false
    
    // MARK: - Dependencies
    
    private let aiRoutineService: AIRoutineService
    private let manualActivityHoursService: ManualActivityHoursService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Properties pour les données
    
    /// Références aux ViewModels (optionnelles)
    var evenementViewModel: EvenementViewModel? {
        didSet {
            // Observer les changements d'événements pour recharger l'analyse automatiquement
            setupEventObserver()
        }
    }
    
    var availabilityViewModel: AvailabilityViewModel? {
        didSet {
            // Observer les changements de disponibilités pour recharger l'analyse automatiquement
            setupAvailabilityObserver()
        }
    }
    
    /// Heures d'activités manuelles pour la semaine actuelle
    @Published var manualActivityHours: Double = 0.0
    
    // MARK: - Initialization
    
    init(
        aiRoutineService: AIRoutineService = AIRoutineService(),
        manualActivityHoursService: ManualActivityHoursService = ManualActivityHoursService()
    ) {
        self.aiRoutineService = aiRoutineService
        self.manualActivityHoursService = manualActivityHoursService
    }
    
    // MARK: - Observers
    
    /// Configure l'observer pour les événements
    private func setupEventObserver() {
        guard let evenementViewModel = evenementViewModel else { return }
        
        // Observer les changements dans la liste d'événements
        evenementViewModel.$evenements
            .dropFirst() // Ignorer la valeur initiale
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main) // Attendre 500ms après le dernier changement
            .sink { [weak self] _ in
                print("🟢 RoutineBalanceViewModel - Événements modifiés, rechargement de l'analyse...")
                Task { @MainActor in
                    await self?.rechargerAnalyse()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Configure l'observer pour les disponibilités
    private func setupAvailabilityObserver() {
        guard let availabilityViewModel = availabilityViewModel else { return }
        
        // Observer les changements dans la liste de disponibilités
        availabilityViewModel.$disponibilites
            .dropFirst() // Ignorer la valeur initiale
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main) // Attendre 500ms après le dernier changement
            .sink { [weak self] _ in
                print("🟢 RoutineBalanceViewModel - Disponibilités modifiées, rechargement de l'analyse...")
                Task { @MainActor in
                    await self?.rechargerAnalyse()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Analyse la routine de l'utilisateur
    @MainActor
    func analyserRoutine(
        evenements: [Evenement] = [],
        disponibilites: [Disponibilite] = [],
        preferences: UserPreferences? = nil,
        dateDebut: Date? = nil,
        dateFin: Date? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        
        // Calculer la date de début : début de la semaine calendaire (lundi) si non spécifiée
        let calendar = Calendar.current
        let debut: Date
        if let dateDebutSpecifiee = dateDebut {
            debut = dateDebutSpecifiee
        } else {
            // Calculer le lundi de la semaine en cours
            let aujourdhui = Date()
            let components = calendar.dateComponents([.weekday, .yearForWeekOfYear, .weekOfYear], from: aujourdhui)
            let weekday = components.weekday ?? 1 // 1 = dimanche, 2 = lundi, 3 = mardi, etc.
            
            // Calculer le nombre de jours à soustraire pour arriver au lundi
            // weekday: 1 (dimanche) -> -6 jours, 2 (lundi) -> 0 jours, 3 (mardi) -> -1 jour, etc.
            let joursDepuisLundi = (weekday == 1) ? -6 : (2 - weekday)
            
            debut = calendar.date(byAdding: .day, value: joursDepuisLundi, to: aujourdhui) ?? aujourdhui
        }
        
        // Calculer la date de fin : 7 jours après le début de la semaine
        let fin = dateFin ?? calendar.date(byAdding: .day, value: 7, to: debut) ?? Date()
        
        // Utiliser les données passées en paramètre ou depuis les ViewModels
        let events = evenements.isEmpty ? (evenementViewModel?.evenements ?? []) : evenements
        let dispo = disponibilites.isEmpty ? (availabilityViewModel?.disponibilites ?? []) : disponibilites
        
        // Charger les heures d'activités manuelles pour cette semaine
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let semaineDebutString = dateFormatter.string(from: debut)
        manualActivityHours = manualActivityHoursService.getHours(for: semaineDebutString)
        
        do {
            print("🟢 RoutineBalanceViewModel - Début de l'analyse")
            print("🟢 RoutineBalanceViewModel - Heures manuelles: \(manualActivityHours)h")
            
            let balance = try await aiRoutineService.analyserRoutine(
                evenements: events,
                disponibilites: dispo,
                preferences: preferences,
                dateDebut: debut,
                dateFin: fin,
                manualActivityHours: manualActivityHours
            )
            
            routineBalance = balance
            print("🟢 RoutineBalanceViewModel - Analyse terminée. Score: \(balance.scoreEquilibre)")
            
        } catch {
            print("🔴 RoutineBalanceViewModel - Erreur: \(error.localizedDescription)")
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Recharge l'analyse avec les données actuelles des ViewModels
    @MainActor
    func rechargerAnalyse(preferences: UserPreferences? = nil) async {
        let events = evenementViewModel?.evenements ?? []
        let dispo = availabilityViewModel?.disponibilites ?? []
        await analyserRoutine(
            evenements: events,
            disponibilites: dispo,
            preferences: preferences
        )
    }
    
    /// Sauvegarde les heures d'activités manuelles pour la semaine actuelle
    func saveManualActivityHours(_ heures: Double, for semaineDebut: String) {
        manualActivityHoursService.setHours(heures, for: semaineDebut)
        manualActivityHours = heures
        
        // Recharger l'analyse après la sauvegarde
        Task { @MainActor in
            await rechargerAnalyse()
        }
    }
    
    /// Récupère les heures d'activités manuelles pour une semaine
    func getManualActivityHours(for semaineDebut: String) -> Double {
        return manualActivityHoursService.getHours(for: semaineDebut)
    }
    
    
    // MARK: - Helper Methods
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
    
    // MARK: - Computed Properties
    
    /// Retourne le niveau d'équilibre basé sur le score
    var niveauEquilibre: String {
        guard let score = routineBalance?.scoreEquilibre else {
            return "Non analysé"
        }
        
        if score >= 80 {
            return "Excellent"
        } else if score >= 60 {
            return "Bon"
        } else if score >= 40 {
            return "Moyen"
        } else {
            return "À améliorer"
        }
    }
    
    /// Retourne la couleur du score
    var couleurScore: Color {
        guard let score = routineBalance?.scoreEquilibre else {
            return AppColors.mediumGray
        }
        
        if score >= 80 {
            return Color(hex: "#2ECC71") // Vert
        } else if score >= 60 {
            return Color(hex: "#3498DB") // Bleu
        } else if score >= 40 {
            return Color(hex: "#F39C12") // Orange
        } else {
            return Color(hex: "#FF5733") // Rouge
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

