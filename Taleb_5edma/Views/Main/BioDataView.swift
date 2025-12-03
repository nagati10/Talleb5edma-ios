//
//  BioDataView.swift
//  Taleb_5edma
//

import SwiftUI

struct BioDataView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var showAICVAnalysis = false
    
    // Champs éditables
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var joinedAt: String = "08 novembre 2025"
    
    // Pour savoir si quelque chose a changé
    @State private var initialName: String = ""
    @State private var initialPhone: String = ""
    
    private var hasChanges: Bool {
        (name != initialName || phone != initialPhone)
        && !name.isEmpty
        && !phone.isEmpty
    }
    
    var body: some View {
        ZStack {
            // Background dégradé
            LinearGradient(
                colors: [AppColors.darkRed, AppColors.primaryRed],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack {
                    Spacer(minLength: 40)
                    
                    // Carte principale
                    VStack(spacing: 22) {
                        
                        // Titre
                        VStack(alignment: .leading, spacing: 4) {
                            Text(" profil" )
                                .font(.largeTitle)
                                .fontWeight(.heavy)
                                .foregroundColor(AppColors.black)
                            
                            Text("Mettre à jour vos informations personnelles")
                                .font(.subheadline)
                                .foregroundColor(AppColors.mediumGray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Champs
                        VStack(spacing: 16) {
                            fieldRow(
                                label: "Name",
                                systemIcon: "person.fill",
                                text: $name,
                                editable: true
                            )
                            
                            fieldRow(
                                label: "Email",
                                systemIcon: "envelope.fill",
                                text: $email,
                                editable: false
                            )
                            
                            fieldRow(
                                label: "Phone Number",
                                systemIcon: "phone.fill",
                                text: $phone,
                                editable: true,
                                keyboardType: .phonePad
                            )
                            
                            // Joined at
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Joined at")
                                    .font(.caption)
                                    .foregroundColor(AppColors.mediumGray)
                                
                                Text(joinedAt)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical)
                                    .background(
                                        Capsule()
                                            .fill(AppColors.white)
                                            .shadow(
                                                color: .black.opacity(0.05),
                                                radius: 3,
                                                x: 0,
                                                y: 1
                                            )
                                    )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Boutons
                        VStack(spacing: 14) {
                            Button {
                                showAICVAnalysis = true
                            } label: {
                                Text("Analyser mon CV avec l'IA")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [AppColors.primaryRed, AppColors.darkRed],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                            }
                            
                           
                            
                            Button {
                                saveChanges()
                            } label: {
                                Text("Save Changes")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        AppColors.lightGray.opacity(hasChanges ? 1.0 : 0.7)
                                    )
                                    .foregroundColor(
                                        hasChanges ? AppColors.black : AppColors.mediumGray
                                    )
                                    .cornerRadius(14)
                            }
                            .disabled(!hasChanges)
                        }
                    }
                    .padding(24)
                    .background(
                        AppColors.white
                            .opacity(0.96)
                            .cornerRadius(26)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 6)
                    .padding(.horizontal, 20)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding( .leading, 16)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            loadUserData()
        }
        .fullScreenCover(isPresented: $showAICVAnalysis) {
            AICVAnalysisView()
                .environmentObject(authService)
        }
    }
    
    // MARK: - Sous-vues
    
    private func fieldRow(
        label: String,
        systemIcon: String,
        text: Binding<String>,
        editable: Bool,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(AppColors.mediumGray)
            
            HStack(spacing: 10) {
                Image(systemName: systemIcon)
                    .foregroundColor(AppColors.black)
                    .frame(width: 24)
                
                if editable {
                    TextField(label, text: text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled(true)
                } else {
                    Text(text.wrappedValue)
                        .foregroundColor(AppColors.mediumGray)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColors.white)
            )
        }
    }
    
    // MARK: - Logic
    
    private func loadUserData() {
        if let user = viewModel.currentUser {
            name = user.nom
            email = user.email
            phone = user.contact
            
            initialName = user.nom
            initialPhone = user.contact
        }
    }
    
    private func saveChanges() {
        viewModel.updateUserProfile(nom: name, contact: phone)
    }
}

#Preview {
    let auth = AuthService()
    let vm = ProfileViewModel(authService: auth)
    
    return NavigationStack {
        BioDataView(viewModel: vm)
            .environmentObject(auth)
    }
}
