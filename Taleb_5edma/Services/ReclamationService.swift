//
//  ReclamationService.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation
import Combine

/// Service pour gérer les opérations CRUD des réclamations
/// Communique avec le backend NestJS pour créer, lire, mettre à jour et supprimer des réclamations
class ReclamationService: ObservableObject {
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
    
    /// Token d'authentification (récupéré depuis UserDefaults)
    private var authToken: String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    /// Liste réactive des réclamations à afficher dans l'interface
    @Published var reclamations: [Reclamation] = []
    
    /// Indicateur de chargement pour piloter les spinners
    @Published var isLoading = false
    
    // MARK: - Helper Methods
    
    /// Crée une requête avec les headers appropriés
    private func createRequest(url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let token = authToken else {
            throw ReclamationError.notAuthenticated
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
            // Essayer aussi le format simple YYYY-MM-DD
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd"
            simpleFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = simpleFormatter.date(from: dateString) {
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
    
    /// Crée une nouvelle réclamation
    func createReclamation(_ request: CreateReclamationRequest) async throws -> Reclamation {
        guard let url = URL(string: APIConfig.createReclamationEndpoint) else {
            throw ReclamationError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "POST")
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let requestData = try encoder.encode(request)
        httpRequest.httpBody = requestData
        
        print("🔵 Create Reclamation - URL: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("🔵 Create Reclamation - Body: \(bodyString)")
        }
        print("🔵 Create Reclamation - Headers: \(httpRequest.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReclamationError.invalidResponse
        }
        
        print("🔵 Create Reclamation - Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Create Reclamation - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            var errorMessage: String? = nil
            
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                errorMessage = errorResponse["message"] ?? errorResponse["error"]
            } else if let errorArray = try? JSONDecoder().decode([String].self, from: data),
                      !errorArray.isEmpty {
                errorMessage = errorArray.joined(separator: ", ")
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = json["message"] as? String {
                    errorMessage = message
                } else if let error = json["error"] as? String {
                    errorMessage = error
                }
            }
            
            if let message = errorMessage {
                print("🔴 Create Reclamation - Erreur serveur: \(message)")
                if httpResponse.statusCode == 400 {
                    throw ReclamationError.invalidDataWithMessage(message)
                }
            }
            
            if httpResponse.statusCode == 401 {
                throw ReclamationError.notAuthenticated
            }
            throw ReclamationError.serverError(httpResponse.statusCode)
        }
        
        let reclamation = try makeJSONDecoder().decode(Reclamation.self, from: data)
        print("✅ Create Reclamation - Succès")
        return reclamation
    }
    
    /// Récupère toutes les réclamations (Admin seulement)
    func getAllReclamations() async throws -> [Reclamation] {
        guard let url = URL(string: APIConfig.getAllReclamationsEndpoint) else {
            throw ReclamationError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get All Reclamations - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReclamationError.invalidResponse
        }
        
        print("🔵 Get All Reclamations - Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Get All Reclamations - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ReclamationError.notAuthenticated
            } else if httpResponse.statusCode == 403 {
                throw ReclamationError.forbidden
            }
            throw ReclamationError.serverError(httpResponse.statusCode)
        }
        
        let reclamations = try makeJSONDecoder().decode([Reclamation].self, from: data)
        print("✅ Get All Reclamations - Succès: \(reclamations.count) réclamations")
        return reclamations
    }
    
    /// Récupère les réclamations de l'utilisateur connecté
    func getMyReclamations() async throws -> [Reclamation] {
        guard let url = URL(string: APIConfig.getMyReclamationsEndpoint) else {
            throw ReclamationError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get My Reclamations - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReclamationError.invalidResponse
        }
        
        print("🔵 Get My Reclamations - Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Get My Reclamations - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ReclamationError.notAuthenticated
            }
            throw ReclamationError.serverError(httpResponse.statusCode)
        }
        
        let reclamations = try makeJSONDecoder().decode([Reclamation].self, from: data)
        print("✅ Get My Reclamations - Succès: \(reclamations.count) réclamations")
        return reclamations
    }
    
    /// Récupère les réclamations par type
    func getReclamationsByType(_ type: ReclamationType) async throws -> [Reclamation] {
        guard let url = URL(string: APIConfig.getReclamationsByTypeEndpoint(type: type.toBackendValue())) else {
            throw ReclamationError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Reclamations By Type - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReclamationError.invalidResponse
        }
        
        print("🔵 Get Reclamations By Type - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ReclamationError.notAuthenticated
            }
            throw ReclamationError.serverError(httpResponse.statusCode)
        }
        
        let reclamations = try makeJSONDecoder().decode([Reclamation].self, from: data)
        print("✅ Get Reclamations By Type - Succès: \(reclamations.count) réclamations")
        return reclamations
    }
    
    /// Récupère une réclamation par ID
    func getReclamationById(_ id: String) async throws -> Reclamation {
        guard let url = URL(string: APIConfig.getReclamationByIdEndpoint(id: id)) else {
            throw ReclamationError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Reclamation By ID - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReclamationError.invalidResponse
        }
        
        print("🔵 Get Reclamation By ID - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ReclamationError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw ReclamationError.notFound
            }
            throw ReclamationError.serverError(httpResponse.statusCode)
        }
        
        let reclamation = try makeJSONDecoder().decode(Reclamation.self, from: data)
        print("✅ Get Reclamation By ID - Succès")
        return reclamation
    }
    
    /// Met à jour une réclamation
    func updateReclamation(_ id: String, request: UpdateReclamationRequest) async throws -> Reclamation {
        guard let url = URL(string: APIConfig.updateReclamationEndpoint(id: id)) else {
            throw ReclamationError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "PATCH")
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let requestData = try encoder.encode(request)
        httpRequest.httpBody = requestData
        
        print("🔵 Update Reclamation - URL: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("🔵 Update Reclamation - Body: \(bodyString)")
        }
        print("🔵 Update Reclamation - Headers: \(httpRequest.allHTTPHeaderFields ?? [:])")
        
        // Log token info for debugging
        if let token = authToken {
            print("🔵 Update Reclamation - Token présent: \(token.prefix(20))...")
        } else {
            print("🔴 Update Reclamation - Aucun token trouvé!")
        }
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReclamationError.invalidResponse
        }
        
        print("🔵 Update Reclamation - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            var errorMessage: String? = nil
            
            // Try to decode error response
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔴 Update Reclamation - Response: \(responseString)")
                
                // Try to parse as JSON
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    errorMessage = json["message"] as? String ?? json["error"] as? String
                } else if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                    errorMessage = errorResponse["message"] ?? errorResponse["error"]
                }
            }
            
            if let message = errorMessage {
                print("🔴 Update Reclamation - Erreur serveur: \(message)")
                if httpResponse.statusCode == 400 {
                    throw ReclamationError.invalidDataWithMessage(message)
                } else if httpResponse.statusCode == 403 {
                    // Use the actual backend error message for 403
                    throw ReclamationError.forbiddenWithMessage(message)
                }
            }
            
            if httpResponse.statusCode == 401 {
                throw ReclamationError.notAuthenticated
            } else if httpResponse.statusCode == 403 {
                throw ReclamationError.forbidden
            } else if httpResponse.statusCode == 404 {
                throw ReclamationError.notFound
            }
            throw ReclamationError.serverError(httpResponse.statusCode)
        }
        
        let reclamation = try makeJSONDecoder().decode(Reclamation.self, from: data)
        print("✅ Update Reclamation - Succès")
        return reclamation
    }
    
    /// Supprime une réclamation
    func deleteReclamation(_ id: String) async throws {
        guard let url = URL(string: APIConfig.deleteReclamationEndpoint(id: id)) else {
            throw ReclamationError.networkError
        }
        
        let request = try createRequest(url: url, method: "DELETE")
        
        print("🔵 Delete Reclamation - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReclamationError.invalidResponse
        }
        
        print("🔵 Delete Reclamation - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ReclamationError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw ReclamationError.notFound
            }
            throw ReclamationError.serverError(httpResponse.statusCode)
        }
        
        print("✅ Delete Reclamation - Succès")
    }
    
    /// Modifie le statut d'une réclamation
    func updateReclamationStatus(_ id: String, status: ReclamationStatus) async throws -> Reclamation {
        guard let url = URL(string: APIConfig.updateReclamationStatusEndpoint(id: id)) else {
            throw ReclamationError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "PATCH")
        
        // Créer la requête de mise à jour de statut
        let request = UpdateReclamationStatusRequest(status: status)
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let requestData = try encoder.encode(request)
        httpRequest.httpBody = requestData
        
        print("🔵 Update Reclamation Status - URL: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("🔵 Update Reclamation Status - Body: \(bodyString)")
        }
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReclamationError.invalidResponse
        }
        
        print("🔵 Update Reclamation Status - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ReclamationError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw ReclamationError.notFound
            }
            throw ReclamationError.serverError(httpResponse.statusCode)
        }
        
        let reclamation = try makeJSONDecoder().decode(Reclamation.self, from: data)
        print("✅ Update Reclamation Status - Succès")
        return reclamation
    }
    
    // MARK: - Statistics Methods
    
    /// Obtient les statistiques par type de réclamation
    func getTypeStats() async throws -> [ReclamationTypeStats] {
        guard let url = URL(string: APIConfig.getReclamationTypeStatsEndpoint) else {
            throw ReclamationError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Type Stats - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReclamationError.invalidResponse
        }
        
        print("🔵 Get Type Stats - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ReclamationError.notAuthenticated
            }
            throw ReclamationError.serverError(httpResponse.statusCode)
        }
        
        let stats = try makeJSONDecoder().decode([ReclamationTypeStats].self, from: data)
        print("✅ Get Type Stats - Succès")
        return stats
    }
    
    /// Obtient les statistiques par statut de réclamation
    func getStatusStats() async throws -> [ReclamationStatusStats] {
        guard let url = URL(string: APIConfig.getReclamationStatusStatsEndpoint) else {
            throw ReclamationError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Status Stats - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReclamationError.invalidResponse
        }
        
        print("🔵 Get Status Stats - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ReclamationError.notAuthenticated
            }
            throw ReclamationError.serverError(httpResponse.statusCode)
        }
        
        let stats = try makeJSONDecoder().decode([ReclamationStatusStats].self, from: data)
        print("✅ Get Status Stats - Succès")
        return stats
    }
    
    // MARK: - Convenience Methods
    
    /// Charge les réclamations de l'utilisateur connecté
    func loadReclamations() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let reclamations = try await getMyReclamations()
            await MainActor.run {
                self.reclamations = reclamations
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("❌ Erreur lors du chargement des réclamations: \(error.localizedDescription)")
        }
    }
    
    /// Filtre les réclamations par statut
    func filterByStatus(_ status: ReclamationStatus) -> [Reclamation] {
        return reclamations.filter { $0.status == status }
    }
    
    /// Obtenir les statistiques des réclamations (local)
    func getReclamationStats() -> (total: Int, pending: Int, inProgress: Int, resolved: Int) {
        let total = reclamations.count
        let pending = reclamations.filter { $0.status == .pending }.count
        let inProgress = reclamations.filter { $0.status == .inProgress }.count
        let resolved = reclamations.filter { $0.status == .resolved }.count
        
        return (total, pending, inProgress, resolved)
    }
}

// MARK: - Reclamation Errors

enum ReclamationError: LocalizedError {
    case invalidCredentials
    case invalidResponse
    case serverError(Int)
    case networkError
    case notAuthenticated
    case notFound
    case forbidden
    case forbiddenWithMessage(String)
    case invalidDataWithMessage(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Identifiants invalides"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .serverError(let code):
            return "Erreur serveur: \(code)"
        case .networkError:
            return "Erreur de connexion réseau"
        case .notAuthenticated:
            return "Vous devez être connecté pour effectuer cette action"
        case .notFound:
            return "Réclamation introuvable"
        case .forbidden:
            return "Accès interdit - Admin seulement"
        case .forbiddenWithMessage(let message):
            return message
        case .invalidDataWithMessage(let message):
            return "Données invalides: \(message)"
        }
    }
}
