//
//  StudentPreferencesService.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation
import Combine

/// Service pour gérer les opérations CRUD des préférences étudiant
/// Communique avec le backend NestJS pour créer, lire, mettre à jour et supprimer les préférences
class StudentPreferencesService: ObservableObject {
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
    /// Note: Pour une meilleure synchronisation, le token devrait être passé depuis AuthService
    private var authToken: String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    /// Récupère le token depuis AuthService si disponible
    /// Cette méthode permet de synchroniser le token avec AuthService
    private func getAuthToken() -> String? {
        // Essayer d'abord depuis UserDefaults (compatibilité)
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            return token
        }
        return nil
    }
    
    // MARK: - Helper Methods
    
    /// Crée une requête avec les headers appropriés
    /// - Parameter token: Token d'authentification optionnel. Si fourni, sera utilisé au lieu de celui dans UserDefaults
    private func createRequest(url: URL, method: String, token: String? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Utiliser le token fourni en paramètre, sinon celui de UserDefaults
        let authToken = token ?? getAuthToken()
        
        guard let token = authToken else {
            throw StudentPreferencesError.notAuthenticated
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
    
    /// Crée ou complète les préférences étudiant
    /// - Parameter preferences: Les préférences à créer
    /// - Parameter currentStep: L'étape actuelle du formulaire (par défaut: 5)
    /// - Parameter isCompleted: Si le formulaire est complété (par défaut: false)
    /// - Parameter token: Token d'authentification optionnel. Si fourni, sera utilisé au lieu de celui dans UserDefaults
    /// - Returns: Les préférences créées
    func createStudentPreferences(_ preferences: UserPreferences, currentStep: Int = 5, isCompleted: Bool = false, token: String? = nil) async throws -> StudentPreferencesResponse {
        guard let url = URL(string: APIConfig.createStudentPreferencesEndpoint) else {
            throw StudentPreferencesError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "POST", token: token)
        
        // Créer la requête à partir des préférences (avec validation)
        let request: CreateStudentPreferencesRequest
        do {
            request = try CreateStudentPreferencesRequest(from: preferences, currentStep: currentStep, isCompleted: isCompleted)
        } catch let validationError as StudentPreferencesValidationError {
            print("❌ Validation Error: \(validationError.localizedDescription)")
            throw StudentPreferencesError.invalidDataWithMessage(validationError.localizedDescription)
        } catch {
            print("❌ Unexpected Error: \(error.localizedDescription)")
            throw StudentPreferencesError.invalidDataWithMessage("Erreur de validation: \(error.localizedDescription)")
        }
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let requestData = try encoder.encode(request)
        httpRequest.httpBody = requestData
        
        print("🔵 Create Student Preferences - URL: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("🔵 Create Student Preferences - Body: \(bodyString)")
        }
        print("🔵 Create Student Preferences - Headers: \(httpRequest.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StudentPreferencesError.invalidResponse
        }
        
        print("🔵 Create Student Preferences - Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Create Student Preferences - Response: \(responseString)")
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
                print("🔴 Create Student Preferences - Erreur serveur: \(message)")
                if httpResponse.statusCode == 400 {
                    throw StudentPreferencesError.invalidDataWithMessage(message)
                }
            }
            
            if httpResponse.statusCode == 401 {
                print("🔒 Token expiré ou invalide - L'utilisateur doit se reconnecter")
                // Notifier que le token est expiré (sera géré par le ViewModel)
                throw StudentPreferencesError.notAuthenticated
            }
            throw StudentPreferencesError.serverError(httpResponse.statusCode)
        }
        
        let preferencesResponse = try makeJSONDecoder().decode(StudentPreferencesResponse.self, from: data)
        print("✅ Create Student Preferences - Succès")
        return preferencesResponse
    }
    
    /// Récupère les préférences de l'utilisateur connecté
    /// - Returns: Les préférences de l'utilisateur
    func getMyStudentPreferences() async throws -> StudentPreferencesResponse {
        guard let url = URL(string: APIConfig.getMyStudentPreferencesEndpoint) else {
            throw StudentPreferencesError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get My Student Preferences - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StudentPreferencesError.invalidResponse
        }
        
        print("🔵 Get My Student Preferences - Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Get My Student Preferences - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                print("🔒 Token expiré ou invalide lors de la récupération des préférences")
                throw StudentPreferencesError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw StudentPreferencesError.notFound
            }
            throw StudentPreferencesError.serverError(httpResponse.statusCode)
        }
        
        let preferencesResponse = try makeJSONDecoder().decode(StudentPreferencesResponse.self, from: data)
        print("✅ Get My Student Preferences - Succès")
        return preferencesResponse
    }
    
    /// Met à jour les préférences de l'utilisateur connecté
    /// - Parameter preferences: Les préférences à mettre à jour
    /// - Parameter currentStep: L'étape actuelle (optionnel)
    /// - Parameter isCompleted: Si le formulaire est complété (optionnel)
    /// - Returns: Les préférences mises à jour
    func updateMyStudentPreferences(_ preferences: UserPreferences, currentStep: Int? = nil, isCompleted: Bool? = nil) async throws -> StudentPreferencesResponse {
        guard let url = URL(string: APIConfig.updateMyStudentPreferencesEndpoint) else {
            throw StudentPreferencesError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "PATCH")
        
        // Créer la requête de mise à jour
        let request = UpdateStudentPreferencesRequest(from: preferences, currentStep: currentStep, isCompleted: isCompleted)
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let requestData = try encoder.encode(request)
        httpRequest.httpBody = requestData
        
        print("🔵 Update My Student Preferences - URL: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("🔵 Update My Student Preferences - Body: \(bodyString)")
        }
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StudentPreferencesError.invalidResponse
        }
        
        print("🔵 Update My Student Preferences - Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Update My Student Preferences - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            var errorMessage: String? = nil
            
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                errorMessage = errorResponse["message"] ?? errorResponse["error"]
            }
            
            if let message = errorMessage {
                print("🔴 Update My Student Preferences - Erreur serveur: \(message)")
                if httpResponse.statusCode == 400 {
                    throw StudentPreferencesError.invalidDataWithMessage(message)
                }
            }
            
            if httpResponse.statusCode == 401 {
                throw StudentPreferencesError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw StudentPreferencesError.notFound
            }
            throw StudentPreferencesError.serverError(httpResponse.statusCode)
        }
        
        let preferencesResponse = try makeJSONDecoder().decode(StudentPreferencesResponse.self, from: data)
        print("✅ Update My Student Preferences - Succès")
        return preferencesResponse
    }
    
    /// Supprime les préférences de l'utilisateur connecté
    func deleteMyStudentPreferences() async throws {
        guard let url = URL(string: APIConfig.deleteMyStudentPreferencesEndpoint) else {
            throw StudentPreferencesError.networkError
        }
        
        let request = try createRequest(url: url, method: "DELETE")
        
        print("🔵 Delete My Student Preferences - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StudentPreferencesError.invalidResponse
        }
        
        print("🔵 Delete My Student Preferences - Status Code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                print("🔒 Token expiré ou invalide lors de la récupération des préférences")
                throw StudentPreferencesError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw StudentPreferencesError.notFound
            }
            throw StudentPreferencesError.serverError(httpResponse.statusCode)
        }
        
        print("✅ Delete My Student Preferences - Succès")
    }
    
    /// Met à jour une étape spécifique du formulaire
    /// - Parameter step: Le numéro de l'étape (1-5)
    /// - Parameter data: Les données de l'étape sous forme de dictionnaire
    /// - Parameter markCompleted: Si true, marque le formulaire comme complété
    /// - Returns: Les préférences mises à jour
    func updateStep(step: Int, data: [String: String], markCompleted: Bool? = nil) async throws -> StudentPreferencesResponse {
        guard let url = URL(string: APIConfig.updateStudentPreferencesStepEndpoint(step: step)) else {
            throw StudentPreferencesError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "PATCH")
        
        // Créer la requête de mise à jour d'étape
        let request = UpdateStepRequest(step: step, data: data, markCompleted: markCompleted)
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let requestData = try encoder.encode(request)
        httpRequest.httpBody = requestData
        
        print("🔵 Update Step - URL: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("🔵 Update Step - Body: \(bodyString)")
        }
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StudentPreferencesError.invalidResponse
        }
        
        print("🔵 Update Step - Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Update Step - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            var errorMessage: String? = nil
            
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                errorMessage = errorResponse["message"] ?? errorResponse["error"]
            }
            
            if let message = errorMessage {
                print("🔴 Update Step - Erreur serveur: \(message)")
                if httpResponse.statusCode == 400 {
                    throw StudentPreferencesError.invalidDataWithMessage(message)
                }
            }
            
            if httpResponse.statusCode == 401 {
                throw StudentPreferencesError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw StudentPreferencesError.notFound
            }
            throw StudentPreferencesError.serverError(httpResponse.statusCode)
        }
        
        let preferencesResponse = try makeJSONDecoder().decode(StudentPreferencesResponse.self, from: data)
        print("✅ Update Step - Succès")
        return preferencesResponse
    }
    
    /// Obtient la progression du formulaire
    /// - Returns: La progression du formulaire
    func getProgress() async throws -> StudentPreferencesProgressResponse {
        guard let url = URL(string: APIConfig.getStudentPreferencesProgressEndpoint) else {
            throw StudentPreferencesError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        print("🔵 Get Progress - URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StudentPreferencesError.invalidResponse
        }
        
        print("🔵 Get Progress - Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Get Progress - Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                print("🔒 Token expiré ou invalide lors de la récupération des préférences")
                throw StudentPreferencesError.notAuthenticated
            } else if httpResponse.statusCode == 404 {
                throw StudentPreferencesError.notFound
            }
            throw StudentPreferencesError.serverError(httpResponse.statusCode)
        }
        
        let progressResponse = try makeJSONDecoder().decode(StudentPreferencesProgressResponse.self, from: data)
        print("✅ Get Progress - Succès")
        return progressResponse
    }
}

// MARK: - Student Preferences Errors

enum StudentPreferencesError: LocalizedError {
    case invalidCredentials
    case invalidResponse
    case serverError(Int)
    case networkError
    case notAuthenticated
    case notFound
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
            return "Préférences introuvables"
        case .invalidDataWithMessage(let message):
            return "Données invalides: \(message)"
        }
    }
}

// MARK: - Validation Errors

enum StudentPreferencesValidationError: LocalizedError {
    case missingEducationLevel
    case missingStudyField
    case missingSearchType
    case missingMotivation
    case missingSoftSkills
    
    var errorDescription: String? {
        switch self {
        case .missingEducationLevel:
            return "Le niveau d'étude est requis"
        case .missingStudyField:
            return "Le domaine d'étude est requis"
        case .missingSearchType:
            return "Le type de recherche est requis"
        case .missingMotivation:
            return "La motivation principale est requise"
        case .missingSoftSkills:
            return "Au moins une compétence douce est requise"
        }
    }
}

