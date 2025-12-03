
//  APIConfig.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import Foundation

// MARK: - APIConfig

/// Configuration centralisée pour toutes les requêtes API vers le backend NestJS
/// Gère l'URL de base, les endpoints et les paramètres de réseau
/// Supporte la bascule entre environnement de développement local et production
///
/// **Configuration:**
/// - Modifiez `isDevelopment` pour basculer entre local et production
/// - Modifiez `localBaseURL` si votre serveur tourne sur un autre port/address
/// - Modifiez `productionBaseURL` avec l'URL réelle de votre application déployée
///
/// **Utilisation:**
/// ```swift
/// let url = URL(string: APIConfig.loginEndpoint)
/// ```
struct APIConfig {
    // MAxRK: - Environment Configuration
    
    /// Mode de développement (true = local, false = production)
    /// Changez cette valeur pour basculer entre local et production
    /// ✅ Pour utiliser le backend Render, changez cette valeur à false
    static let isDevelopment: Bool = false // 🔧 Changez à false pour utiliser le backend Render
    
    // MARK: - Base URL
    
    /// URL de base pour le développement local
    /// ⚠️ IMPORTANT : Sur iOS Simulator, utilisez "127.0.0.1" au lieu de "localhost"
    /// Pour un appareil physique, utilisez l'adresse IP de votre Mac (ex: "192.168.1.100")
    ///
    /// 🔧 CONFIGURATION IMPORTANTE:
    /// Si votre backend NestJS utilise un préfixe global "/api", gardez "/api" dans l'URL
    /// Si votre backend n'utilise PAS de préfixe global, enlevez "/api" de l'URL
    ///
    /// Exemples:
    /// - Avec préfixe: "http://127.0.0.1:3005" → les endpoints seront "/api/auth/login"
    /// - Sans préfixe: "http://127.0.0.1:3005" → les endpoints seront "/auth/login"
    static let localBaseURL: String = "http://127.0.0.1:3005"
    
    /// URL de base pour la production (Render)
    /// Format : https://talleb-5edma.onrender.com
    /// ✅ Backend déployé sur Render
    ///
    /// 🔧 CONFIGURATION IMPORTANTE:
    /// Si le backend retourne 404, essayez de changer cette valeur :
    /// - Avec préfixe: "https://talleb-5edma.onrender.com/api" (et enlever /api des endpoints)
    /// - Sans préfixe: "https://talleb-5edma.onrender.com" (et garder /api dans les endpoints)
    static let productionBaseURL: String = "https://talleb-5edma.onrender.com"
    
    /// Indique si le préfixe /api doit être ajouté dans les endpoints
    /// Changez à false si votre backend Render n'utilise pas le préfixe /api
    /// 🔧 Si vous obtenez une erreur 404, essayez de changer cette valeur à false
    static let useApiPrefix: Bool = false
    
    /// URL de base de l'API backend (sélectionnée automatiquement selon l'environnement)
    ///
    /// 🔧 Pour tester sans le préfixe /api, changez localBaseURL en "http://127.0.0.1:3005"
    static var baseURL: String {
        if isDevelopment {
            return localBaseURL
        } else {
            return productionBaseURL
        }
    }
    
    /// Affiche la configuration actuelle pour le débogage
    static func printConfiguration() {
        print("📱 Configuration API:")
        print("   Mode: \(isDevelopment ? "Développement" : "Production")")
        print("   Base URL: \(baseURL)")
        print("   Login: \(loginEndpoint)")
        print("   SignUp: \(signUpEndpoint)")
    }
    
    // MARK: - Endpoints
    
    /// Construit un endpoint avec ou sans le préfixe /api selon la configuration
    private static func endpoint(_ path: String) -> String {
        let apiPrefix = useApiPrefix ? "/api" : ""
        return "\(baseURL)\(apiPrefix)\(path)"
    }
    
    /// Endpoint pour la connexion (POST /api/auth/login)
    static var loginEndpoint: String {
        return endpoint("/auth/login")
    }
    
    /// Endpoint pour l'inscription (POST /api/admin/register)
    /// ⚠️ Note: Le backend utilise /admin/register pour créer un utilisateur
    static var signUpEndpoint: String {
        return endpoint("/admin/register")
    }
    
    /// Endpoint pour obtenir le profil utilisateur (GET /api/user/me)
    static var getUserProfileEndpoint: String {
        return endpoint("/user/me")
    }
    
    /// Endpoint pour mettre à jour le profil utilisateur (PATCH /api/user/me)
    static var updateUserProfileEndpoint: String {
        return endpoint("/user/me")
    }
    
    /// Endpoint pour réinitialiser le mot de passe (PATCH /api/user/me/reset-password)
    static var resetPasswordEndpoint: String {
        return endpoint("/user/me/reset-password")
    }
    
    /// Endpoint pour obtenir l'image de profil (GET /api/user/me/image/Get)
    static var getUserImageEndpoint: String {
        return endpoint("/user/me/image/Get")
    }
    
    /// Endpoint pour mettre à jour l'image de profil (PATCH /api/user/me/image/update)
    static var updateUserImageEndpoint: String {
        return endpoint("/user/me/image/update")
    }
    
    /// Endpoint pour la connexion Google (POST /api/auth/google)
    static var googleSignInEndpoint: String {
        return endpoint("/auth/google")
    }
    
    /// Endpoint pour vérifier si un email existe déjà dans le système (GET /api/admin/email-exists/{email})
    static func emailExistsEndpoint(for email: String) -> String {
        // On encode l'email pour éviter les caractères spéciaux dans l'URL
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? email
        return endpoint("/admin/email-exists/\(encodedEmail)")
    }
    
    // MARK: - Evenements Endpoints
    
    /// Endpoint pour créer un événement (POST /evenements)
    static var createEvenementEndpoint: String {
        return endpoint("/evenements")
    }
    
    /// Endpoint pour récupérer tous les événements (GET /evenements)
    static var getAllEvenementsEndpoint: String {
        return endpoint("/evenements")
    }
    
    /// Endpoint pour récupérer les événements par plage de dates (GET /evenements/date-range)
    static func getEvenementsByDateRangeEndpoint(startDate: String, endDate: String) -> String {
        let encodedStartDate = startDate.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? startDate
        let encodedEndDate = endDate.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? endDate
        return endpoint("/evenements/date-range?startDate=\(encodedStartDate)&endDate=\(encodedEndDate)")
    }
    
    /// Endpoint pour récupérer les événements par type (GET /evenements/type/{type})
    static func getEvenementsByTypeEndpoint(type: String) -> String {
        let encodedType = type.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? type
        return endpoint("/evenements/type/\(encodedType)")
    }
    
    /// Endpoint pour récupérer un événement par ID (GET /evenements/{id})
    static func getEvenementByIdEndpoint(id: String) -> String {
        return endpoint("/evenements/\(id)")
    }
    
    /// Endpoint pour mettre à jour un événement (PATCH /evenements/{id})
    static func updateEvenementEndpoint(id: String) -> String {
        return endpoint("/evenements/\(id)")
    }
    
    /// Endpoint pour supprimer un événement (DELETE /evenements/{id})
    static func deleteEvenementEndpoint(id: String) -> String {
        return endpoint("/evenements/\(id)")
    }
    
    // MARK: - Disponibilites Endpoints
    
    /// Endpoint pour créer une disponibilité (POST /disponibilites)
    static var createDisponibiliteEndpoint: String {
        return endpoint("/disponibilites")
    }
    
    /// Endpoint pour récupérer toutes les disponibilités (GET /disponibilites)
    static var getAllDisponibilitesEndpoint: String {
        return endpoint("/disponibilites")
    }
    
    /// Endpoint pour supprimer toutes les disponibilités (DELETE /disponibilites)
    static var deleteAllDisponibilitesEndpoint: String {
        return endpoint("/disponibilites")
    }
    
    /// Endpoint pour récupérer les disponibilités par jour (GET /disponibilites/jour/{jour})
    static func getDisponibilitesByDayEndpoint(jour: String) -> String {
        let encodedJour = jour.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? jour
        return endpoint("/disponibilites/jour/\(encodedJour)")
    }
    
    /// Endpoint pour récupérer une disponibilité par ID (GET /disponibilites/{id})
    static func getDisponibiliteByIdEndpoint(id: String) -> String {
        return endpoint("/disponibilites/\(id)")
    }
    
    /// Endpoint pour mettre à jour une disponibilité (PATCH /disponibilites/{id})
    static func updateDisponibiliteEndpoint(id: String) -> String {
        return endpoint("/disponibilites/\(id)")
    }
    
    /// Endpoint pour supprimer une disponibilité (DELETE /disponibilites/{id})
    static func deleteDisponibiliteEndpoint(id: String) -> String {
        return endpoint("/disponibilites/\(id)")
    }
    
    // MARK: - Offres Endpoints
    
    /// Endpoint pour créer une offre (POST /offre)
    static var createOffreEndpoint: String {
        return endpoint("/offre")
    }
    
    /// Endpoint pour récupérer toutes les offres actives (GET /offre)
    static var getAllOffresEndpoint: String {
        return endpoint("/offre")
    }
    
    /// Endpoint pour rechercher des offres par requête (GET /offre/search?q={query})
    static func searchOffresEndpoint(query: String) -> String {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return endpoint("/offre/search?q=\(encodedQuery)")
    }
    
    /// Endpoint pour trouver des offres par tags (GET /offre/tags?tags={tags})
    static func getOffresByTagsEndpoint(tags: String) -> String {
        let encodedTags = tags.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tags
        return endpoint("/offre/tags?tags=\(encodedTags)")
    }
    
    /// Endpoint pour trouver des offres par ville (GET /offre/location/{city})
    static func getOffresByLocationEndpoint(city: String) -> String {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? city
        return endpoint("/offre/location/\(encodedCity)")
    }
    
    /// Endpoint pour récupérer les offres de l'utilisateur actuel (GET /offre/my-offers)
    static var getMyOffresEndpoint: String {
        return endpoint("/offre/my-offers")
    }
    
    /// Endpoint pour récupérer les offres aimées par l'utilisateur actuel (GET /offre/liked)
    static var getLikedOffresEndpoint: String {
        return endpoint("/offre/liked")
    }
    
    /// Endpoint pour trouver des offres par ID utilisateur (GET /offre/user/{userId})
    static func getOffresByUserIdEndpoint(userId: String) -> String {
        return endpoint("/offre/user/\(userId)")
    }
    
    /// Endpoint pour récupérer les offres populaires (GET /offre/popular)
    static var getPopularOffresEndpoint: String {
        return endpoint("/offre/popular")
    }
    
    /// Endpoint pour récupérer une offre par ID (GET /offre/{id})
    static func getOffreByIdEndpoint(id: String) -> String {
        return endpoint("/offre/\(id)")
    }
    
    /// Endpoint pour mettre à jour une offre (PATCH /offre/{id})
    static func updateOffreEndpoint(id: String) -> String {
        return endpoint("/offre/\(id)")
    }
    
    /// Endpoint pour supprimer une offre (DELETE /offre/{id})
    static func deleteOffreEndpoint(id: String) -> String {
        return endpoint("/offre/\(id)")
    }
    
    /// Endpoint pour aimer ou ne plus aimer une offre (POST /offre/{id}/like)
    static func likeOffreEndpoint(id: String) -> String {
        return endpoint("/offre/\(id)/like")
    }
    
    // MARK: - Student Preferences Endpoints
    
    /// Endpoint pour créer ou compléter les préférences étudiant (POST /student-preferences)
    static var createStudentPreferencesEndpoint: String {
        return endpoint("/student-preferences")
    }
    
    /// Endpoint pour récupérer les préférences de l'utilisateur connecté (GET /student-preferences/my-preferences)
    static var getMyStudentPreferencesEndpoint: String {
        return endpoint("/student-preferences/my-preferences")
    }
    
    /// Endpoint pour mettre à jour les préférences de l'utilisateur connecté (PATCH /student-preferences/my-preferences)
    static var updateMyStudentPreferencesEndpoint: String {
        return endpoint("/student-preferences/my-preferences")
    }
    
    /// Endpoint pour supprimer les préférences de l'utilisateur connecté (DELETE /student-preferences/my-preferences)
    static var deleteMyStudentPreferencesEndpoint: String {
        return endpoint("/student-preferences/my-preferences")
    }
    
    /// Endpoint pour mettre à jour une étape spécifique (PATCH /student-preferences/step/{step})
    static func updateStudentPreferencesStepEndpoint(step: Int) -> String {
        return endpoint("/student-preferences/step/\(step)")
    }
    
    /// Endpoint pour obtenir la progression du formulaire (GET /student-preferences/progress)
    static var getStudentPreferencesProgressEndpoint: String {
        return endpoint("/student-preferences/progress")
    }
    
    // MARK: - Reclamations Endpoints
    
    /// Endpoint pour créer une nouvelle réclamation (POST /reclamations)
    static var createReclamationEndpoint: String {
        return endpoint("/reclamations")
    }
    
    /// Endpoint pour récupérer toutes les réclamations (GET /reclamations) - Admin seulement
    static var getAllReclamationsEndpoint: String {
        return endpoint("/reclamations")
    }
    
    /// Endpoint pour récupérer les réclamations de l'utilisateur connecté (GET /reclamations/my-reclamations)
    static var getMyReclamationsEndpoint: String {
        return endpoint("/reclamations/my-reclamations")
    }
    
    /// Endpoint pour récupérer les réclamations par type (GET /reclamations/type/{type})
    static func getReclamationsByTypeEndpoint(type: String) -> String {
        let encodedType = type.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? type
        return endpoint("/reclamations/type/\(encodedType)")
    }
    
    /// Endpoint pour obtenir les statistiques par type (GET /reclamations/stats/types)
    static var getReclamationTypeStatsEndpoint: String {
        return endpoint("/reclamations/stats/types")
    }
    
    /// Endpoint pour obtenir les statistiques par statut (GET /reclamations/stats/status)
    static var getReclamationStatusStatsEndpoint: String {
        return endpoint("/reclamations/stats/status")
    }
    
    /// Endpoint pour récupérer une réclamation par ID (GET /reclamations/{id})
    static func getReclamationByIdEndpoint(id: String) -> String {
        return endpoint("/reclamations/\(id)")
    }
    
    /// Endpoint pour mettre à jour une réclamation (PATCH /reclamations/{id})
    static func updateReclamationEndpoint(id: String) -> String {
        return endpoint("/reclamations/\(id)")
    }
    
    /// Endpoint pour supprimer une réclamation (DELETE /reclamations/{id})
    static func deleteReclamationEndpoint(id: String) -> String {
        return endpoint("/reclamations/\(id)")
    }
    
    /// Endpoint pour modifier le statut d'une réclamation (PATCH /reclamations/{id}/status)
    static func updateReclamationStatusEndpoint(id: String) -> String {
        return endpoint("/reclamations/\(id)/status")
    }
    
    // MARK: - Configuration
    
    /// Timeout pour les requêtes réseau (en secondes)
    static let requestTimeout: TimeInterval = 30.0
    
    /// Vérifie si l'URL de base est configurée
    static var isConfigured: Bool {
        // Vérifie que l'URL n'est pas vide et qu'elle est valide
        return !baseURL.isEmpty && URL(string: baseURL) != nil
    }
    
    // MARK: - AI Routine Endpoints
    
    /// Endpoint pour analyser la routine avec IA (POST /ai/routine/analyze)
    static var analyzeRoutineEndpoint: String {
        return endpoint("/cv-ai/analyze")
    }
    
    // MARK: - AICV Endpoints
    
    /// Endpoint pour analyser un CV avec IA (POST /cv-ai/extract-cv)
    static var analyzeCVEndpoint: String {
        return endpoint("/cv-ai/extract-cv")
    }
    
    /// Endpoint pour enregistrer le profil depuis un CV (PATCH /user/me/cv/profile)
    static var saveCVToProfileEndpoint: String {
        return endpoint("/user/me/cv/profile")
    }
    
    // MARK: - Chat Endpoints
    
    /// Endpoint pour créer ou obtenir un chat existant (POST /chat)
    static var createChatEndpoint: String {
        return endpoint("/chat")
    }
    
    /// Alias pour createChatEndpoint (compatibilité avec ChatRepository)
    static var createOrGetChatEndpoint: String {
        return createChatEndpoint
    }
    
    /// Endpoint pour envoyer un message dans un chat (POST /chat/{chatId}/message)
    static func sendMessageEndpoint(chatId: String) -> String {
        return endpoint("/chat/\(chatId)/message")
    }
    
    /// Endpoint pour récupérer tous les chats de l'utilisateur (GET /chat/my-chats)
    static var getMyChatsEndpoint: String {
        return endpoint("/chat/my-chats")
    }
    
    /// Endpoint pour récupérer les messages d'un chat avec pagination (GET /chat/{chatId}/messages)
    static func getChatMessagesEndpoint(chatId: String, page: Int? = nil, limit: Int? = nil) -> String {
        var url = endpoint("/chat/\(chatId)/messages")
        var queryParams: [String] = []
        
        if let page = page {
            queryParams.append("page=\(page)")
        }
        if let limit = limit {
            queryParams.append("limit=\(limit)")
        }
        
        if !queryParams.isEmpty {
            url += "?" + queryParams.joined(separator: "&")
        }
        
        return url
    }
    
    /// Endpoint pour récupérer un chat par ID (GET /chat/{chatId})
    static func getChatByIdEndpoint(chatId: String) -> String {
        return endpoint("/chat/\(chatId)")
    }
    
    /// Endpoint pour supprimer un chat (DELETE /chat/{chatId})
    static func deleteChatEndpoint(chatId: String) -> String {
        return endpoint("/chat/\(chatId)")
    }
    
    /// Endpoint pour bloquer un chat (PATCH /chat/{chatId}/block) - Entreprise seulement
    static func blockChatEndpoint(chatId: String) -> String {
        return endpoint("/chat/\(chatId)/block")
    }
    
    /// Endpoint pour débloquer un chat (PATCH /chat/{chatId}/unblock) - Entreprise seulement
    static func unblockChatEndpoint(chatId: String) -> String {
        return endpoint("/chat/\(chatId)/unblock")
    }
    
    /// Endpoint pour accepter un candidat (PATCH /chat/{chatId}/accept) - Entreprise seulement
    static func acceptChatEndpoint(chatId: String) -> String {
        return endpoint("/chat/\(chatId)/accept")
    }
    
    /// Alias pour acceptChatEndpoint (compatibilité avec ChatRepository)
    static func acceptCandidateEndpoint(chatId: String) -> String {
        return acceptChatEndpoint(chatId: chatId)
    }
    
    /// Endpoint pour vérifier si un utilisateur peut appeler pour une offre (GET /chat/can-call/{offerId})
    static func canCallEndpoint(offerId: String) -> String {
        return endpoint("/chat/can-call/\(offerId)")
    }
    
    /// Alias pour canCallEndpoint (compatibilité avec ChatRepository)
    static func canMakeCallEndpoint(offerId: String) -> String {
        return canCallEndpoint(offerId: offerId)
    }
    
    /// Endpoint pour uploader un fichier média de chat (POST /chat/upload)
    static var uploadChatMediaEndpoint: String {
        return endpoint("/chat/upload")
    }
    
    /// Alias pour uploadChatMediaEndpoint (compatibilité avec ChatRepository)
    static var uploadMediaEndpoint: String {
        return uploadChatMediaEndpoint
    }
    
    /// Endpoint pour récupérer les messages d'un chat (GET /chat/{chatId}/messages)
    static func getMessagesEndpoint(chatId: String) -> String {
        return getChatMessagesEndpoint(chatId: chatId)
    }
    
    /// Endpoint pour marquer les messages comme lus (PATCH /chat/{chatId}/mark-read)
    static func markMessagesReadEndpoint(chatId: String) -> String {
        return endpoint("/chat/\(chatId)/mark-read")
    }
    
    /// Alias pour markMessagesReadEndpoint (compatibilité avec ChatRepository)
    static func markMessagesAsReadEndpoint(chatId: String) -> String {
        return markMessagesReadEndpoint(chatId: chatId)
    }
}
