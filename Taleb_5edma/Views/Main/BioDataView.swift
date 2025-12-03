// BioDataView.swift
import SwiftUI

struct BioDataView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    // Champs éditables reflétant le formulaire utilisateur
    @State private var nom: String = ""
    @State private var contact: String = ""
    
    var body: some View {
        ZStack {
            AppColors.backgroundGray
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppColors.primaryRed)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        bioDataHeader
                        
                        // Form
                        bioDataForm
                        
                        // Update Button
                        updateButton
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Bio-data")
        .navigationBarTitleDisplayMode(.large)
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue")
        }
        .alert("Succès", isPresented: $viewModel.showSuccess) {
            Button("OK", role: .cancel) {
                // Retourner à l'écran précédent après succès
                dismiss()
            }
        } message: {
            Text(viewModel.successMessage ?? "Profil mis à jour avec succès")
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private var bioDataHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.currentUser?.nom ?? "")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.black)
            
            Text(viewModel.currentUser?.email ?? "")
                .font(.body)
                .foregroundColor(AppColors.mediumGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.white)
    }
    
    private var bioDataForm: some View {
        VStack(spacing: 0) {
            // Nom complet
            formField(
                title: "Nom complet",
                text: $nom,
                placeholder: "Entrez votre nom complet"
            )
            
            // Contact
            formField(
                title: "Numéro de téléphone",
                text: $contact,
                placeholder: "Entrez votre numéro",
                keyboardType: .phonePad
            )
            
            // Email (non modifiable - lecture seule)
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.caption)
                    .foregroundColor(AppColors.mediumGray)
                
                Text(viewModel.currentUser?.email ?? "Non disponible")
                    .padding()
                    .background(AppColors.lightGray)
                    .cornerRadius(8)
                    .foregroundColor(AppColors.mediumGray)
            }
            .padding()
            .background(AppColors.white)
        }
        .padding(.top, 1)
    }
    
    private func formField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.mediumGray)
            
            TextField(placeholder, text: text)
                .padding()
                .background(AppColors.lightGray)
                .cornerRadius(8)
                .keyboardType(keyboardType)
        }
        .padding()
        .background(AppColors.white)
    }
    
    private var updateButton: some View {
        Button(action: {
            updateProfile()
        }) {
            Text("Mettre à jour le profil")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [AppColors.primaryRed, AppColors.darkRed],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .padding()
        }
        .padding(.top, 24)
        .disabled(nom.isEmpty || contact.isEmpty || viewModel.isLoading)
        .opacity((nom.isEmpty || contact.isEmpty || viewModel.isLoading) ? 0.6 : 1.0)
    }
    
    private func loadUserData() {
        if let user = viewModel.currentUser {
            nom = user.nom
            contact = user.contact
        }
    }
    
    private func updateProfile() {
        guard !nom.isEmpty, !contact.isEmpty else {
            viewModel.errorMessage = "Veuillez remplir tous les champs"
            viewModel.showError = true
            return
        }
        
        // Ne pas fermer l'écran immédiatement - attendre la réponse de l'API
        viewModel.updateUserProfile(nom: nom, contact: contact)
        
        // Note: L'écran se fermera automatiquement quand l'utilisateur cliquera sur "OK"
        // dans l'alerte de succès grâce au dismiss() dans le .alert
    }
}

#Preview {
    NavigationView {
        BioDataView(viewModel: ProfileViewModel(authService: AuthService()))
    }
}
