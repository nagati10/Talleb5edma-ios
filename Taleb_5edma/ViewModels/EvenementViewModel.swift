//
//  EvenementViewModel.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel pour gérer la logique métier des événements
/// Suit le pattern MVVM : sépare la logique métier de la vue
class EvenementViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Liste de tous les événements
    @Published var evenements: [Evenement] = []
    
    /// Indicateur de chargement
    @Published var isLoading: Bool = false
    
    /// Message d'erreur
    @Published var errorMessage: String?
    
    /// Indique si une alerte d'erreur doit être affichée
    @Published var showError: Bool = false
    
    // MARK: - Dependencies
    
    private let evenementService: EvenementService
    
    // MARK: - Initialization
    
    init(evenementService: EvenementService = EvenementService()) {
        self.evenementService = evenementService
    }
    
    // MARK: - CRUD Methods
    
    /// Charge tous les événements
    @MainActor
    func loadEvenements() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🟢 LoadEvenements - Début du chargement")
            let loadedEvenements = try await evenementService.getAllEvenements()
            evenements = loadedEvenements
            print("🟢 LoadEvenements - \(loadedEvenements.count) événements chargés")
        } catch {
            print("🔴 LoadEvenements - Erreur: \(error.localizedDescription)")
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Crée un nouvel événement
    @MainActor
    func createEvenement(_ request: CreateEvenementRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🟢 CreateEvenement - Début de la création: \(request.titre)")
            let newEvenement = try await evenementService.createEvenement(request)
            print("🟢 CreateEvenement - Événement créé avec succès: \(newEvenement.id)")
            
            /// Ajouter l'événement à la liste immédiatement après création
            /// 
            /// PROBLÈME RÉSOLU : Les nouveaux événements n'apparaissaient pas immédiatement dans le calendrier.
            /// 
            /// MODIFICATION : Ajout de l'événement à la liste locale dès sa création réussie, avant même
            /// le rechargement depuis le serveur. Cela garantit que l'événement apparaît immédiatement
            /// dans l'interface, et le Combine subscriber dans CalendarViewModel déclenchera un refresh.
            evenements.append(newEvenement)
            print("🟢 CreateEvenement - Événement ajouté à la liste. Total: \(evenements.count)")
            
            isLoading = false
            return true
        } catch {
            print("🔴 CreateEvenement - Erreur: \(error.localizedDescription)")
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// Met à jour un événement
    @MainActor
    func updateEvenement(id: String, _ request: UpdateEvenementRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🟢 UpdateEvenement - Début de la mise à jour pour ID: \(id)")
            let updatedEvenement = try await evenementService.updateEvenement(id: id, request)
            print("🟢 UpdateEvenement - Événement mis à jour avec succès: \(updatedEvenement.titre)")
            
            if let index = evenements.firstIndex(where: { $0.id == id }) {
                evenements[index] = updatedEvenement
                print("🟢 UpdateEvenement - Événement mis à jour dans la liste à l'index: \(index)")
            } else {
                print("⚠️ UpdateEvenement - Événement non trouvé dans la liste, ajout à la fin")
                evenements.append(updatedEvenement)
            }
            
            isLoading = false
            return true
        } catch {
            print("🔴 UpdateEvenement - Erreur: \(error.localizedDescription)")
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// Supprime un événement
    @MainActor
    func deleteEvenement(_ id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await evenementService.deleteEvenement(id)
            evenements.removeAll { $0.id == id }
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// Récupère les événements par plage de dates
    @MainActor
    func loadEvenementsByDateRange(startDate: String, endDate: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            evenements = try await evenementService.getEvenementsByDateRange(startDate: startDate, endDate: endDate)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Récupère les événements par type
    @MainActor
    func loadEvenementsByType(_ type: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            evenements = try await evenementService.getEvenementsByType(type)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func handleError(_ error: Error) {
        if let evenementError = error as? EvenementError {
            errorMessage = evenementError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
}

