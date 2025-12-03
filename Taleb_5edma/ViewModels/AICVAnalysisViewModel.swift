//
//  AICVAnalysisViewModel.swift
//  Taleb_5edma
//

import SwiftUI
import Combine      // 👈 AJOUTER ÇA

@MainActor
final class AICVAnalysisViewModel: ObservableObject {
    @Published var cvImage: UIImage?
    @Published var isAnalyzing = false
    @Published var analysisComplete = false
    @Published var errorMessage: String?
    @Published var result: CvStructuredResponse?
    @Published var shouldLogout = false

    func reset() {
        cvImage = nil
        isAnalyzing = false
        analysisComplete = false
        errorMessage = nil
        result = nil
    }

    func analyze(image: UIImage, token: String?) async {
        self.errorMessage = nil
        self.isAnalyzing = true
        self.analysisComplete = false
        self.result = nil
        self.shouldLogout = false

        do {
            let res = try await AICVService.shared.analyzeCv(image: image, token: token)
            self.result = res
            self.analysisComplete = true
        } catch let error as AuthError where error == .userNotFound {
            // Utilisateur introuvable = état invalide, déconnecter
            self.shouldLogout = true
        } catch {
            self.errorMessage = error.localizedDescription
        }

        self.isAnalyzing = false
    }

    func saveToProfile(token: String) async throws {
        guard let result = result else { return }
        try await AICVService.shared.saveProfileFromCv(result, token: token)
    }
}
