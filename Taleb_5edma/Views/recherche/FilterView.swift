//
//  FilterView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

//
//  FilterView.swift
//  Taleb_5edma
//

import SwiftUI

struct FilterView: View {
    @Environment(\.presentationMode) var presentationMode
    // Modèle de filtre manipulé avant d'appliquer les changements
    @State private var filter = JobFilter()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Recherche
                    searchSection
                    
                    // Catégorie
                    categorySection
                    
                    // Salaire
                    salarySection
                    
                    // Localisation
                    locationSection
                    
                    // Type d'horaire
                    scheduleSection
                    
                    // Options
                    optionsSection
                }
                .padding()
            }
            .background(AppColors.backgroundGray)
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Appliquer") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recherche")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.mediumGray)
                
                TextField("Mot-clé...", text: $filter.searchText)
            }
            .padding()
            .background(AppColors.white)
            .cornerRadius(8)
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Catégorie")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(JobCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: filter.selectedCategory == category
                    ) {
                        filter.selectedCategory = category
                    }
                }
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
    }
    
    private var salarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Salaire (\(Int(filter.salaryRange.lowerBound)) - \(Int(filter.salaryRange.upperBound)) DT)")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            VStack(spacing: 16) {
                Slider(
                    value: .init(
                        get: { filter.salaryRange.upperBound },
                        set: { filter.salaryRange = 0...$0 }
                    ),
                    in: 0...500,
                    step: 10
                )
                .accentColor(AppColors.primaryRed)
                
                HStack {
                    Text("0 DT")
                    Spacer()
                    Text("500 DT")
                }
                .font(.caption)
                .foregroundColor(AppColors.mediumGray)
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Localisation")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(AppColors.mediumGray)
                
                TextField("Ville, région...", text: $filter.location)
            }
            .padding()
            .background(AppColors.backgroundGray)
            .cornerRadius(8)
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
    }
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type d'horaire")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(ScheduleType.allCases, id: \.self) { schedule in
                    ScheduleChip(
                        title: schedule.rawValue,
                        isSelected: filter.scheduleType == schedule
                    ) {
                        filter.scheduleType = schedule
                    }
                }
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Options")
                .font(.headline)
                .foregroundColor(AppColors.primaryRed)
            
            Toggle("Afficher seulement les populaires", isOn: $filter.showPopularOnly)
                .toggleStyle(SwitchToggleStyle(tint: AppColors.primaryRed))
            
            Toggle("Afficher seulement les favoris", isOn: $filter.showFavoritesOnly)
                .toggleStyle(SwitchToggleStyle(tint: AppColors.primaryRed))
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(12)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppColors.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? AppColors.primaryRed : AppColors.backgroundGray)
                .cornerRadius(8)
        }
    }
}

struct ScheduleChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppColors.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primaryRed : AppColors.backgroundGray)
                .cornerRadius(6)
        }
    }
}

#Preview {
    FilterView()
}
