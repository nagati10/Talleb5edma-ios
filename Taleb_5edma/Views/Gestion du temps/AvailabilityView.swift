//
//  AvailabilityView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

struct AvailabilityView: View {
    @StateObject private var viewModel = AvailabilityViewModel()
    @State private var showingExamMode = false
    @State private var selectedDay: String?
    @State private var showingCreateDisponibilite = false
    @State private var selectedDisponibilite: Disponibilite?
    
    let joursSemaine = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
    
    var body: some View {
        ZStack {
            AppColors.backgroundGray
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
                    // Mode examens
                    examModeSection
                    
                    // Jours de la semaine avec disponibilités
                    daysSection
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadDisponibilites()
            }
        }
            .sheet(isPresented: $showingExamMode) {
                ExamModeView()
        }
        .sheet(isPresented: $showingCreateDisponibilite) {
            if let day = selectedDay {
                CreateDisponibiliteView(
                    jour: day,
                    viewModel: viewModel
                ) {
                    Task {
                        await viewModel.loadDisponibilites()
                    }
                }
            }
        }
        .sheet(item: $selectedDisponibilite) { disponibilite in
            EditDisponibiliteView(
                disponibilite: disponibilite,
                viewModel: viewModel
            ) {
                Task {
                    await viewModel.loadDisponibilites()
                }
            }
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Indique quand tu N'ES PAS disponible")
                .font(.headline)
                .foregroundColor(AppColors.mediumGray)
            
            Text("Gain de temps")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryRed)
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var examModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(AppColors.primaryRed)
                
                Text("Mode Examens")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryRed)
            }
            
            Text("Configurez vos préférences pour la période d'examens")
                .font(.subheadline)
                .foregroundColor(AppColors.mediumGray)
            
            Button(action: {
                showingExamMode = true
            }) {
                HStack {
                    Text("Configurer le mode examens")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(AppColors.white)
                .padding()
                .background(AppColors.primaryRed)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var daysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cette semaine")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            ForEach(joursSemaine, id: \.self) { jour in
                DayRow(
                    jour: jour,
                    disponibilites: viewModel.getDisponibilitesForDay(jour),
                    onAdd: {
                        selectedDay = jour
                        showingCreateDisponibilite = true
                    },
                    onDelete: { disponibiliteId in
                        Task {
                            _ = await viewModel.deleteDisponibilite(disponibiliteId)
                            await viewModel.loadDisponibilites()
                        }
                    },
                    onEdit: { disponibilite in
                        selectedDisponibilite = disponibilite
                    }
                )
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct DayRow: View {
    let jour: String
    let disponibilites: [Disponibilite]
    let onAdd: () -> Void
    let onDelete: (String) -> Void
    var onEdit: ((Disponibilite) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
        HStack {
                Text(jour)
                .font(.headline)
                    .foregroundColor(AppColors.black)
                
            Spacer()
                
                Button(action: onAdd) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Ajouter")
                    }
                    .font(.caption)
            .foregroundColor(AppColors.primaryRed)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.primaryRed.opacity(0.1))
            .cornerRadius(6)
                }
            }
            
            if disponibilites.isEmpty {
                Text("Aucune indisponibilité")
                    .font(.caption)
                    .foregroundColor(AppColors.mediumGray)
                    .padding(.leading)
            } else {
                ForEach(disponibilites) { disponibilite in
                    DisponibiliteCard(
                        disponibilite: disponibilite,
                        onTap: {
                            onEdit?(disponibilite)
                        },
                        onDelete: {
                            onDelete(disponibilite.id)
                        }
                    )
                }
            }
        }
        .padding()
        .background(AppColors.backgroundGray)
        .cornerRadius(8)
    }
}

struct DisponibiliteCard: View {
    let disponibilite: Disponibilite
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(AppColors.primaryRed)
                        Text(disponibilite.heureDebut)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.black)
                    }
                    
                    if let heureFin = disponibilite.heureFin {
                        Text("jusqu'à \(heureFin)")
                            .font(.caption)
                            .foregroundColor(AppColors.mediumGray)
                    } else {
                        Text("Toute la journée")
                            .font(.caption)
                            .foregroundColor(AppColors.mediumGray)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Menu {
                Button("Modifier", action: onTap)
                Button("Supprimer", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(AppColors.mediumGray)
                    .padding(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.white)
        .cornerRadius(6)
    }
}

// MARK: - CreateDisponibiliteView

struct CreateDisponibiliteView: View {
    let jour: String
    @ObservedObject var viewModel: AvailabilityViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var heureDebut = Date()
    @State private var heureFin = Date()
    @State private var hasHeureFin = true
    
    let onDismiss: () -> Void
    
    init(jour: String, viewModel: AvailabilityViewModel, onDismiss: @escaping () -> Void) {
        self.jour = jour
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        
        // Initialiser avec des heures par défaut (9h-17h)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        self._heureDebut = State(initialValue: calendar.date(from: components) ?? Date())
        
        components.hour = 17
        components.minute = 0
        self._heureFin = State(initialValue: calendar.date(from: components) ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Jour") {
                    Text(jour)
                        .foregroundColor(AppColors.mediumGray)
                }
                
                Section("Horaires") {
                    DatePicker("Heure début", selection: $heureDebut, displayedComponents: .hourAndMinute)
                    
                    Toggle("Heure fin", isOn: $hasHeureFin)
                    
                    if hasHeureFin {
                        DatePicker("Heure fin", selection: $heureFin, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("Nouvelle indisponibilité")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Créer") {
                        createDisponibilite()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
    
    private func createDisponibilite() {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let heureDebutString = timeFormatter.string(from: heureDebut)
        let heureFinString = hasHeureFin ? timeFormatter.string(from: heureFin) : nil
        
        let request = CreateDisponibiliteRequest(
            jour: jour,
            heureDebut: heureDebutString,
            heureFin: heureFinString
        )
        
        Task {
            print("🟢 CreateDisponibiliteView - Début de la création pour \(jour)")
            let success = await viewModel.createDisponibilite(request)
            print("🟢 CreateDisponibiliteView - Résultat création: \(success)")
            
            if success {
                dismiss()
                onDismiss()
            }
        }
    }
}

// MARK: - EditDisponibiliteView

struct EditDisponibiliteView: View {
    let disponibilite: Disponibilite
    @ObservedObject var viewModel: AvailabilityViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var jour: String
    @State private var heureDebut: Date
    @State private var heureFin: Date
    @State private var hasHeureFin: Bool
    
    let onDismiss: () -> Void
    
    init(disponibilite: Disponibilite, viewModel: AvailabilityViewModel, onDismiss: @escaping () -> Void) {
        self.disponibilite = disponibilite
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        
        self._jour = State(initialValue: disponibilite.jour)
        
        // Convertir les heures String en Date
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        
        if let heureDebutDate = timeFormatter.date(from: disponibilite.heureDebut) {
            let heureDebutComponents = calendar.dateComponents([.hour, .minute], from: heureDebutDate)
            components.hour = heureDebutComponents.hour
            components.minute = heureDebutComponents.minute
            self._heureDebut = State(initialValue: calendar.date(from: components) ?? Date())
        } else {
            components.hour = 9
            components.minute = 0
            self._heureDebut = State(initialValue: calendar.date(from: components) ?? Date())
        }
        
        if let heureFinString = disponibilite.heureFin,
           let heureFinDate = timeFormatter.date(from: heureFinString) {
            let heureFinComponents = calendar.dateComponents([.hour, .minute], from: heureFinDate)
            components.hour = heureFinComponents.hour
            components.minute = heureFinComponents.minute
            self._heureFin = State(initialValue: calendar.date(from: components) ?? Date())
            self._hasHeureFin = State(initialValue: true)
        } else {
            components.hour = 17
            components.minute = 0
            self._heureFin = State(initialValue: calendar.date(from: components) ?? Date())
            self._hasHeureFin = State(initialValue: false)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Jour") {
                    Picker("Jour", selection: $jour) {
                        ForEach(["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"], id: \.self) { day in
                            Text(day).tag(day)
                        }
                    }
                }
                
                Section("Horaires") {
                    DatePicker("Heure début", selection: $heureDebut, displayedComponents: .hourAndMinute)
                    
                    Toggle("Heure fin", isOn: $hasHeureFin)
                    
                    if hasHeureFin {
                        DatePicker("Heure fin", selection: $heureFin, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("Modifier indisponibilité")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        updateDisponibilite()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
    
    private func updateDisponibilite() {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let heureDebutString = timeFormatter.string(from: heureDebut)
        let heureFinString = hasHeureFin ? timeFormatter.string(from: heureFin) : nil
        
        let request = UpdateDisponibiliteRequest(
            jour: jour,
            heureDebut: heureDebutString,
            heureFin: heureFinString
        )
        
        Task {
            print("🟢 EditDisponibiliteView - Début de la mise à jour")
            let success = await viewModel.updateDisponibilite(id: disponibilite.id, request)
            print("🟢 EditDisponibiliteView - Résultat mise à jour: \(success)")
            
            if success {
                dismiss()
                onDismiss()
            }
        }
    }
}

#Preview {
    AvailabilityView()
}
