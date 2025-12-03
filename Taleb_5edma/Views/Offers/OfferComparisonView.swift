//
//  OfferComparisonView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

//
//  OfferComparisonView.swift
//  Taleb_5edma
//

import SwiftUI

struct OfferComparisonView: View {
    @Environment(\.dismiss) var dismiss
    // Affiche ou masque la deuxième colonne de comparaison
    @State private var showSecondOffer = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppColors.primaryRed)
                            .frame(width: 40, height: 40)
                            .background(AppColors.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Title
                Text("Comparaison d'Offres")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.primaryRed)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // Comparison Card
                CardView(showSecondOffer: $showSecondOffer)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            }
        }
        .navigationBarHidden(true)
    }
}

struct CardView: View {
    @Binding var showSecondOffer: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header avec les offres
            ZStack {
                LinearGradient(
                    colors: [AppColors.primaryRed.opacity(0.8), AppColors.accentPink.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 120)
                
                HStack(spacing: 0) {
                    Spacer()
                    
                    OfferColumn(
                        letter: "A",
                        category: "Restaurant",
                        color: AppColors.successGreen,
                        isVisible: true,
                        onRemove: {},
                        onAdd: {}
                    )
                    
                    Spacer()
                    
                    OfferColumn(
                        letter: "B",
                        category: "Café",
                        color: AppColors.primaryRed,
                        isVisible: showSecondOffer,
                        onRemove: { withAnimation { showSecondOffer = false } },
                        onAdd: { withAnimation { showSecondOffer = true } }
                    )
                    
                    Spacer()
                }
                .padding(.top, 24)
            }
            
            // En-tête des colonnes
            HStack(spacing: 0) {
                Text("CRITÈRE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                
                Text("OFFRE A")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                if showSecondOffer {
                    Text("OFFRE B")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(AppColors.darkGray)
            
            // Contenu de comparaison
            ScrollView {
                VStack(spacing: 0) {
                    ComparisonRow(
                        label: "Correspondance",
                        valueA: "80%",
                        valueB: "60%",
                        showSecondOffer: showSecondOffer,
                        backgroundColor: AppColors.backgroundGray,
                        valueAColor: AppColors.successGreen,
                        valueBColor: AppColors.primaryRed,
                        isScore: true
                    )
                    
                    SectionHeader(text: "COMPATIBILITÉ AVEC LES ÉTUDES")
                    
                    ComparisonRow(
                        label: "Horaire & Flexibilité",
                        valueA: "Flexible",
                        valueB: "Flexible",
                        showSecondOffer: showSecondOffer,
                        backgroundColor: AppColors.backgroundGray
                    )
                    
                    ComparisonRow(
                        label: "Temps de trajet",
                        valueA: "15 min",
                        valueB: "45 min",
                        showSecondOffer: showSecondOffer,
                        backgroundColor: AppColors.backgroundGray
                    )
                    
                    ComparisonRow(
                        label: "Charge de travail",
                        valueA: "3h",
                        valueB: "8h",
                        showSecondOffer: showSecondOffer,
                        backgroundColor: AppColors.backgroundGray
                    )
                    
                    SectionHeader(text: "RÉMUNÉRATION & AVANTAGES")
                    
                    ComparisonRow(
                        label: "Salaire",
                        valueA: "40d",
                        valueB: "70d",
                        showSecondOffer: showSecondOffer,
                        backgroundColor: AppColors.backgroundGray
                    )
                    
                    ComparisonRow(
                        label: "Avantages",
                        valueA: "Tickets resto",
                        valueB: "Aucun",
                        showSecondOffer: showSecondOffer,
                        backgroundColor: AppColors.backgroundGray
                    )
                }
            }
        }
        .background(AppColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

struct OfferColumn: View {
    let letter: String
    let category: String
    let color: Color
    let isVisible: Bool
    let onRemove: () -> Void
    let onAdd: () -> Void
    
    var body: some View {
        Group {
            if isVisible {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(AppColors.white)
                            .frame(width: 56, height: 56)
                        
                        Text(letter)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.primaryRed)
                    }
                    
                    Text(category)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(color)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .overlay(
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.white)
                            .frame(width: 20, height: 20)
                            .background(AppColors.primaryRed)
                            .clipShape(Circle())
                    }
                    .offset(x: 10, y: -10),
                    alignment: .topTrailing
                )
            } else {
                Button(action: onAdd) {
                    ZStack {
                        Circle()
                            .fill(AppColors.white)
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.primaryRed)
                    }
                }
            }
        }
    }
}

struct ComparisonRow: View {
    let label: String
    let valueA: String
    let valueB: String
    let showSecondOffer: Bool
    let backgroundColor: Color
    let valueAColor: Color?
    let valueBColor: Color?
    let isScore: Bool
    
    init(label: String, valueA: String, valueB: String, showSecondOffer: Bool, backgroundColor: Color, valueAColor: Color? = nil, valueBColor: Color? = nil, isScore: Bool = false) {
        self.label = label
        self.valueA = valueA
        self.valueB = valueB
        self.showSecondOffer = showSecondOffer
        self.backgroundColor = backgroundColor
        self.valueAColor = valueAColor
        self.valueBColor = valueBColor
        self.isScore = isScore
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
            
            Text(valueA)
                .font(.system(size: isScore ? 16 : 13, weight: isScore ? .bold : .medium))
                .foregroundColor(valueAColor ?? AppColors.black)
                .frame(maxWidth: .infinity, alignment: .center)
            
            if showSecondOffer {
                Text(valueB)
                    .font(.system(size: isScore ? 16 : 13, weight: isScore ? .bold : .medium))
                    .foregroundColor(valueBColor ?? AppColors.black)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(height: 50)
        .background(backgroundColor)
    }
}

struct SectionHeader: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(AppColors.primaryRed)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.backgroundGray)
    }
}

#Preview {
    OfferComparisonView()
}
