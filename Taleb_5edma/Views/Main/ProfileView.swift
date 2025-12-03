//
//  ProfileView.swift
//  Taleb_5edma
//

import SwiftUI
import UIKit

struct ProfileView: View {
    // ViewModel propre à l'écran profil, initialisé avec le service d'authentification
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject var authService: AuthService
    
    // États pour le sélecteur d'image
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingReclamations = false
    @State private var showingNewReclamation = false
    
    init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.red)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header avec photo de profil
                            profileHeader
                            
                            // Section Mon Compte
                            myAccountSection
                            
                            // Section Réclamations
                            reclamationsSection
                            
                            // Section Déconnexion
                            logoutSection
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Erreur", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Une erreur est survenue")
            }
            .alert("Succès", isPresented: $viewModel.showSuccess) {
                Button("OK", role: .cancel) {
                    // Réinitialiser l'image sélectionnée après succès
                    selectedImage = nil
                }
            } message: {
                Text(viewModel.successMessage ?? "Opération réussie")
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Choisir une photo"),
                    buttons: [
                        .default(Text("Caméra")) {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                sourceType = .camera
                                showImagePicker = true
                            }
                        },
                        .default(Text("Galerie")) {
                            sourceType = .photoLibrary
                            showImagePicker = true
                        },
                        .cancel(Text("Annuler"))
                    ]
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(selectedImage: $selectedImage, sourceType: sourceType)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                // Upload l'image quand elle est sélectionnée
                if let image = newValue {
                    viewModel.uploadProfileImage(image)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Photo de profil avec possibilité de modification
            ZStack {
                Circle()
                    .fill(.red)
                    .frame(width: 100, height: 100)
                
                // Afficher l'image sélectionnée ou celle du serveur
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else if let imageUrl = viewModel.currentUser?.image, !imageUrl.isEmpty {
                    // Ici vous pouvez charger l'image depuis l'URL
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text("IMG")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Text(getInitials(from: viewModel.currentUser?.nom ?? "U"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Badge de modification en bas à droite
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showActionSheet = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(.red)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                )
                        }
                    }
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }
                .frame(width: 100, height: 100)
            }
            .onTapGesture {
                showActionSheet = true
            }
            
            // Nom et email
            VStack(spacing: 4) {
                Text(viewModel.currentUser?.nom ?? "Utilisateur")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(viewModel.currentUser?.email ?? "email@exemple.com")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                if let contact = viewModel.currentUser?.contact, !contact.isEmpty {
                    Text(contact)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(.white)
    }
    
    private var myAccountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Mon Compte")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                NavigationLink(destination: BioDataView(viewModel: viewModel)) {
                    ProfileMenuItem(
                        icon: "person.circle",
                        title: "Modifier le profil",
                        subtitle: "Mettre à jour vos informations personnelles"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .padding(.leading, 56)
                
                NavigationLink(
                    destination: PasswordResetView(
                        viewModel: PasswordResetViewModel(
                            authService: authService,
                            mode: .updatePassword,
                            email: viewModel.currentUser?.email
                        )
                    )
                ) {
                    ProfileMenuItem(
                        icon: "lock.rotation",
                        title: "Modifier le mot de passe",
                        subtitle: "Choisir un nouveau mot de passe sécurisé"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var reclamationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Réclamations")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                // Navigation vers les réclamations
                Button(action: {
                    showingReclamations = true
                }) {
                    ProfileMenuItem(
                        icon: "exclamationmark.bubble",
                        title: "Mes réclamations",
                        subtitle: "Consulter et gérer vos réclamations"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .padding(.leading, 56)
                
                // Option pour créer une réclamation rapide
                Button(action: {
                    showingNewReclamation = true
                }) {
                    ProfileMenuItem(
                        icon: "plus.circle",
                        title: "Nouvelle réclamation",
                        subtitle: "Signaler un problème ou donner votre avis"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .sheet(isPresented: $showingReclamations) {
            Text("Mes Réclamations - À implémenter")
        }
        .sheet(isPresented: $showingNewReclamation) {
            Text("Nouvelle Réclamation - À implémenter")
        }
    }
    
    private var logoutSection: some View {
        Button(action: {
            viewModel.logout()
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
                
                Text("Se déconnecter")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding()
            .background(.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private func getInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else {
            return String(name.prefix(1)).uppercased()
        }
    }
}

// MARK: - Profile Menu Item Component
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .contentShape(Rectangle()) // Important pour que tout le rectangle soit cliquable
    }
}

// MARK: - Image Picker View (Renommé pour éviter les conflits)
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ProfileView(authService: AuthService())
        .environmentObject(AuthService())
}
