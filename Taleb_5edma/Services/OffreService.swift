//
//  OffreService.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import Foundation
import Combine

/// Service pour gérer les opérations CRUD des offres
/// Communique avec le backend NestJS pour créer, lire, mettre à jour et supprimer des offres
class OffreService: ObservableObject {
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
            throw OffreError.notAuthenticated
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    /// Crée une requête multipart/form-data pour l'upload de fichiers
    private func createMultipartRequest(url: URL, method: String, boundary: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let token = authToken else {
            throw OffreError.notAuthenticated
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    private func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple date formats
            let formatters: [DateFormatter] = [
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    return formatter
                }(),
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    return formatter
                }(),
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    return formatter
                }()
            ]
            
            // Also try ISO8601DateFormatter
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Try the custom formatters
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // If all else fails, throw an error
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return decoder
    }
    
    // MARK: - CRUD Methods
    
    /// Crée une nouvelle offre
    /// Note: Le backend attend multipart/form-data pour supporter les images
    func createOffre(_ request: CreateOffreRequest, imageFiles: [Data]? = nil) async throws -> Offre {
        guard let url = URL(string: APIConfig.createOffreEndpoint) else {
            throw OffreError.networkError
        }
        
        let boundary = UUID().uuidString
        var httpRequest = try createMultipartRequest(url: url, method: "POST", boundary: boundary)
        
        // Construire le body multipart/form-data
        var body = Data()
        
        // Ajouter les champs texte
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Champs requis
        appendField("title", request.title)
        appendField("description", request.description)
        appendField("company", request.company)
        
        // Location (encodé en JSON)
        let locationEncoder = JSONEncoder()
        if let locationData = try? locationEncoder.encode(request.location),
           let locationString = String(data: locationData, encoding: .utf8) {
            appendField("location", locationString)
        }
        
        // Champs optionnels - Tableaux encodés en JSON
        let jsonEncoder = JSONEncoder()
        if let tags = request.tags, !tags.isEmpty {
            if let tagsData = try? jsonEncoder.encode(tags),
               let tagsString = String(data: tagsData, encoding: .utf8) {
                appendField("tags", tagsString)
            }
        }
        if let exigences = request.exigences, !exigences.isEmpty {
            if let exigencesData = try? jsonEncoder.encode(exigences),
               let exigencesString = String(data: exigencesData, encoding: .utf8) {
                appendField("exigences", exigencesString)
            }
        }
        if let category = request.category {
            appendField("category", category)
        }
        if let salary = request.salary {
            appendField("salary", salary)
        }
        if let expiresAt = request.expiresAt {
            appendField("expiresAt", expiresAt)
        }
        if let jobType = request.jobType {
            appendField("jobType", jobType)
        }
        if let shift = request.shift {
            appendField("shift", shift)
        }
        if let isActive = request.isActive {
            appendField("isActive", String(isActive))
        }
        
        // Ajouter les images si présentes
        if let imageFiles = imageFiles {
            for (index, imageData) in imageFiles.enumerated() {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"imageFiles\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        // Fermer le boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        httpRequest.httpBody = body
        
        // Log de la requête
        print("🔵 Create Offre - URL: \(url.absoluteString)")
        print("🔵 Create Offre - Headers: \(httpRequest.allHTTPHeaderFields ?? [:])")
        print("🔵 Create Offre - Body size: \(body.count) bytes")
        
        // Log des données envoyées pour déboguer
        print("🔵 Create Offre - Title: \(request.title)")
        print("🔵 Create Offre - Company: \(request.company)")
        print("🔵 Create Offre - Tags: \(request.tags ?? [])")
        print("🔵 Create Offre - Exigences: \(request.exigences ?? [])")
        if let locationData = try? JSONEncoder().encode(request.location),
           let locationString = String(data: locationData, encoding: .utf8) {
            print("🔵 Create Offre - Location: \(locationString)")
        }
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OffreError.invalidResponse
        }
        
        print("🔵 Create Offre - Status Code: \(httpResponse.statusCode)")
        
        // Log de la réponse
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Create Offre - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Essayer de décoder le message d'erreur du serveur
            var errorMessage: String? = nil
            
            // Essayer plusieurs formats de réponse d'erreur
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                errorMessage = json["message"] as? String ?? json["error"] as? String
                
                // Vérifier s'il y a des erreurs de validation détaillées
                if let errors = json["errors"] as? [String: Any] {
                    let allErrors = errors.compactMap { key, value -> String? in
                        if let array = value as? [String] {
                            return "\(key): \(array.joined(separator: ", "))"
                        } else if let str = value as? String {
                            return "\(key): \(str)"
                        }
                        return nil
                    }
                    if !allErrors.isEmpty {
                        errorMessage = allErrors.joined(separator: "; ")
                    }
                } else if let errorArray = json["errors"] as? [String] {
                    errorMessage = errorArray.joined(separator: ", ")
                }
            } else if let errorString = String(data: data, encoding: .utf8) {
                errorMessage = errorString
            }
            
            if let message = errorMessage {
                print("🔴 Create Offre - Erreur serveur: \(message)")
                // Créer un type d'erreur avec message pour afficher le détail
                if httpResponse.statusCode == 400 {
                    throw OffreError.invalidDataWithMessage(message)
                }
            } else {
                print("🔴 Create Offre - Erreur serveur (pas de message)")
            }
            
            if httpResponse.statusCode == 401 {
                throw OffreError.notAuthenticated
            } else if httpResponse.statusCode == 400 {
                throw OffreError.invalidData
            }
            throw OffreError.serverError(httpResponse.statusCode)
        }
        
        let offre = try makeJSONDecoder().decode(Offre.self, from: data)
        print("✅ Create Offre - Success: \(offre.title), ID: \(offre.id)")
        return offre
    }
    
    /// Récupère toutes les offres actives
    func getAllOffres() async throws -> [Offre] {
        guard let url = URL(string: APIConfig.getAllOffresEndpoint) else {
            throw OffreError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get All Offres - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OffreError.invalidResponse
        }
        
        print("🔵 Get All Offres - Status Code: \(httpResponse.statusCode)")
        
        // Log the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Get All Offres - Raw Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw OffreError.notAuthenticated
            }
            throw OffreError.serverError(httpResponse.statusCode)
        }
        
        do {
            let offres = try makeJSONDecoder().decode([Offre].self, from: data)
            print("✅ Get All Offres - Success: \(offres.count) offres")
            return offres
        } catch {
            print("🔴 Get All Offres - Decoding Error: \(error)")
            print("🔴 Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Récupère une offre par ID
    func getOffreById(_ id: String) async throws -> Offre {
        guard let url = URL(string: APIConfig.getOffreByIdEndpoint(id: id)) else {
            throw OffreError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Offre By ID - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OffreError.invalidResponse
        }
        
        print("🔵 Get Offre By ID - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw OffreError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw OffreError.notFound
            }
            throw OffreError.serverError(httpResponse.statusCode)
        }
        
        let offre = try makeJSONDecoder().decode(Offre.self, from: data)
        return offre
    }
    
    /// Met à jour une offre
    func updateOffre(id: String, _ request: UpdateOffreRequest) async throws -> Offre {
        guard let url = URL(string: APIConfig.updateOffreEndpoint(id: id)) else {
            throw OffreError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "PATCH")
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let requestData = try encoder.encode(request)
        httpRequest.httpBody = requestData
        
        // Log de la requête
        print("🔵 Update Offre - URL: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("🔵 Update Offre - Body: \(bodyString)")
        }
        print("🔵 Update Offre - Headers: \(httpRequest.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OffreError.invalidResponse
        }
        
        print("🔵 Update Offre - Status Code: \(httpResponse.statusCode)")
        
        // Log de la réponse
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Update Offre - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Essayer de décoder le message d'erreur du serveur
            var errorMessage: String? = nil
            
            // Essayer plusieurs formats de réponse d'erreur
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                errorMessage = json["message"] as? String ?? json["error"] as? String
                
                // Vérifier s'il y a des erreurs de validation détaillées
                if let errors = json["errors"] as? [String: Any] {
                    let allErrors = errors.compactMap { key, value -> String? in
                        if let array = value as? [String] {
                            return "\(key): \(array.joined(separator: ", "))"
                        } else if let str = value as? String {
                            return "\(key): \(str)"
                        }
                        return nil
                    }
                    if !allErrors.isEmpty {
                        errorMessage = allErrors.joined(separator: "; ")
                    }
                } else if let errorArray = json["errors"] as? [[String: Any]] {
                    // Format: [{"field": "shift", "message": "..."}]
                    let allErrors = errorArray.compactMap { error -> String? in
                        if let field = error["field"] as? String,
                           let message = error["message"] as? String {
                            return "\(field): \(message)"
                        }
                        return nil
                    }
                    if !allErrors.isEmpty {
                        errorMessage = allErrors.joined(separator: "; ")
                    }
                } else if let errorArray = json["errors"] as? [String] {
                    errorMessage = errorArray.joined(separator: ", ")
                }
            } else if let errorString = String(data: data, encoding: .utf8) {
                errorMessage = errorString
            }
            
            if let message = errorMessage {
                print("🔴 Update Offre - Erreur serveur: \(message)")
                // Créer un type d'erreur avec message pour afficher le détail
                if httpResponse.statusCode == 400 {
                    throw OffreError.invalidDataWithMessage(message)
                }
            } else {
                print("🔴 Update Offre - Erreur serveur (pas de message)")
            }
            
            if httpResponse.statusCode == 401 {
                throw OffreError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw OffreError.notFound
            } else if httpResponse.statusCode == 400 {
                throw OffreError.invalidData
            }
            throw OffreError.serverError(httpResponse.statusCode)
        }
        
        let offre = try makeJSONDecoder().decode(Offre.self, from: data)
        print("✅ Update Offre - Success: \(offre.title)")
        return offre
    }
    
    /// Supprime une offre
    func deleteOffre(_ id: String) async throws {
        guard let url = URL(string: APIConfig.deleteOffreEndpoint(id: id)) else {
            throw OffreError.networkError
        }
        
        let request = try createRequest(url: url, method: "DELETE")
        
        print("🔵 Delete Offre - URL: \(url.absoluteString)")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OffreError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw OffreError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw OffreError.notFound
            }
            throw OffreError.serverError(httpResponse.statusCode)
        }
        
        print("✅ Delete Offre - Success")
    }
    
    /// Aime ou n'aime plus une offre
    func likeOffre(_ id: String) async throws -> Offre {
        guard let url = URL(string: APIConfig.likeOffreEndpoint(id: id)) else {
            throw OffreError.networkError
        }
        
        let request = try createRequest(url: url, method: "POST")
        
        print("🔵 Like Offre - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OffreError.invalidResponse
        }
        
        print("🔵 Like Offre - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw OffreError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw OffreError.notFound
            }
            throw OffreError.serverError(httpResponse.statusCode)
        }
        
        let offre = try makeJSONDecoder().decode(Offre.self, from: data)
        print("✅ Like Offre - Success")
        return offre
    }
    
    /// Récupère les offres de l'utilisateur actuel
    func getMyOffres() async throws -> [Offre] {
        guard let url = URL(string: APIConfig.getMyOffresEndpoint) else {
            throw OffreError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get My Offres - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OffreError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw OffreError.notAuthenticated
            }
            throw OffreError.serverError(httpResponse.statusCode)
        }
        
        let offres = try makeJSONDecoder().decode([Offre].self, from: data)
        return offres
    }
    
    /// Récupère les offres aimées par l'utilisateur actuel
    func getLikedOffres() async throws -> [Offre] {
        guard let url = URL(string: APIConfig.getLikedOffresEndpoint) else {
            throw OffreError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Liked Offres - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OffreError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw OffreError.notAuthenticated
            }
            throw OffreError.serverError(httpResponse.statusCode)
        }
        
        let offres = try makeJSONDecoder().decode([Offre].self, from: data)
        return offres
    }
    
    /// Recherche des offres par requête
    func searchOffres(query: String) async throws -> [Offre] {
        guard let url = URL(string: APIConfig.searchOffresEndpoint(query: query)) else {
            throw OffreError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Search Offres - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OffreError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw OffreError.notAuthenticated
            }
            throw OffreError.serverError(httpResponse.statusCode)
        }
        
        let offres = try makeJSONDecoder().decode([Offre].self, from: data)
        return offres
    }
    
    /// Récupère les offres populaires
    func getPopularOffres() async throws -> [Offre] {
        guard let url = URL(string: APIConfig.getPopularOffresEndpoint) else {
            throw OffreError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Popular Offres - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OffreError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw OffreError.notAuthenticated
            }
            throw OffreError.serverError(httpResponse.statusCode)
        }
        
        let offres = try makeJSONDecoder().decode([Offre].self, from: data)
        return offres
    }
}

// MARK: - Offre Errors
enum OffreError: LocalizedError {
    case invalidData
    case invalidDataWithMessage(String)
    case invalidResponse
    case serverError(Int)
    case networkError
    case notAuthenticated
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Données invalides"
        case .invalidDataWithMessage(let message):
            return message
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .serverError(let code):
            return "Erreur serveur: \(code)"
        case .networkError:
            return "Erreur de connexion réseau"
        case .notAuthenticated:
            return "Vous devez être connecté pour effectuer cette action"
        case .notFound:
            return "Offre introuvable"
        }
    }
}

