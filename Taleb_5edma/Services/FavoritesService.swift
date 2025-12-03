//
//  FavoritesService.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation
import Combine

// MARK: - FavoritesService

/// Service singleton pour gérer les offres d'emploi favorites de l'utilisateur
/// Permet d'ajouter, retirer et vérifier les favoris de manière centralisée
/// Les favoris sont persistés dans UserDefaults pour conserver les préférences entre les sessions
///
/// **Utilisation:**
/// ```swift
/// let favoritesService = FavoritesService.shared
/// favoritesService.addFavorite(jobId: "123")
/// if favoritesService.isFavorite(jobId: "123") {
///     // L'offre est dans les favoris
/// }
/// ```
class FavoritesService: ObservableObject {
    // MARK: - Singleton
    
    /// Instance partagée unique du service des favoris
    /// Utilise le pattern Singleton pour garantir une seule instance dans toute l'application
    static let shared = FavoritesService()
    
    // MARK: - Published Properties
    
    /// Ensemble des IDs des offres favorites de l'utilisateur
    /// Utilise un Set pour garantir l'unicité et permettre des recherches rapides
    /// Publié pour permettre aux vues SwiftUI de réagir automatiquement aux changements
    @Published var favoriteJobIds: Set<String> = []
    
    // MARK: - Private Properties
    
    /// Clé utilisée pour sauvegarder les favoris dans UserDefaults
    /// Permet la persistance des favoris entre les sessions de l'application
    private let userDefaultsKey = "favoriteJobIds"
    
    // MARK: - Initialization
    
    /// Initialiseur privé pour garantir le pattern Singleton
    /// Charge automatiquement les favoris sauvegardés depuis UserDefaults
    private init() {
        // Charger les favoris sauvegardés au démarrage du service
        loadFavorites()
    }
    
    // MARK: - Public Methods
    
    /// Vérifie si une offre d'emploi est dans les favoris
    /// - Parameter jobId: L'identifiant unique de l'offre à vérifier
    /// - Returns: `true` si l'offre est favorite, `false` sinon
    /// - Complexity: O(1) grâce à l'utilisation d'un Set
    func isFavorite(jobId: String) -> Bool {
        return favoriteJobIds.contains(jobId)
    }
    
    /// Ajoute une offre d'emploi aux favoris
    /// Sauvegarde automatiquement dans UserDefaults après l'ajout
    /// - Parameter jobId: L'identifiant unique de l'offre à ajouter
    /// - Note: Si l'offre est déjà favorite, cette méthode n'a aucun effet (Set unique)
    func addFavorite(jobId: String) {
        favoriteJobIds.insert(jobId)
        // Sauvegarder immédiatement pour garantir la persistance
        saveFavorites()
    }
    
    /// Retire une offre d'emploi des favoris
    /// Sauvegarde automatiquement dans UserDefaults après la suppression
    /// - Parameter jobId: L'identifiant unique de l'offre à retirer
    /// - Note: Si l'offre n'est pas dans les favoris, cette méthode n'a aucun effet
    func removeFavorite(jobId: String) {
        favoriteJobIds.remove(jobId)
        // Sauvegarder immédiatement pour garantir la persistance
        saveFavorites()
    }
    
    /// Bascule l'état favoris d'une offre d'emploi
    /// Si l'offre est favorite, elle est retirée ; sinon, elle est ajoutée
    /// - Parameter jobId: L'identifiant unique de l'offre à basculer
    /// - Note: Méthode pratique pour les boutons cœur dans les interfaces utilisateur
    func toggleFavorite(jobId: String) {
        if isFavorite(jobId: jobId) {
            removeFavorite(jobId: jobId)
        } else {
            addFavorite(jobId: jobId)
        }
    }
    
    /// Filtre une liste d'offres pour ne garder que celles qui sont favorites
    /// Utile pour afficher uniquement les offres favorites dans `FavoritesView`
    /// - Parameter offres: La liste complète des offres à filtrer
    /// - Returns: Une liste contenant uniquement les offres favorites
    /// - Complexity: O(n) où n est le nombre d'offres dans la liste
    func filterFavoriteOffres(from offres: [Offre]) -> [Offre] {
        return offres.filter { offre in
            favoriteJobIds.contains(offre.id)
        }
    }
    
    // MARK: - Persistence
    
    /// Charge les favoris sauvegardés depuis UserDefaults
    /// Appelé automatiquement lors de l'initialisation du service
    /// Gère silencieusement les erreurs de décodage (retour à un Set vide)
    private func loadFavorites() {
        // Tenter de charger les données depuis UserDefaults
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            // Si le décodage réussit, mettre à jour la liste des favoris
            favoriteJobIds = decoded
        }
        // Si le chargement échoue (première utilisation ou données corrompues),
        // favoriteJobIds reste un Set vide (valeur par défaut)
    }
    
    /// Sauvegarde les favoris actuels dans UserDefaults
    /// Appelé automatiquement après chaque modification (ajout, retrait, toggle)
    /// Garantit la persistance des favoris entre les sessions de l'application
    private func saveFavorites() {
        // Encoder les favoris en JSON et sauvegarder dans UserDefaults
        if let encoded = try? JSONEncoder().encode(favoriteJobIds) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        // Si l'encodage échoue, les favoris ne sont pas sauvegardés
        // Mais cela ne devrait jamais arriver avec un Set<String>
    }
}

