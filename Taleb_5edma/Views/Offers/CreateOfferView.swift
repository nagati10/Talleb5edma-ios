//
//  CreateOfferView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI
import UIKit

struct CreateOfferView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    // ViewModel pour gérer la logique métier
    @StateObject private var viewModel = OffreViewModel()
    
    // Champs du formulaire
    @State private var title = ""
    @State private var description = ""
    @State private var selectedTags: Set<String> = []
    @State private var exigences: [String] = []
    @State private var newExigence = ""
    @State private var address = ""
    @State private var city = ""
    @State private var country = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var category: String = ""
    @State private var salary = ""
    @State private var company = ""
    @State private var expiresAt = Date()
    @State private var jobType: String = ""
    @State private var shift: String = ""
    
    // Images
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // État de chargement et erreurs
    @State private var showSuccess = false
    
    // Tags disponibles
    let availableTags = ["Urgent", "CDI", "CDD", "Stage", "Freelance", "Télétravail", "Formation", "Équipe dynamique"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Section Image
                        imageSection
                        
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
            .navigationTitle("Nouvelle offre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: Binding(
                    get: { selectedImages.last },
                    set: { newImage in
                        if let image = newImage {
                            selectedImages.append(image)
                        }
                    }
                ), sourceType: sourceType)
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Sélectionner une image"),
                    buttons: [
                        .default(Text("Caméra")) {
                            sourceType = .camera
                            showImagePicker = true
                        },
                        .default(Text("Galerie")) {
                            sourceType = .photoLibrary
                            showImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .alert("Erreur", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Une erreur est survenue")
            }
            .alert("Succès", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("L'offre a été créée avec succès!")
            }
        }
    }
    
    // MARK: - Image Section
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image de l'offre")
                .font(.headline)
                .foregroundColor(AppColors.black)
            
            Button(action: {
                showActionSheet = true
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.lightGray.opacity(0.3))
                        .frame(height: 200)
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 200)
                                        .clipped()
                                        .cornerRadius(12)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.primaryRed)
                            Text("Ajouter une image")
                                .font(.subheadline)
                                .foregroundColor(AppColors.mediumGray)
                        }
                    }
                }
            }
        }
        .cardStyle()
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
                    Text("Publier l'offre")
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
        
        // Créer la requête
        let request = CreateOffreRequest(
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
            isActive: true
        )
        
        // Convertir les images en Data
        let imageData = selectedImages.compactMap { image in
            image.jpegData(compressionQuality: 0.8)
        }
        
        // Envoyer la requête
        Task {
            let success = await viewModel.createOffre(request, imageFiles: imageData.isEmpty ? nil : imageData)
            if success {
                showSuccess = true
            }
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppColors.primaryRed : AppColors.lightGray.opacity(0.3))
                .foregroundColor(isSelected ? AppColors.white : AppColors.black)
                .cornerRadius(16)
        }
    }
}


// MARK: - Custom Text Field Style

struct OfferTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppColors.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.lightGray, lineWidth: 1)
            )
    }
}

#Preview {
    CreateOfferView()
        .environmentObject(AuthService())
}

