//
//  OffreViewModel.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel pour gérer la logique métier des offres
/// Suit le pattern MVVM : sépare la logique métier de la vue
class OffreViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Liste de toutes les offres
    @Published var offres: [Offre] = []
    
    /// Indicateur de chargement
    @Published var isLoading: Bool = false
    
    /// Message d'erreur
    @Published var errorMessage: String?
    
    /// Indique si une alerte d'erreur doit être affichée
    @Published var showError: Bool = false
    
    // MARK: - Dependencies
    
    private let offreService: OffreService
    
    // MARK: - Initialization
    
    init(offreService: OffreService = OffreService()) {
        self.offreService = offreService
    }
    
    // MARK: - CRUD Methods
    
    /// Charge toutes les offres actives
    @MainActor
    func loadOffres() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🟢 LoadOffres - Début du chargement")
            let loadedOffres = try await offreService.getAllOffres()
            offres = loadedOffres
            print("🟢 LoadOffres - \(loadedOffres.count) offres chargées")
        } catch {
            print("🔴 LoadOffres - Erreur: \(error.localizedDescription)")
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Crée une nouvelle offre
    @MainActor
    func createOffre(_ request: CreateOffreRequest, imageFiles: [Data]? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🟢 CreateOffre - Début de la création: \(request.title)")
            let newOffre = try await offreService.createOffre(request, imageFiles: imageFiles)
            print("🟢 CreateOffre - Offre créée avec succès: \(newOffre.id)")
            
            // Ajouter l'offre à la liste
            offres.append(newOffre)
            print("🟢 CreateOffre - Offre ajoutée à la liste. Total: \(offres.count)")
            
            isLoading = false
            return true
        } catch {
            print("🔴 CreateOffre - Erreur: \(error.localizedDescription)")
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// Met à jour une offre
    @MainActor
    func updateOffre(id: String, _ request: UpdateOffreRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🟢 UpdateOffre - Début de la mise à jour pour ID: \(id)")
            let updatedOffre = try await offreService.updateOffre(id: id, request)
            print("🟢 UpdateOffre - Offre mise à jour avec succès: \(updatedOffre.title)")
            
            if let index = offres.firstIndex(where: { $0.id == id }) {
                offres[index] = updatedOffre
                print("🟢 UpdateOffre - Offre mise à jour dans la liste à l'index: \(index)")
            } else {
                print("⚠️ UpdateOffre - Offre non trouvée dans la liste, ajout à la fin")
                offres.append(updatedOffre)
            }
            
            isLoading = false
            return true
        } catch {
            print("🔴 UpdateOffre - Erreur: \(error.localizedDescription)")
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// Supprime une offre
    @MainActor
    func deleteOffre(_ id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await offreService.deleteOffre(id)
            offres.removeAll { $0.id == id }
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// Aime ou n'aime plus une offre
    @MainActor
    func likeOffre(_ id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedOffre = try await offreService.likeOffre(id)
            
            // Mettre à jour l'offre dans la liste
            if let index = offres.firstIndex(where: { $0.id == id }) {
                offres[index] = updatedOffre
            }
            
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// Charge les offres de l'utilisateur actuel
    @MainActor
    func loadMyOffres() async {
        isLoading = true
        errorMessage = nil
        
        do {
            offres = try await offreService.getMyOffres()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Charge les offres aimées par l'utilisateur actuel
    @MainActor
    func loadLikedOffres() async {
        isLoading = true
        errorMessage = nil
        
        do {
            offres = try await offreService.getLikedOffres()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Recherche des offres
    @MainActor
    func searchOffres(query: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            offres = try await offreService.searchOffres(query: query)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Charge les offres populaires
    @MainActor
    func loadPopularOffres() async {
        isLoading = true
        errorMessage = nil
        
        do {
            offres = try await offreService.getPopularOffres()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func handleError(_ error: Error) {
        if let offreError = error as? OffreError {
            errorMessage = offreError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
}

