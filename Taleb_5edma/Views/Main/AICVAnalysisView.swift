// AICVAnalysisView.swift

import SwiftUI

struct AICVAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService   // doit contenir le token (ex: accessToken)

    @StateObject private var vm = AICVAnalysisViewModel()
    @State private var showingImagePicker = false
    @State private var showSaveAlert = false
    @State private var saveMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // erreur éventuelle
                    if let error = vm.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }

                    if !vm.analysisComplete {
                        uploadSection
                    } else {
                        analysisResultsSection
                    }
                }
                .padding()
            }
            .background(AppColors.backgroundGray)
            .navigationTitle("Analyse CV IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle().fill(Color.white.opacity(0.2))
                            )
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
            }
            // ✅ bon nom de state + bon picker
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $vm.cvImage)
            }
            .onChange(of: vm.cvImage) { newImage in
                if let image = newImage {
                    Task {
                        await vm.analyze(image: image, token: authService.authToken)
                    }
                }
            }
            .onChange(of: vm.shouldLogout) { should in
                if should {
                    authService.logout()
                }
            }
            .alert(isPresented: $showSaveAlert) {
                Alert(
                    title: Text("Profil"),
                    message: Text(saveMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Section upload

    private var uploadSection: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primaryRed)

                Text("Analysez votre CV avec l'IA")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryRed)

                Text("Générez ou analysez votre CV avec l'intelligence artificielle")
                    .font(.subheadline)
                    .foregroundColor(AppColors.mediumGray)
                    .multilineTextAlignment(.center)
            }

            // Zone upload
            VStack(spacing: 16) {
                if let image = vm.cvImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(AppColors.backgroundGray)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.mediumGray)

                                Text("Ajoutez votre CV")
                                    .font(.headline)
                                    .foregroundColor(AppColors.mediumGray)
                            }
                        )
                        .cornerRadius(12)
                        .onTapGesture {
                            showingImagePicker = true
                        }
                }

                HStack(spacing: 12) {
                    Button {
                        showingImagePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "photo")
                            Text("CV existant")
                        }
                        .font(.headline)
                        .foregroundColor(AppColors.primaryRed)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.primaryRed, lineWidth: 1)
                        )
                    }

                    Button {
                        // TODO: génération de CV via IA plus tard
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Générer CV IA")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryRed)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(AppColors.white)
            .cornerRadius(12)

            // Bouton analyser
            if vm.cvImage != nil {
                Button {
                    if let img = vm.cvImage {
                        Task {
                            await vm.analyze(image: img, token: authService.authToken)
                        }
                    }
                } label: {
                    if vm.isAnalyzing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Analyser le CV")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primaryRed)
                .cornerRadius(12)
                .disabled(vm.isAnalyzing)
            }
        }
    }

    // MARK: - Section résultats

    private var analysisResultsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let r = vm.result {

                // En-tête
                VStack(alignment: .leading, spacing: 8) {
                    if let name = r.name {
                        Text(name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.black)
                    }
                    if let email = r.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(AppColors.mediumGray)
                    }
                    if let phone = r.phone {
                        Text(phone)
                            .font(.subheadline)
                            .foregroundColor(AppColors.mediumGray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppColors.white)
                .cornerRadius(12)

                // Expérience
                if !r.experience.isEmpty {
                    section(title: "EXPÉRIENCE") {
                        ForEach(r.experience, id: \.self) { line in
                            Text("• \(line)")
                                .font(.subheadline)
                        }
                    }
                }

                // Formation
                if !r.education.isEmpty {
                    section(title: "FORMATION") {
                        ForEach(r.education, id: \.self) { line in
                            Text("• \(line)")
                                .font(.subheadline)
                        }
                    }
                }

                // Compétences
                if !r.skills.isEmpty {
                    section(title: "COMPÉTENCES") {
                        Text(r.skills.joinToString())
                            .font(.subheadline)
                    }
                }

                // Enregistrer dans profil
                Button {
                    Task {
                        guard let token = authService.authToken else { return }
                        do {
                            try await vm.saveToProfile(token: token)
                            saveMessage = "Les informations du CV ont été enregistrées dans votre profil."
                            showSaveAlert = true
                        } catch let error as AuthError where error == .userNotFound || error == .notAuthenticated {
                            authService.logout()
                        } catch {
                            saveMessage = "Erreur: \(error.localizedDescription)"
                            showSaveAlert = true
                        }
                    }
                } label: {
                    Text("Enregistrer dans mon profil")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryRed)
                        .cornerRadius(12)
                }

                // Nouvelle analyse
                Button {
                    vm.reset()
                } label: {
                    Text("Nouvelle Analyse")
                        .font(.headline)
                        .foregroundColor(AppColors.primaryRed)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.primaryRed, lineWidth: 1)
                        )
                }
            }
        }
    }

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)

            VStack(alignment: .leading, spacing: 8, content: content)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// petit helper pour joindre la liste de skills
private extension Array where Element == String {
    func joinToString() -> String {
        joined(separator: ", ")
    }
}
