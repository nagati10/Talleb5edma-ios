//
//  DisponibiliteService.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation
import Combine

/// Service pour gérer les opérations CRUD des disponibilités
/// Communique avec le backend NestJS pour créer, lire, mettre à jour et supprimer des disponibilités
class DisponibiliteService: ObservableObject {
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
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    // MARK: - Helper Methods
    
    /// Crée une requête avec les headers appropriés
    private func createRequest(url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let token = authToken else {
            throw DisponibiliteError.notAuthenticated
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
    
    /// Crée une nouvelle disponibilité
    func createDisponibilite(_ request: CreateDisponibiliteRequest) async throws -> Disponibilite {
        guard let url = URL(string: APIConfig.createDisponibiliteEndpoint) else {
            throw DisponibiliteError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "POST")
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let requestData = try encoder.encode(request)
        httpRequest.httpBody = requestData
        
        // Log de la requête
        print("🔵 Create Disponibilite - URL: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("🔵 Create Disponibilite - Body: \(bodyString)")
        }
        print("🔵 Create Disponibilite - Headers: \(httpRequest.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DisponibiliteError.invalidResponse
        }
        
        print("🔵 Create Disponibilite - Status Code: \(httpResponse.statusCode)")
        
        // Log de la réponse en cas d'erreur
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Create Disponibilite - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Essayer de décoder le message d'erreur du serveur
            var errorMessage: String? = nil
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                errorMessage = json["message"] as? String ?? json["error"] as? String
            }
            
            if let message = errorMessage {
                print("🔴 Create Disponibilite - Erreur serveur: \(message)")
            }
            
            if httpResponse.statusCode == 401 {
                throw DisponibiliteError.notAuthenticated
            } else if httpResponse.statusCode == 400 {
                throw DisponibiliteError.invalidData
            }
            throw DisponibiliteError.serverError(httpResponse.statusCode)
        }
        
        let disponibilite = try makeJSONDecoder().decode(Disponibilite.self, from: data)
        print("✅ Create Disponibilite - Success: \(disponibilite.jour)")
        return disponibilite
    }
    
    /// Récupère toutes les disponibilités de l'utilisateur
    func getAllDisponibilites() async throws -> [Disponibilite] {
        guard let url = URL(string: APIConfig.getAllDisponibilitesEndpoint) else {
            throw DisponibiliteError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get All Disponibilites - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DisponibiliteError.invalidResponse
        }
        
        print("🔵 Get All Disponibilites - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw DisponibiliteError.notAuthenticated
            }
            throw DisponibiliteError.serverError(httpResponse.statusCode)
        }
        
        let disponibilites = try makeJSONDecoder().decode([Disponibilite].self, from: data)
        print("✅ Get All Disponibilites - Success: \(disponibilites.count) disponibilités")
        return disponibilites
    }
    
    /// Supprime toutes les disponibilités de l'utilisateur
    func deleteAllDisponibilites() async throws {
        guard let url = URL(string: APIConfig.deleteAllDisponibilitesEndpoint) else {
            throw DisponibiliteError.networkError
        }
        
        let request = try createRequest(url: url, method: "DELETE")
        
        print("🔵 Delete All Disponibilites - URL: \(url.absoluteString)")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DisponibiliteError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw DisponibiliteError.notAuthenticated
            }
            throw DisponibiliteError.serverError(httpResponse.statusCode)
        }
        
        print("✅ Delete All Disponibilites - Success")
    }
    
    /// Récupère les disponibilités par jour
    func getDisponibilitesByDay(_ jour: String) async throws -> [Disponibilite] {
        guard let url = URL(string: APIConfig.getDisponibilitesByDayEndpoint(jour: jour)) else {
            throw DisponibiliteError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Disponibilites By Day - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DisponibiliteError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw DisponibiliteError.notAuthenticated
            }
            throw DisponibiliteError.serverError(httpResponse.statusCode)
        }
        
        let disponibilites = try makeJSONDecoder().decode([Disponibilite].self, from: data)
        return disponibilites
    }
    
    /// Récupère une disponibilité par ID
    func getDisponibiliteById(_ id: String) async throws -> Disponibilite {
        guard let url = URL(string: APIConfig.getDisponibiliteByIdEndpoint(id: id)) else {
            throw DisponibiliteError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Disponibilite By ID - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DisponibiliteError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw DisponibiliteError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw DisponibiliteError.notFound
            }
            throw DisponibiliteError.serverError(httpResponse.statusCode)
        }
        
        let disponibilite = try makeJSONDecoder().decode(Disponibilite.self, from: data)
        return disponibilite
    }
    
    /// Met à jour une disponibilité
    func updateDisponibilite(id: String, _ request: UpdateDisponibiliteRequest) async throws -> Disponibilite {
        guard let url = URL(string: APIConfig.updateDisponibiliteEndpoint(id: id)) else {
            throw DisponibiliteError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "PATCH")
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let requestData = try encoder.encode(request)
        httpRequest.httpBody = requestData
        
        // Log de la requête
        print("🔵 Update Disponibilite - URL: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("🔵 Update Disponibilite - Body: \(bodyString)")
        }
        print("🔵 Update Disponibilite - Headers: \(httpRequest.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DisponibiliteError.invalidResponse
        }
        
        print("🔵 Update Disponibilite - Status Code: \(httpResponse.statusCode)")
        
        // Log de la réponse en cas d'erreur
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Update Disponibilite - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Essayer de décoder le message d'erreur du serveur
            var errorMessage: String? = nil
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                errorMessage = json["message"] as? String ?? json["error"] as? String
            }
            
            if let message = errorMessage {
                print("🔴 Update Disponibilite - Erreur serveur: \(message)")
            }
            
            if httpResponse.statusCode == 401 {
                throw DisponibiliteError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw DisponibiliteError.notFound
            } else if httpResponse.statusCode == 400 {
                throw DisponibiliteError.invalidData
            }
            throw DisponibiliteError.serverError(httpResponse.statusCode)
        }
        
        let disponibilite = try makeJSONDecoder().decode(Disponibilite.self, from: data)
        print("✅ Update Disponibilite - Success: \(disponibilite.jour)")
        return disponibilite
    }
    
    /// Supprime une disponibilité
    func deleteDisponibilite(_ id: String) async throws {
        guard let url = URL(string: APIConfig.deleteDisponibiliteEndpoint(id: id)) else {
            throw DisponibiliteError.networkError
        }
        
        let request = try createRequest(url: url, method: "DELETE")
        
        print("🔵 Delete Disponibilite - URL: \(url.absoluteString)")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DisponibiliteError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw DisponibiliteError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw DisponibiliteError.notFound
            }
            throw DisponibiliteError.serverError(httpResponse.statusCode)
        }
        
        print("✅ Delete Disponibilite - Success")
    }
}

// MARK: - Disponibilite Errors
enum DisponibiliteError: LocalizedError {
    case invalidData
    case invalidResponse
    case serverError(Int)
    case networkError
    case notAuthenticated
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Données invalides"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .serverError(let code):
            return "Erreur serveur: \(code)"
        case .networkError:
            return "Erreur de connexion réseau"
        case .notAuthenticated:
            return "Vous devez être connecté pour effectuer cette action"
        case .notFound:
            return "Disponibilité introuvable"
        }
    }
}

