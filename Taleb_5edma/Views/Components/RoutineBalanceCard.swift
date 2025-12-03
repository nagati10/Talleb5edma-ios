//
//  RoutineBalanceCard.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Carte compacte affichant un résumé de l'analyse de routine équilibrée
struct RoutineBalanceCard: View {
    @ObservedObject var viewModel: RoutineBalanceViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.primaryRed)
                        
                        Text("Équilibre de vie")
                            .font(.headline)
                            .foregroundColor(AppColors.black)
                    }
                    
                    Spacer()
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.mediumGray)
                    }
                }
                
                if let balance = viewModel.routineBalance {
                    // Score et niveau
                    HStack(spacing: 16) {
                        // Score circulaire
                        ZStack {
                            Circle()
                                .stroke(viewModel.couleurScore.opacity(0.2), lineWidth: 6)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(balance.scoreEquilibre / 100))
                                .stroke(viewModel.couleurScore, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(balance.scoreEquilibre))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(viewModel.couleurScore)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.niveauEquilibre)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.couleurScore)
                            
                            Text("\(balance.recommandations.count) recommandations")
                                .font(.caption)
                                .foregroundColor(AppColors.mediumGray)
                        }
                        
                        Spacer()
                    }
                    
                    // Mini répartition
                    HStack(spacing: 4) {
                        // Travail
                        if balance.analyseHebdomadaire.repartition.pourcentageTravail > 0 {
                            Rectangle()
                                .fill(AppColors.primaryRed)
                                .frame(height: 8)
                                .frame(maxWidth: .infinity)
                        }
                        
                        // Études
                        if balance.analyseHebdomadaire.repartition.pourcentageEtudes > 0 {
                            Rectangle()
                                .fill(Color(hex: "#3498DB"))
                                .frame(height: 8)
                                .frame(maxWidth: .infinity)
                        }
                        
                        // Repos
                        if balance.analyseHebdomadaire.repartition.pourcentageRepos > 0 {
                            Rectangle()
                                .fill(Color(hex: "#2ECC71"))
                                .frame(height: 8)
                                .frame(maxWidth: .infinity)
                        }
                        
                        // Activités
                        if balance.analyseHebdomadaire.repartition.pourcentageActivites > 0 {
                            Rectangle()
                                .fill(Color(hex: "#F39C12"))
                                .frame(height: 8)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .cornerRadius(4)
                    .frame(height: 8)
                } else {
                    // État vide
                    HStack {
                        Text("Analysez votre routine pour obtenir des recommandations personnalisées")
                            .font(.subheadline)
                            .foregroundColor(AppColors.mediumGray)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.primaryRed)
                    }
                }
            }
            .padding()
            .background(AppColors.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RoutineBalanceCard(
        viewModel: RoutineBalanceViewModel(),
        onTap: {}
    )
    .padding()
    .background(AppColors.backgroundGray)
}

