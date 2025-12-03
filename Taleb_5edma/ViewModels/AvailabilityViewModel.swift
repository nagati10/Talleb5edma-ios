//
//  AvailabilityViewModel.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel pour gérer la logique métier des disponibilités
/// Suit le pattern MVVM : sépare la logique métier de la vue
class AvailabilityViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Liste de toutes les disponibilités
    @Published var disponibilites: [Disponibilite] = []
    
    /// Indicateur de chargement
    @Published var isLoading: Bool = false
    
    /// Message d'erreur
    @Published var errorMessage: String?
    
    /// Indique si une alerte d'erreur doit être affichée
    @Published var showError: Bool = false
    
    // MARK: - Dependencies
    
    private let disponibiliteService: DisponibiliteService
    
    // MARK: - Initialization
    
    init(disponibiliteService: DisponibiliteService = DisponibiliteService()) {
        self.disponibiliteService = disponibiliteService
    }
    
    // MARK: - CRUD Methods
    
    /// Charge toutes les disponibilités
    @MainActor
    func loadDisponibilites() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🟢 LoadDisponibilites - Début du chargement")
            let loadedDisponibilites = try await disponibiliteService.getAllDisponibilites()
            disponibilites = loadedDisponibilites
            print("🟢 LoadDisponibilites - \(loadedDisponibilites.count) disponibilités chargées")
        } catch {
            print("🔴 LoadDisponibilites - Erreur: \(error.localizedDescription)")
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Crée une nouvelle disponibilité
    @MainActor
    func createDisponibilite(_ request: CreateDisponibiliteRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🟢 CreateDisponibilite - Début de la création pour \(request.jour)")
            let newDisponibilite = try await disponibiliteService.createDisponibilite(request)
            print("🟢 CreateDisponibilite - Disponibilité créée avec succès: \(newDisponibilite.id)")
            
            disponibilites.append(newDisponibilite)
            print("🟢 CreateDisponibilite - Disponibilité ajoutée à la liste. Total: \(disponibilites.count)")
            
            isLoading = false
            return true
        } catch {
            print("🔴 CreateDisponibilite - Erreur: \(error.localizedDescription)")
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// Met à jour une disponibilité
    @MainActor
    func updateDisponibilite(id: String, _ request: UpdateDisponibiliteRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🟢 UpdateDisponibilite - Début de la mise à jour pour ID: \(id)")
            let updatedDisponibilite = try await disponibiliteService.updateDisponibilite(id: id, request)
            print("🟢 UpdateDisponibilite - Disponibilité mise à jour avec succès: \(updatedDisponibilite.jour)")
            
            if let index = disponibilites.firstIndex(where: { $0.id == id }) {
                disponibilites[index] = updatedDisponibilite
                print("🟢 UpdateDisponibilite - Disponibilité mise à jour dans la liste à l'index: \(index)")
            } else {
                print("⚠️ UpdateDisponibilite - Disponibilité non trouvée dans la liste, ajout à la fin")
                disponibilites.append(updatedDisponibilite)
            }
            
            isLoading = false
            return true
        } catch {
            print("🔴 UpdateDisponibilite - Erreur: \(error.localizedDescription)")
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// Supprime une disponibilité
    @MainActor
    func deleteDisponibilite(_ id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await disponibiliteService.deleteDisponibilite(id)
            disponibilites.removeAll { $0.id == id }
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// Supprime toutes les disponibilités
    @MainActor
    func deleteAllDisponibilites() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await disponibiliteService.deleteAllDisponibilites()
            disponibilites.removeAll()
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// Récupère les disponibilités par jour
    @MainActor
    func loadDisponibilitesByDay(_ jour: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            disponibilites = try await disponibiliteService.getDisponibilitesByDay(jour)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Récupère les disponibilités pour un jour spécifique
    func getDisponibilitesForDay(_ jour: String) -> [Disponibilite] {
        return disponibilites.filter { $0.jour == jour }
    }
    
    // MARK: - Helper Methods
    
    private func handleError(_ error: Error) {
        if let disponibiliteError = error as? DisponibiliteError {
            errorMessage = disponibiliteError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
}

