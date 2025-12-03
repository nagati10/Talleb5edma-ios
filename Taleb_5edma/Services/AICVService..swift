//  AICVService.swift
//  Taleb_5edma

import UIKit

final class AICVService {
    static let shared = AICVService()
    private init() {}

    // MARK: - 1) Analyse CV (image → multipart → /cv-ai/analyze-image)

    func analyzeCv(image: UIImage, token: String?) async throws -> CvStructuredResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(
                domain: "AICVService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Impossible de convertir l'image"]
            )
        }

        guard let url = URL(string: APIConfig.analyzeCVEndpoint) else {
            throw NSError(
                domain: "AICVService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "URL invalide pour l'analyse de CV"]
            )
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // --- Body multipart ---
        var body = Data()
        let fieldName = "file"  // Le backend attend 'file', pas 'image'
        let fileName = "cv_ios.jpg"
        let mimeType = "image/jpeg"

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "AICVService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Réponse invalide du serveur"]
            )
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 { throw AuthError.notAuthenticated }
            if httpResponse.statusCode == 404 { throw AuthError.userNotFound }
            
            let msg = String(data: data, encoding: .utf8) ?? "Erreur serveur"
            throw NSError(
                domain: "AICVService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: msg]
            )
        }

        let decoder = JSONDecoder()
        return try decoder.decode(CvStructuredResponse.self, from: data)
    }

    // MARK: - 2) Enregistrer dans le profil /user/me/cv/profile

    func saveProfileFromCv(_ cv: CvStructuredResponse, token: String) async throws {
        guard let url = URL(string: APIConfig.saveCVToProfileEndpoint) else {
            throw NSError(
                domain: "AICVService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "URL invalide pour l'enregistrement du profil"]
            )
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = CreateProfileFromCvRequest(
            name: cv.name,
            email: cv.email,
            phone: cv.phone,
            experience: cv.experience,
            education: cv.education,
            skills: cv.skills
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "AICVService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Réponse invalide du serveur"]
            )
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 { throw AuthError.notAuthenticated }
            if httpResponse.statusCode == 404 { throw AuthError.userNotFound }

            let msg = String(data: data, encoding: .utf8) ?? "Erreur serveur"
            throw NSError(
                domain: "AICVService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: msg]
            )
        }
    }
}
