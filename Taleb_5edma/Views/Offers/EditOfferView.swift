//
//  EditOfferView.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import SwiftUI
import UIKit

/// Vue pour modifier une offre existante
struct EditOfferView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    let offre: Offre
    @ObservedObject var viewModel: OffreViewModel
    let onDismiss: () -> Void
    
    // Champs du formulaire initialisés avec les valeurs de l'offre
    @State private var title: String
    @State private var description: String
    @State private var selectedTags: Set<String>
    @State private var exigences: [String]
    @State private var newExigence = ""
    @State private var address: String
    @State private var city: String
    @State private var country: String
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var category: String
    @State private var salary: String
    @State private var company: String
    @State private var expiresAt: Date
    @State private var jobType: String
    @State private var shift: String
    @State private var isActive: Bool
    
    // Images
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // État de chargement et erreurs
    @State private var showSuccess = false
    
    // Tags disponibles
    let availableTags = ["Urgent", "CDI", "CDD", "Stage", "Freelance", "Télétravail", "Formation", "Équipe dynamique"]
    
    init(offre: Offre, viewModel: OffreViewModel, onDismiss: @escaping () -> Void) {
        self.offre = offre
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        
        // Initialiser les champs avec les valeurs de l'offre
        _title = State(initialValue: offre.title)
        _description = State(initialValue: offre.description)
        _selectedTags = State(initialValue: Set(offre.tags ?? []))
        _exigences = State(initialValue: offre.exigences ?? [])
        _address = State(initialValue: offre.location.address)
        _city = State(initialValue: offre.location.city ?? "")
        _country = State(initialValue: offre.location.country ?? "")
        _latitude = State(initialValue: offre.location.coordinates?.lat)
        _longitude = State(initialValue: offre.location.coordinates?.lng)
        _category = State(initialValue: offre.category ?? "")
        _salary = State(initialValue: offre.salary ?? "")
        _company = State(initialValue: offre.company)
        
        // Parser la date d'expiration
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let parsedDate = offre.expiresAt.flatMap { dateFormatter.date(from: $0) } ?? Date()
        _expiresAt = State(initialValue: parsedDate)
        
        _jobType = State(initialValue: offre.jobType ?? "")
        _shift = State(initialValue: offre.shift ?? "")
        _isActive = State(initialValue: offre.isActive ?? true)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Section Informations principales
                        mainInfoSection
                        
                        // Section Description
                        descriptionSection
                        
                        // Section Localisation
                        locationSection
                        
                        // Section Tags
                        tagsSection
                        
                        // Section Exigences
                        exigencesSection
                        
                        // Section Informations supplémentaires
                        additionalInfoSection
                        
                        // Bouton de soumission
                        submitButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Modifier l'offre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
            }
            .alert("Erreur", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Une erreur est survenue")
            }
            .alert("Succès", isPresented: $showSuccess) {
                Button("OK") {
                    onDismiss()
                    dismiss()
                }
            } message: {
                Text("L'offre a été modifiée avec succès!")
            }
        }
    }
    
    // MARK: - Main Info Section
    
    private var mainInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Informations principales")
                .font(.headline)
                .foregroundColor(AppColors.black)
            
            // Titre
            VStack(alignment: .leading, spacing: 8) {
                Text("Titre *")
                    .font(.subheadline)
                    .foregroundColor(AppColors.black)
                TextField("Ex: Développeur Web Junior", text: $title)
                    .textFieldStyle(OfferTextFieldStyle())
            }
            
            // Entreprise
            VStack(alignment: .leading, spacing: 8) {
                Text("Entreprise *")
                    .font(.subheadline)
                    .foregroundColor(AppColors.black)
                TextField("Nom de l'entreprise", text: $company)
                    .textFieldStyle(OfferTextFieldStyle())
            }
            
            // Catégorie
            VStack(alignment: .leading, spacing: 8) {
                Text("Catégorie")
                    .font(.subheadline)
                    .foregroundColor(AppColors.black)
                TextField("Ex: Informatique, BTP, etc.", text: $category)
                    .textFieldStyle(OfferTextFieldStyle())
            }
            
            // Type de poste
            VStack(alignment: .leading, spacing: 8) {
                Text("Type de poste")
                    .font(.subheadline)
                    .foregroundColor(AppColors.black)
                Picker("Type de poste", selection: $jobType) {
                    Text("Sélectionner").tag("")
                    Text("Job").tag("job")
                    Text("Stage").tag("stage")
                    Text("Freelance").tag("freelance")
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(AppColors.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.lightGray, lineWidth: 1)
                )
            }
            
            // Horaire
            VStack(alignment: .leading, spacing: 8) {
                Text("Horaire")
                    .font(.subheadline)
                    .foregroundColor(AppColors.black)
                Picker("Horaire", selection: $shift) {
                    Text("Sélectionner").tag("")
                    Text("Jour").tag("jour")
                    Text("Nuit").tag("nuit")
                    Text("Flexible").tag("flexible")
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(AppColors.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.lightGray, lineWidth: 1)
                )
            }
            
            // Salaire
            VStack(alignment: .leading, spacing: 8) {
                Text("Salaire")
                    .font(.subheadline)
                    .foregroundColor(AppColors.black)
                TextField("Ex: 500-800 DT/mois", text: $salary)
                    .textFieldStyle(OfferTextFieldStyle())
                    .keyboardType(.default)
            }
            
            // Statut actif
            Toggle("Offre active", isOn: $isActive)
                .padding()
                .background(AppColors.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.lightGray, lineWidth: 1)
                )
        }
        .cardStyle()
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description *")
                .font(.headline)
                .foregroundColor(AppColors.black)
            
            TextEditor(text: $description)
                .frame(minHeight: 120)
                .padding(8)
                .background(AppColors.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.lightGray, lineWidth: 1)
                )
        }
        .cardStyle()
    }
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Localisation *")
                .font(.headline)
                .foregroundColor(AppColors.black)
            
            // Adresse
            VStack(alignment: .leading, spacing: 8) {
                Text("Adresse")
                    .font(.subheadline)
                    .foregroundColor(AppColors.black)
                TextField("Ex: 123 Rue de la République", text: $address)
                    .textFieldStyle(OfferTextFieldStyle())
            }
            
            // Ville
            VStack(alignment: .leading, spacing: 8) {
                Text("Ville")
                    .font(.subheadline)
                    .foregroundColor(AppColors.black)
                TextField("Ex: Tunis", text: $city)
                    .textFieldStyle(OfferTextFieldStyle())
            }
            
            // Pays
            VStack(alignment: .leading, spacing: 8) {
                Text("Pays")
                    .font(.subheadline)
                    .foregroundColor(AppColors.black)
                TextField("Ex: Tunisie", text: $country)
                    .textFieldStyle(OfferTextFieldStyle())
            }
        }
        .cardStyle()
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(AppColors.black)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(availableTags, id: \.self) { tag in
                    TagChip(
                        text: tag,
                        isSelected: selectedTags.contains(tag),
                        action: {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    )
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Exigences Section
    
    private var exigencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exigences")
                .font(.headline)
                .foregroundColor(AppColors.black)
            
            // Ajouter une exigence
            HStack {
                TextField("Ajouter une exigence", text: $newExigence)
                    .textFieldStyle(OfferTextFieldStyle())
                
                Button(action: {
                    if !newExigence.isEmpty {
                        exigences.append(newExigence)
                        newExigence = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primaryRed)
                }
            }
            
            // Liste des exigences
            if !exigences.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(exigences.indices, id: \.self) { index in
                        HStack {
                            Text(exigences[index])
                                .font(.system(size: 14))
                            Spacer()
                            Button(action: {
                                exigences.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.primaryRed)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Additional Info Section
    
    private var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Informations supplémentaires")
                .font(.headline)
                .foregroundColor(AppColors.black)
            
            // Date d'expiration
            VStack(alignment: .leading, spacing: 8) {
                Text("Date d'expiration")
                    .font(.subheadline)
                    .foregroundColor(AppColors.black)
                DatePicker("", selection: $expiresAt, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding()
                    .background(AppColors.white)
                    .cornerRadius(12)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        Button(action: {
            submitOffer()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.white)
                } else {
                    Text("Enregistrer les modifications")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(AppColors.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.primaryRed, AppColors.accentPink]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading || !isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
        .padding(.vertical, 8)
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && !address.isEmpty && !company.isEmpty
    }
    
    // MARK: - Submit Action
    
    private func submitOffer() {
        guard isFormValid else {
            return
        }
        
        // Créer la location
        let coordinates: Coordinates? = {
            if let lat = latitude, let lng = longitude {
                return Coordinates(lat: lat, lng: lng)
            }
            return nil
        }()
        
        let location = OffreLocation(
            address: address,
            city: city.isEmpty ? nil : city,
            country: country.isEmpty ? nil : country,
            coordinates: coordinates
        )
        
        // Formater la date d'expiration
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let expiresAtString = dateFormatter.string(from: expiresAt)
        
        // Créer la requête de mise à jour
        let request = UpdateOffreRequest(
            title: title,
            description: description,
            tags: selectedTags.isEmpty ? nil : Array(selectedTags),
            exigences: exigences.isEmpty ? nil : exigences,
            location: location,
            category: category.isEmpty ? nil : category,
            salary: salary.isEmpty ? nil : salary,
            company: company,
            expiresAt: expiresAtString,
            jobType: jobType.isEmpty ? nil : jobType,
            shift: shift.isEmpty ? nil : shift,
            isActive: isActive
        )
        
        // Envoyer la requête
        Task {
            let success = await viewModel.updateOffre(id: offre.id, request)
            if success {
                showSuccess = true
            }
        }
    }
}

#Preview {
    EditOfferView(
        offre: Offre(
            id: "1",
            title: "Développeur Web Junior",
            description: "Description",
            tags: ["CDI"],
            exigences: ["JavaScript"],
            location: OffreLocation(
                address: "123 Rue",
                city: "Tunis",
                country: "Tunisie",
                coordinates: nil
            ),
            category: "Informatique",
            salary: "500-800 DT",
            company: "TechCorp",
            expiresAt: "2025-12-31",
            jobType: "job",
            shift: "jour",
            isActive: true,
            images: nil,
            viewCount: 10,
            likeCount: 5,
            userId: nil,
            createdAt: nil,
            updatedAt: nil
        ),
        viewModel: OffreViewModel(),
        onDismiss: {}
    )
}

