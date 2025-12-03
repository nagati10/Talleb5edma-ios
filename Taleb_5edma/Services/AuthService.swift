//
//  AuthService.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import Foundation
import Combine
import UIKit

/// Service responsable de l'authentification des utilisateurs
/// Communique avec le backend NestJS
class AuthService: ObservableObject {
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
        // Configuration pour éviter les avertissements de socket sur iOS
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        return URLSession(configuration: configuration)
    }()
    
    /// Token d'authentification stocké localement
    /// 
    /// **Persistance automatique :**
    /// - Lorsqu'un token est défini, il est automatiquement sauvegardé dans UserDefaults
    /// - Lorsqu'un token est supprimé (nil), il est retiré de UserDefaults
    /// - Cela permet de conserver la session entre les lancements de l'application
    /// - Le token est chargé automatiquement au démarrage dans l'initializer
    @Published var authToken: String? {
        didSet {
            // Sauvegarder le token dans UserDefaults pour la persistance entre les sessions
            if let token = authToken {
                UserDefaults.standard.set(token, forKey: "authToken")
                print("💾 Token sauvegardé dans UserDefaults")
            } else {
                // Supprimer le token si l'utilisateur se déconnecte
                UserDefaults.standard.removeObject(forKey: "authToken")
                print("🗑️ Token supprimé de UserDefaults")
            }
        }
    }
    
    /// Utilisateur actuellement connecté
    /// 
    /// **Persistance automatique :**
    /// - Lorsqu'un utilisateur est défini (après connexion), il est automatiquement sauvegardé dans UserDefaults
    /// - L'utilisateur est encodé en JSON avant d'être stocké
    /// - Lorsqu'un utilisateur est supprimé (nil), il est retiré de UserDefaults
    /// - Cela permet de restaurer rapidement la session sans appeler l'API à chaque démarrage
    /// - L'utilisateur est chargé automatiquement au démarrage dans l'initializer
    @Published var currentUser: User? {
        didSet {
            // Sauvegarder l'utilisateur dans UserDefaults pour la persistance entre les sessions
            if let user = currentUser {
                // Encoder l'utilisateur en JSON pour le stocker dans UserDefaults
                if let encoded = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                    print("💾 Utilisateur sauvegardé dans UserDefaults: \(user.email)")
                } else {
                    print("⚠️ Erreur lors de l'encodage de l'utilisateur")
                }
            } else {
                // Supprimer l'utilisateur si l'utilisateur se déconnecte
                UserDefaults.standard.removeObject(forKey: "currentUser")
                print("🗑️ Utilisateur supprimé de UserDefaults")
            }
        }
    }
    
    // MARK: - Initialization
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    /// Initialise le service d'authentification
    /// 
    /// **Restauration automatique de la session :**
    /// 1. Charge le token d'authentification depuis UserDefaults (s'il existe)
    /// 2. Charge les informations de l'utilisateur depuis UserDefaults (s'il existe)
    /// 3. Utilise le même décodeur JSON que pour les réponses API pour garantir la cohérence
    /// 
    /// **Note :** Cette restauration initiale permet d'afficher rapidement l'interface utilisateur
    /// sans attendre un appel réseau. La méthode `restoreSession()` sera appelée ensuite
    /// pour vérifier la validité du token et mettre à jour les données si nécessaire.
    init() {
        // Étape 1 : Charger le token sauvegardé depuis UserDefaults
        // Si un token existe, cela signifie que l'utilisateur s'est connecté précédemment
        self.authToken = UserDefaults.standard.string(forKey: "authToken")
        
        // Étape 2 : Charger l'utilisateur sauvegardé depuis UserDefaults
        // Utiliser le même décodeur JSON que pour les réponses API pour garantir la cohérence
        // (notamment pour le formatage des dates ISO8601)
        if let userData = UserDefaults.standard.data(forKey: "currentUser") {
            let decoder = makeJSONDecoder()
            do {
                let user = try decoder.decode(User.self, from: userData)
                self.currentUser = user
                print("✅ Session restaurée - Utilisateur chargé depuis UserDefaults: \(user.email)")
            } catch {
                print("⚠️ Impossible de décoder l'utilisateur depuis UserDefaults: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ Aucune session sauvegardée trouvée")
        }
        
        // Afficher la configuration pour le débogage
        APIConfig.printConfiguration()
    }
    
    // MARK: - Helper Methods
    
    /// Crée une requête avec les headers appropriés (incluant le token si disponible)
    private func createRequest(url: URL, method: String, requiresAuth: Bool = false) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Ajouter le token d'authentification si requis et disponible
        if requiresAuth {
            guard let token = authToken else {
                throw AuthError.notAuthenticated
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = AuthService.iso8601Formatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Format de date invalide: \(dateString)"
            )
        }
        return decoder
    }
    
    // MARK: - Authentication Methods
    
    /// Connecte un utilisateur avec email et mot de passe
    func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: APIConfig.loginEndpoint) else {
            throw AuthError.networkError
        }
        
        // Log de l'URL pour le débogage
        print("🔵 Login - URL: \(url.absoluteString)")
        
        var request = try createRequest(url: url, method: "POST", requiresAuth: false)
        let loginRequest = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(loginRequest)
        
        // Log du body de la requête
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🔵 Login - Body: \(bodyString)")
        }
        
        // Log des headers
        print("🔵 Login - Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Login - Réponse invalide (pas de HTTPURLResponse)")
                throw AuthError.invalidResponse
            }
            
            // Log de la réponse
            print("🔵 Login - Status Code: \(httpResponse.statusCode)")
            print("🔵 Login - Response Headers: \(httpResponse.allHeaderFields)")
            
            if let responseDataString = String(data: data, encoding: .utf8) {
                print("🔵 Login - Response Body: \(responseDataString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Log de l'erreur pour le débogage
                if let responseData = String(data: data, encoding: .utf8) {
                    print("❌ Erreur Login - Status: \(httpResponse.statusCode)")
                    print("❌ Erreur Login - URL: \(url.absoluteString)")
                    print("❌ Erreur Login - Réponse: \(responseData)")
                }
                
                if httpResponse.statusCode == 401 {
                    throw AuthError.invalidCredentials
                } else if httpResponse.statusCode == 404 {
                    throw AuthError.endpointNotFound(url.absoluteString)
                }
                throw AuthError.serverError(httpResponse.statusCode)
            }
            
            // Vérifier si la réponse contient une erreur (même avec un status code 200-299)
            // Le backend peut renvoyer {"status":"error","message":"..."} avec un code 201
            if let responseString = String(data: data, encoding: .utf8),
               responseString.contains("\"status\":\"error\"") {
                // Essayer de décoder le message d'erreur
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorData["message"] {
                    print("❌ Login - Erreur du serveur: \(errorMessage)")
                    if errorMessage.lowercased().contains("invalid") || errorMessage.lowercased().contains("incorrect") {
                        throw AuthError.invalidCredentials
                    }
                }
                throw AuthError.invalidCredentials
            }
            
            let authResponse = try makeJSONDecoder().decode(AuthResponse.self, from: data)
            self.authToken = authResponse.token
            self.currentUser = authResponse.user
            
            print("✅ Login - Succès! Token reçu: \(authResponse.token.prefix(20))...")
            
            return authResponse
        } catch let error as DecodingError {
            print("❌ Login - Erreur de décodage JSON: \(error)")
            print("❌ Login - Détails: \(error.localizedDescription)")
            throw AuthError.invalidResponse
        } catch let urlError as URLError {
            print("❌ Login - Erreur réseau: \(urlError.localizedDescription)")
            print("❌ Login - Code d'erreur: \(urlError.code.rawValue)")
            throw AuthError.networkError
        } catch {
            print("❌ Login - Erreur inconnue: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Inscrit un nouvel utilisateur
    func signUp(_ request: SignUpRequest) async throws -> AuthResponse {
        guard let url = URL(string: APIConfig.signUpEndpoint) else {
            throw AuthError.networkError
        }
        
        // Log de l'URL pour le débogage
        print("🔵 SignUp - URL: \(url.absoluteString)")
        
        var httpRequest = try createRequest(url: url, method: "POST", requiresAuth: false)
        httpRequest.httpBody = try JSONEncoder().encode(request)
        
        // Log du body de la requête
        if let bodyData = httpRequest.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🔵 SignUp - Body: \(bodyString)")
        }
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Log de l'erreur pour le débogage
            if let responseData = try? String(data: data, encoding: .utf8) {
                print("❌ Erreur SignUp - Status: \(httpResponse.statusCode)")
                print("URL: \(url.absoluteString)")
                print("Réponse: \(responseData)")
            }
            
            if httpResponse.statusCode == 409 {
                throw AuthError.userAlreadyExists
            } else if httpResponse.statusCode == 404 {
                throw AuthError.endpointNotFound(url.absoluteString)
            }
            throw AuthError.serverError(httpResponse.statusCode)
        }
        
        // Vérifier si la réponse contient une erreur (même avec un status code 200-299)
        if let responseString = String(data: data, encoding: .utf8),
           responseString.contains("\"status\":\"error\"") {
            // Essayer de décoder le message d'erreur
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["message"] {
                print("❌ SignUp - Erreur du serveur: \(errorMessage)")
                if errorMessage.lowercased().contains("already exists") || errorMessage.lowercased().contains("déjà") {
                    throw AuthError.userAlreadyExists
                }
            }
            throw AuthError.serverError(httpResponse.statusCode)
        }
        
        let authResponse = try makeJSONDecoder().decode(AuthResponse.self, from: data)
        self.authToken = authResponse.token
        self.currentUser = authResponse.user
        
        return authResponse
    }
    
    /// Connecte ou inscrit un utilisateur avec Google
    /// - Parameter idToken: Le token ID Google obtenu après la connexion Google
    /// - Returns: La réponse d'authentification avec le token et l'utilisateur
    func signInWithGoogle(idToken: String) async throws -> AuthResponse {
        guard let url = URL(string: APIConfig.googleSignInEndpoint) else {
            throw AuthError.networkError
        }
        
        // Log de l'URL pour le débogage
        print("🔵 Google Sign-In - URL: \(url.absoluteString)")
        
        var request = try createRequest(url: url, method: "POST", requiresAuth: false)
        
        // Le backend attend probablement un objet avec le token Google
        let googleRequest = GoogleSignInRequest(idToken: idToken)
        request.httpBody = try JSONEncoder().encode(googleRequest)
        
        // Log du body de la requête
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🔵 Google Sign-In - Body: \(bodyString)")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        // Log de la réponse
        print("🔵 Google Sign-In - Status Code: \(httpResponse.statusCode)")
        
        if let responseDataString = String(data: data, encoding: .utf8) {
            print("🔵 Google Sign-In - Response Body: \(responseDataString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Log de l'erreur pour le débogage
            if let responseData = String(data: data, encoding: .utf8) {
                print("❌ Erreur Google Sign-In - Status: \(httpResponse.statusCode)")
                print("❌ Erreur Google Sign-In - URL: \(url.absoluteString)")
                print("❌ Erreur Google Sign-In - Réponse: \(responseData)")
            }
            
            if httpResponse.statusCode == 401 {
                throw AuthError.invalidCredentials
            } else if httpResponse.statusCode == 404 {
                throw AuthError.endpointNotFound(url.absoluteString)
            }
            throw AuthError.serverError(httpResponse.statusCode)
        }
        
        // Vérifier si la réponse contient une erreur
        if let responseString = String(data: data, encoding: .utf8),
           responseString.contains("\"status\":\"error\"") {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["message"] {
                print("❌ Google Sign-In - Erreur du serveur: \(errorMessage)")
            }
            throw AuthError.serverError(httpResponse.statusCode)
        }
        
        let authResponse = try makeJSONDecoder().decode(AuthResponse.self, from: data)
        self.authToken = authResponse.token
        self.currentUser = authResponse.user
        
        print("✅ Google Sign-In - Succès! Token reçu: \(authResponse.token.prefix(20))...")
        
        return authResponse
    }
    
    // MARK: - User Profile Methods
    
    /// Récupère le profil de l'utilisateur actuellement connecté
    func getUserProfile() async throws -> User {
        guard let url = URL(string: APIConfig.getUserProfileEndpoint) else {
            throw AuthError.networkError
        }
        
        let request = try createRequest(url: url, method: "GET", requiresAuth: true)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw AuthError.notAuthenticated
            }
            throw AuthError.serverError(httpResponse.statusCode)
        }
        
        let user = try makeJSONDecoder().decode(User.self, from: data)
        self.currentUser = user
        return user
    }
    
    /// Met à jour le profil de l'utilisateur actuellement connecté
    // Dans AuthService.swift - méthode updateUserProfile
    // Dans AuthService.swift - REMPLACEZ la méthode updateUserProfile par ceci :
    /// Met à jour le profil de l'utilisateur actuellement connecté
    func updateUserProfile(_ request: UpdateUserRequest) async throws -> User {
        guard let url = URL(string: APIConfig.updateUserProfileEndpoint) else {
            throw AuthError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "PATCH", requiresAuth: true)
        
        // Encoder la requête
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        httpRequest.httpBody = try encoder.encode(request)
        
        print("🔵 Update User Profile - URL: \(url.absoluteString)")
        
        // Log du body de la requête
        if let bodyData = httpRequest.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🔵 Update User Profile - Body: \(bodyString)")
        }
        
        // Log des headers
        print("🔵 Update User Profile - Headers: \(httpRequest.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await session.data(for: httpRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Update User Profile - Réponse invalide")
                throw AuthError.invalidResponse
            }
            
            print("🔵 Update User Profile - Status Code: \(httpResponse.statusCode)")
            
            // Afficher la réponse brute pour debugger
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔵 Update User Profile - Raw Response: \(responseString)")
            }
            
            // Vérifier le status code AVANT de décoder
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw AuthError.notAuthenticated
                }
                throw AuthError.serverError(httpResponse.statusCode)
            }
            
            
            // SOLUTION 2: Essayer de décoder directement en User
            let decoder = makeJSONDecoder()
            
            do {
                let user = try decoder.decode(User.self, from: data)
                self.currentUser = user
                print("✅ Update User Profile - Direct User Success")
                return user
            } catch let decodingError {
                print("⚠️ Update User Profile - User decoding failed: \(decodingError)")
                
                // SOLUTION 3: Essayer de décoder avec UpdateUserResponse
                do {
                    let response = try decoder.decode(UpdateUserResponse.self, from: data)
                    if let user = response.user {
                        self.currentUser = user
                        print("✅ Update User Profile - Wrapped User Success")
                        return user
                    }
                } catch {
                    print("⚠️ Update User Profile - UpdateUserResponse decoding failed: \(error)")
                }
                
                
                
                // SOLUTION 5: En dernier recours, recharger le profil
                // car le status code était 200-299 (succès)
                print("⚠️ Update User Profile - Unknown response format, reloading profile as fallback")
                return try await getUserProfile()
            }
        } catch let error as AuthError {
            // Propager les erreurs d'authentification
            print("❌ Update User Profile - Auth Error: \(error)")
            throw error
        } catch let urlError as URLError {
            print("❌ Update User Profile - Network Error: \(urlError.localizedDescription)")
            throw AuthError.networkError
        } catch {
            print("❌ Update User Profile - Unknown Error: \(error.localizedDescription)")
            throw AuthError.invalidResponse
        }
    }
    /// Réinitialise le mot de passe de l'utilisateur
    func resetPassword(_ request: ResetPasswordRequest, requiresAuthentication: Bool = false) async throws {
        guard let url = URL(string: APIConfig.resetPasswordEndpoint) else {
            throw AuthError.networkError
        }
        
        var httpRequest = try createRequest(url: url, method: "PATCH", requiresAuth: requiresAuthentication)
        httpRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw AuthError.userNotFound
            } else if httpResponse.statusCode == 401 {
                throw AuthError.notAuthenticated
            }
            throw AuthError.serverError(httpResponse.statusCode)
        }
        
        // Log pour debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔐 Reset Password - Response: \(responseString)")
        }
    }
    
    /// Upload l'image de profil de l'utilisateur
    func uploadProfileImage(_ image: UIImage) async throws -> User {
        guard let url = URL(string: APIConfig.updateUserImageEndpoint) else {
            throw AuthError.networkError
        }
        
        guard let token = authToken else {
            throw AuthError.notAuthenticated
        }
        
        // Créer la requête multipart/form-data
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Créer le boundary pour multipart/form-data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Convertir l'image en Data (JPEG avec compression)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AuthError.invalidResponse
        }
        
        // Créer le body multipart
        var body = Data()
        
        // Ajouter l'image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("🖼️ Upload Profile Image - URL: \(url.absoluteString)")
        print("🖼️ Upload Profile Image - Image size: \(imageData.count) bytes")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            print("🖼️ Upload Profile Image - Status Code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🖼️ Upload Profile Image - Response: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw AuthError.notAuthenticated
                }
                throw AuthError.serverError(httpResponse.statusCode)
            }
            
            // Décoder la réponse en User
            let decoder = makeJSONDecoder()
            let user = try decoder.decode(User.self, from: data)
            
            // Mettre à jour l'utilisateur courant
            self.currentUser = user
            
            print("✅ Upload Profile Image - Success")
            return user
            
        } catch let error as AuthError {
            throw error
        } catch let urlError as URLError {
            print("❌ Upload Profile Image - Network Error: \(urlError.localizedDescription)")
            throw AuthError.networkError
        } catch {
            print("❌ Upload Profile Image - Error: \(error.localizedDescription)")
            throw AuthError.invalidResponse
        }
    }
    
    /// Vérifie si le token JWT est expiré en décodant le payload
    /// - Parameter token: Le token JWT à vérifier
    /// - Returns: True si le token est expiré, false sinon
    private func isTokenExpired(_ token: String) -> Bool {
        // Un JWT est composé de 3 parties séparées par des points : header.payload.signature
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            return true // Token invalide
        }
        
        // Décoder le payload (partie 2)
        guard let payloadData = base64URLDecode(parts[1]),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            return true // Impossible de décoder ou pas de champ exp
        }
        
        // Vérifier si le token est expiré (avec une marge de 60 secondes)
        let expirationDate = Date(timeIntervalSince1970: exp)
        let now = Date()
        let isExpired = expirationDate < now.addingTimeInterval(60) // Marge de 60 secondes
        
        if isExpired {
            print("⚠️ Token expiré - Expiration: \(expirationDate), Maintenant: \(now)")
        }
        
        return isExpired
    }
    
    /// Décode une chaîne base64 URL-safe
    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Ajouter le padding si nécessaire
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        
        return Data(base64Encoded: base64)
    }
    
    /// Restaure la session utilisateur au démarrage de l'application
    /// 
    /// **Fonctionnement :**
    /// Cette méthode est appelée automatiquement au démarrage de l'application pour vérifier
    /// et restaurer la session de l'utilisateur. Elle gère plusieurs scénarios :
    /// 
    /// **Scénario 1 : Token présent mais utilisateur manquant**
    /// - Si un token existe mais que l'utilisateur n'a pas pu être chargé depuis UserDefaults
    /// - Appelle l'API pour récupérer le profil utilisateur avec le token
    /// - Met à jour `currentUser` avec les données fraîches du serveur
    /// 
    /// **Scénario 2 : Token et utilisateur présents**
    /// - Vérifie d'abord si le token est expiré localement
    /// - Si le token est valide, vérifie sa validité avec le serveur
    /// - Si le token est expiré ou invalide, nettoie la session
    /// 
    /// **Scénario 3 : Token invalide ou expiré**
    /// - Si l'API retourne une erreur d'authentification (401)
    /// - Nettoie automatiquement la session (token + utilisateur)
    /// - L'utilisateur devra se reconnecter
    /// 
    /// **Avantages :**
    /// - Permet de récupérer les données utilisateur à jour depuis le serveur
    /// - Vérifie la validité du token sans bloquer l'interface utilisateur
    /// - Nettoie automatiquement les sessions invalides
    /// - Détecte les tokens expirés avant de faire des requêtes API
    func restoreSession() async {
        // Cas 1 : Token présent mais utilisateur manquant
        // Cela peut arriver si UserDefaults a été vidé ou si le décodage a échoué
        if authToken != nil, currentUser == nil {
            do {
                // Vérifier d'abord si le token est expiré
                if let token = authToken, isTokenExpired(token) {
                    print("🔒 Token expiré détecté - Nettoyage de la session")
                    logout()
                    return
                }
                
                print("🔄 Restauration de session - Récupération du profil utilisateur depuis le serveur...")
                // Appeler l'API pour récupérer le profil avec le token sauvegardé
                let user = try await getUserProfile()
                // currentUser sera automatiquement sauvegardé grâce au didSet
                print("✅ Session restaurée avec succès pour l'utilisateur: \(user.email)")
            } catch {
                print("⚠️ Impossible de restaurer la session: \(error.localizedDescription)")
                // Si le token est invalide ou expiré, nettoyer la session
                if case AuthError.notAuthenticated = error {
                    print("🔒 Token invalide - Nettoyage de la session")
                    logout()
                }
            }
        } else if authToken != nil && currentUser != nil {
            // Cas 2 : Token et utilisateur présents - Vérifier la validité du token
            if let token = authToken {
                if isTokenExpired(token) {
                    print("🔒 Token expiré détecté lors de la restauration - Nettoyage de la session")
                    logout()
                    return
                }
                
                // Vérifier la validité du token avec le serveur (en arrière-plan)
                Task {
                    do {
                        _ = try await getUserProfile()
                        print("✅ Token vérifié avec succès - Session valide")
                    } catch {
                        print("⚠️ Token invalide lors de la vérification: \(error.localizedDescription)")
                        if case AuthError.notAuthenticated = error {
                            await MainActor.run {
                                print("🔒 Token invalide - Nettoyage de la session")
                                self.logout()
                            }
                        }
                    }
                }
            }
            print("✅ Session restaurée depuis UserDefaults - Vérification en cours...")
        } else {
            // Cas 3 : Aucun token - L'utilisateur n'est pas connecté
            print("ℹ️ Aucune session à restaurer - L'utilisateur doit se connecter")
        }
    }
    
    /// Déconnecte l'utilisateur et nettoie la session
    /// 
    /// **Actions effectuées :**
    /// - Supprime le token d'authentification (déclenche la suppression dans UserDefaults via didSet)
    /// - Supprime les informations utilisateur (déclenche la suppression dans UserDefaults via didSet)
    /// - Après cette méthode, `isAuthenticated` retournera `false`
    /// - L'utilisateur sera redirigé vers l'écran de connexion
    func logout() {
        print("🚪 Déconnexion de l'utilisateur...")
        // Réinitialiser le token (déclenchera automatiquement la suppression dans UserDefaults)
        self.authToken = nil
        // Réinitialiser l'utilisateur (déclenchera automatiquement la suppression dans UserDefaults)
        self.currentUser = nil
        print("✅ Déconnexion terminée - Session nettoyée")
    }
    
    /// Vérifie si l'utilisateur est connecté
    /// 
    /// **Critères d'authentification :**
    /// L'utilisateur est considéré comme authentifié uniquement si :
    /// - Un token d'authentification est présent (`authToken != nil`)
    /// - Les informations utilisateur sont présentes (`currentUser != nil`)
    /// 
    /// **Utilisation :**
    /// Cette propriété est utilisée dans `Taleb_5edmaApp` pour déterminer quel écran afficher :
    /// - Si `true` : Affiche `ContentView` (Dashboard ou Onboarding)
    /// - Si `false` : Affiche `AuthCoordinatorView` (écran de connexion)
    var isAuthenticated: Bool {
        // L'utilisateur est considéré comme authentifié uniquement si le token et le profil sont présents
        let authenticated = authToken != nil && currentUser != nil
        return authenticated
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidResponse
    case serverError(Int)
    case userAlreadyExists
    case invalidVerificationCode
    case networkError
    case notAuthenticated
    case userNotFound
    case endpointNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email ou mot de passe incorrect"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .serverError(let code):
            return "Erreur serveur: \(code)"
        case .userAlreadyExists:
            return "Cet utilisateur existe déjà"
        case .invalidVerificationCode:
            return "Code de vérification invalide"
        case .networkError:
            return "Erreur de connexion réseau"
        case .notAuthenticated:
            return "Vous devez être connecté pour effectuer cette action"
        case .userNotFound:
            return "Utilisateur introuvable"
        case .endpointNotFound(let url):
            return "Endpoint introuvable (404): \(url)\n\nVérifiez que:\n1. Le backend est démarré sur le port 3005\n2. L'URL de base est correcte dans APIConfig.swift\n3. Le préfixe /api est correct"
        }
    }
}
