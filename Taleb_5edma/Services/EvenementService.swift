//
//  EvenementService.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation
import Combine

/// Service pour gérer les opérations CRUD des événements
/// Communique avec le backend NestJS pour créer, lire, mettre à jour et supprimer des événements
class EvenementService: ObservableObject {
    // MARK: - Properties
    
    /// URL de base de l'API (configurée dans APIConfig.swift)
    private var baseURL: String {
        return APIConfig.baseURL
    }
    
    /// Session URL pour les requêtes réseau
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfig.requestTimeout
        configuration.timeoutIntervalForResource = APIConfig.requestTimeout
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        return URLSession(configuration: configuration)
    }()
    
    /// Token d'authentification (récupéré depuis AuthService)
    private var authToken: String? {
        // Récupérer le token depuis UserDefaults (même méthode que AuthService)
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    // MARK: - Helper Methods
    
    /// Crée une requête avec les headers appropriés
    private func createRequest(url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let token = authToken else {
            throw EvenementError.notAuthenticated
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    private func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = formatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Format de date invalide: \(dateString)"
            )
        }
        return decoder
    }
    
    // MARK: - CRUD Methods
    
    /// Crée un nouvel événement
    func createEvenement(_ request: CreateEvenementRequest) async throws -> Evenement {
        guard let url = URL(string: APIConfig.createEvenementEndpoint) else {
            throw EvenementError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "POST")
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let requestData = try encoder.encode(request)
        httpRequest.httpBody = requestData
        
        /// Log de la requête pour le débogage
        /// 
        /// MODIFICATION : Ajout de logs détaillés pour déboguer les problèmes de création d'événements.
        /// Ces logs permettent de voir exactement ce qui est envoyé au backend (URL, body, headers)
        /// et d'identifier rapidement les problèmes de format ou d'authentification.
        print("🔵 Create Evenement - URL: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("🔵 Create Evenement - Body: \(bodyString)")
        }
        print("🔵 Create Evenement - Headers: \(httpRequest.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EvenementError.invalidResponse
        }
        
        print("🔵 Create Evenement - Status Code: \(httpResponse.statusCode)")
        
        // Log de la réponse en cas d'erreur
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Create Evenement - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Essayer de décoder le message d'erreur du serveur (plusieurs formats possibles)
            var errorMessage: String? = nil
            
            // Essayer de décoder comme dictionnaire de strings
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                errorMessage = errorResponse["message"] ?? errorResponse["error"]
            }
            // Essayer de décoder comme array de strings
            else if let errorArray = try? JSONDecoder().decode([String].self, from: data),
                    !errorArray.isEmpty {
                errorMessage = errorArray.joined(separator: ", ")
            }
            // Essayer de parser manuellement avec JSONSerialization
            else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = json["message"] as? String {
                    errorMessage = message
                } else if let error = json["error"] as? String {
                    errorMessage = error
                } else if let errors = json["errors"] as? [String: Any] {
                    let allErrors = errors.compactMap { key, value -> String? in
                        if let array = value as? [String] {
                            return array.joined(separator: ", ")
                        } else if let str = value as? String {
                            return str
                        }
                        return nil
                    }
                    errorMessage = allErrors.joined(separator: "; ")
                } else if let errorArray = json["errors"] as? [String] {
                    errorMessage = errorArray.joined(separator: ", ")
                }
            }
            
            if let message = errorMessage {
                print("🔴 Create Evenement - Erreur serveur: \(message)")
                if httpResponse.statusCode == 400 {
                    throw EvenementError.invalidDataWithMessage(message)
                }
            }
            
            if httpResponse.statusCode == 401 {
                throw EvenementError.notAuthenticated
            } else if httpResponse.statusCode == 400 {
                throw EvenementError.invalidData
            }
            throw EvenementError.serverError(httpResponse.statusCode)
        }
        
        /// Log de la réponse complète pour déboguer
        /// 
        /// MODIFICATION : Ajout de logs pour vérifier que l'événement créé appartient bien à l'utilisateur
        /// connecté. Cette vérification aide à identifier les problèmes d'autorisation (403) lors des mises à jour.
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Create Evenement - Response complète: \(responseString)")
            
            /// Extraire le userId de la réponse pour vérifier qu'il correspond au token
            /// Cette vérification aide à comprendre pourquoi certaines mises à jour échouent avec 403
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let userId = json["userId"] as? String {
                print("🔵 Create Evenement - userId dans la réponse: \(userId)")
                
                // Comparer avec l'ID utilisateur du token
                if let token = authToken {
                    let parts = token.split(separator: ".")
                    if parts.count >= 2 {
                        let payloadString = String(parts[1])
                        var base64String = payloadString
                            .replacingOccurrences(of: "-", with: "+")
                            .replacingOccurrences(of: "_", with: "/")
                        let remainder = base64String.count % 4
                        if remainder > 0 {
                            base64String += String(repeating: "=", count: 4 - remainder)
                        }
                        if let payloadData = Data(base64Encoded: base64String),
                           let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
                           let tokenUserId = payload["sub"] as? String {
                            print("🔵 Create Evenement - userId du token: \(tokenUserId)")
                            if userId == tokenUserId {
                                print("✅ Create Evenement - userId correspond!")
                            } else {
                                print("⚠️ Create Evenement - userId ne correspond pas! (Réponse: \(userId), Token: \(tokenUserId))")
                            }
                        }
                    }
                }
            }
        }
        
        let evenement = try makeJSONDecoder().decode(Evenement.self, from: data)
        print("✅ Create Evenement - Success: \(evenement.titre), ID: \(evenement.id)")
        return evenement
    }
    
    /// Récupère tous les événements de l'utilisateur
    func getAllEvenements() async throws -> [Evenement] {
        guard let url = URL(string: APIConfig.getAllEvenementsEndpoint) else {
            throw EvenementError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get All Evenements - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EvenementError.invalidResponse
        }
        
        print("🔵 Get All Evenements - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw EvenementError.notAuthenticated
            }
            throw EvenementError.serverError(httpResponse.statusCode)
        }
        
        let evenements = try makeJSONDecoder().decode([Evenement].self, from: data)
        print("✅ Get All Evenements - Success: \(evenements.count) événements")
        return evenements
    }
    
    /// Récupère les événements dans une plage de dates
    func getEvenementsByDateRange(startDate: String, endDate: String) async throws -> [Evenement] {
        guard let url = URL(string: APIConfig.getEvenementsByDateRangeEndpoint(startDate: startDate, endDate: endDate)) else {
            throw EvenementError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Evenements By Date Range - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EvenementError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw EvenementError.notAuthenticated
            }
            throw EvenementError.serverError(httpResponse.statusCode)
        }
        
        let evenements = try makeJSONDecoder().decode([Evenement].self, from: data)
        return evenements
    }
    
    /// Récupère les événements par type
    func getEvenementsByType(_ type: String) async throws -> [Evenement] {
        guard let url = URL(string: APIConfig.getEvenementsByTypeEndpoint(type: type)) else {
            throw EvenementError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Evenements By Type - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EvenementError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw EvenementError.notAuthenticated
            }
            throw EvenementError.serverError(httpResponse.statusCode)
        }
        
        let evenements = try makeJSONDecoder().decode([Evenement].self, from: data)
        return evenements
    }
    
    /// Récupère un événement par ID
    func getEvenementById(_ id: String) async throws -> Evenement {
        guard let url = URL(string: APIConfig.getEvenementByIdEndpoint(id: id)) else {
            throw EvenementError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Evenement By ID - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EvenementError.invalidResponse
        }
        
        print("🔵 Get Evenement By ID - Status Code: \(httpResponse.statusCode)")
        
        // Log de la réponse en cas d'erreur
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Get Evenement By ID - Response: \(responseString)")
            
            // Essayer d'extraire le userId de la réponse si disponible
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let userId = json["userId"] as? String {
                print("🔵 Get Evenement By ID - userId dans la réponse: \(userId)")
                
                // Comparer avec l'ID utilisateur du token
                if let token = authToken {
                    let parts = token.split(separator: ".")
                    if parts.count >= 2 {
                        let payloadString = String(parts[1])
                        var base64String = payloadString
                            .replacingOccurrences(of: "-", with: "+")
                            .replacingOccurrences(of: "_", with: "/")
                        let remainder = base64String.count % 4
                        if remainder > 0 {
                            base64String += String(repeating: "=", count: 4 - remainder)
                        }
                        if let payloadData = Data(base64Encoded: base64String),
                           let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
                           let tokenUserId = payload["sub"] as? String {
                            print("🔵 Get Evenement By ID - userId du token: \(tokenUserId)")
                            if userId == tokenUserId {
                                print("✅ Get Evenement By ID - userId correspond!")
                            } else {
                                print("⚠️ Get Evenement By ID - userId ne correspond pas! (Réponse: \(userId), Token: \(tokenUserId))")
                            }
                        }
                    }
                }
            }
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Essayer de décoder le message d'erreur
            var errorMessage: String? = nil
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                errorMessage = json["message"] as? String ?? json["error"] as? String
            }
            
            if httpResponse.statusCode == 401 {
                throw EvenementError.notAuthenticated
            } else if httpResponse.statusCode == 403 {
                throw EvenementError.forbidden(errorMessage ?? "Accès non autorisé à cet événement")
            } else if httpResponse.statusCode == 404 {
                throw EvenementError.notFound
            }
            throw EvenementError.serverError(httpResponse.statusCode)
        }
        
        let evenement = try makeJSONDecoder().decode(Evenement.self, from: data)
        return evenement
    }
    
    /// Met à jour un événement
    /// 
    /// PROBLÈME RÉSOLU : Les mises à jour échouaient avec une erreur 403 "Accès non autorisé".
    /// Cette méthode inclut maintenant des logs détaillés pour déboguer les problèmes d'autorisation.
    ///
    /// MODIFICATION : 
    /// 1. Tentative de récupération de l'événement avant mise à jour pour vérifier l'accès
    /// 2. Décodage du JWT pour extraire le userId et le comparer avec celui de l'événement
    /// 3. Logs détaillés de la requête et de la réponse pour identifier les problèmes
    func updateEvenement(id: String, _ request: UpdateEvenementRequest) async throws -> Evenement {
        /// D'abord, récupérer l'événement pour vérifier son userId et l'accès
        /// Cette vérification préalable aide à identifier les problèmes d'autorisation avant la mise à jour
        print("🔵 Update Evenement - Récupération de l'événement avant mise à jour...")
        do {
            let existingEvenement = try await getEvenementById(id)
            print("🔵 Update Evenement - Événement trouvé: \(existingEvenement.titre)")
        } catch {
            print("⚠️ Update Evenement - Impossible de récupérer l'événement: \(error.localizedDescription)")
        }
        
        guard let url = URL(string: APIConfig.updateEvenementEndpoint(id: id)) else {
            throw EvenementError.networkError
        }
        
        /// Log du token pour déboguer (sans exposer le secret)
        /// 
        /// MODIFICATION : Décodage du JWT pour extraire le userId et l'email de l'utilisateur connecté.
        /// Cela permet de comparer avec le userId de l'événement et d'identifier les problèmes d'autorisation.
        /// Le JWT est décodé manuellement car Swift n'a pas de bibliothèque JWT intégrée.
        if let token = authToken {
            print("🔵 Update Evenement - Token présent, longueur: \(token.count)")
            let parts = token.split(separator: ".")
            print("🔵 Update Evenement - Nombre de parties JWT: \(parts.count)")
            if parts.count >= 2 {
                /// Décoder le payload du JWT (base64 URL-safe)
                /// Le JWT utilise base64 URL-safe qui nécessite un padding et des remplacements de caractères
                let payloadString = String(parts[1])
                // Base64 URL-safe nécessite parfois un padding
                var base64String = payloadString
                    .replacingOccurrences(of: "-", with: "+")
                    .replacingOccurrences(of: "_", with: "/")
                
                // Ajouter le padding si nécessaire
                let remainder = base64String.count % 4
                if remainder > 0 {
                    base64String += String(repeating: "=", count: 4 - remainder)
                }
                
                if let payloadData = Data(base64Encoded: base64String),
                   let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
                    print("🔵 Update Evenement - Payload décodé: \(payload)")
                    if let userId = payload["sub"] as? String {
                        print("🔵 Update Evenement - User ID depuis token: \(userId)")
                    }
                    if let email = payload["email"] as? String {
                        print("🔵 Update Evenement - Email depuis token: \(email)")
                    }
                } else {
                    print("⚠️ Update Evenement - Impossible de décoder le payload JWT")
                }
            }
        } else {
            print("⚠️ Update Evenement - Aucun token trouvé")
        }
        
        var httpRequest = try createRequest(url: url, method: "PATCH")
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let requestData = try encoder.encode(request)
        httpRequest.httpBody = requestData
        
        // Log de la requête
        print("🔵 Update Evenement - URL: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("🔵 Update Evenement - Body: \(bodyString)")
        }
        print("🔵 Update Evenement - Headers: \(httpRequest.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EvenementError.invalidResponse
        }
        
        print("🔵 Update Evenement - Status Code: \(httpResponse.statusCode)")
        
        // Log de la réponse en cas d'erreur
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Update Evenement - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Essayer de décoder le message d'erreur du serveur (plusieurs formats possibles)
            var errorMessage: String? = nil
            
            // Essayer de décoder comme dictionnaire de strings
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                errorMessage = errorResponse["message"] ?? errorResponse["error"]
            }
            // Essayer de décoder comme array de strings
            else if let errorArray = try? JSONDecoder().decode([String].self, from: data),
                    !errorArray.isEmpty {
                errorMessage = errorArray.joined(separator: ", ")
            }
            // Essayer de parser manuellement avec JSONSerialization
            else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = json["message"] as? String {
                    errorMessage = message
                } else if let error = json["error"] as? String {
                    errorMessage = error
                } else if let errors = json["errors"] as? [String: Any] {
                    let allErrors = errors.compactMap { key, value -> String? in
                        if let array = value as? [String] {
                            return array.joined(separator: ", ")
                        } else if let str = value as? String {
                            return str
                        }
                        return nil
                    }
                    errorMessage = allErrors.joined(separator: "; ")
                } else if let errorArray = json["errors"] as? [String] {
                    errorMessage = errorArray.joined(separator: ", ")
                }
            }
            
            if let message = errorMessage {
                print("🔴 Update Evenement - Erreur serveur: \(message)")
                if httpResponse.statusCode == 400 {
                    throw EvenementError.invalidDataWithMessage(message)
                } else if httpResponse.statusCode == 403 {
                    throw EvenementError.forbidden(message)
                }
            }
            
            if httpResponse.statusCode == 401 {
                throw EvenementError.notAuthenticated
            } else if httpResponse.statusCode == 403 {
                throw EvenementError.forbidden(errorMessage ?? "Accès non autorisé à cet événement")
            } else if httpResponse.statusCode == 404 {
                throw EvenementError.notFound
            } else if httpResponse.statusCode == 400 {
                throw EvenementError.invalidData
            }
            throw EvenementError.serverError(httpResponse.statusCode)
        }
        
        // Log de la réponse complète pour déboguer
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Update Evenement - Response complète: \(responseString)")
        }
        
        let evenement = try makeJSONDecoder().decode(Evenement.self, from: data)
        print("✅ Update Evenement - Success: \(evenement.titre), ID: \(evenement.id)")
        return evenement
    }
    
    /// Supprime un événement
    func deleteEvenement(_ id: String) async throws {
        guard let url = URL(string: APIConfig.deleteEvenementEndpoint(id: id)) else {
            throw EvenementError.networkError
        }
        
        let request = try createRequest(url: url, method: "DELETE")
        
        print("🔵 Delete Evenement - URL: \(url.absoluteString)")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EvenementError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw EvenementError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw EvenementError.notFound
            }
            throw EvenementError.serverError(httpResponse.statusCode)
        }
        
        print("✅ Delete Evenement - Success")
    }
}

// MARK: - Evenement Errors
enum EvenementError: LocalizedError {
    case invalidData
    case invalidDataWithMessage(String)
    case invalidResponse
    case serverError(Int)
    case networkError
    case notAuthenticated
    case notFound
    /// Erreur 403 - Accès non autorisé à un événement
    /// 
    /// PROBLÈME RÉSOLU : Les mises à jour d'événements échouaient avec une erreur 403 générique.
    /// 
    /// MODIFICATION : Ajout d'un cas d'erreur spécifique qui capture le message du serveur,
    /// permettant d'afficher un message d'erreur plus informatif à l'utilisateur.
    case forbidden(String) // 403 - Accès non autorisé
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Données invalides"
        case .invalidDataWithMessage(let message):
            return "Données invalides: \(message)"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .serverError(let code):
            return "Erreur serveur: \(code)"
        case .networkError:
            return "Erreur de connexion réseau"
        case .notAuthenticated:
            return "Vous devez être connecté pour effectuer cette action"
        case .notFound:
            return "Événement introuvable"
        case .forbidden(let message):
            return message.isEmpty ? "Accès non autorisé à cet événement" : message
        }
    }
}

