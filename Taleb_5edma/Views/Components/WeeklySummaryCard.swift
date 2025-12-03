//
//  WeeklySummaryCard.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Card de résumé hebdomadaire
/// Affiche le temps alloué aux jobs et cours avec barre de progression
struct WeeklySummaryCard: View {
    let jobsHours: Double
    let coursesHours: Double
    let maxHours: Double
    
    init(jobsHours: Double = 15, coursesHours: Double = 5, maxHours: Double = 20) {
        self.jobsHours = jobsHours
        self.coursesHours = coursesHours
        self.maxHours = maxHours
    }
    
    private var totalHours: Double {
        jobsHours + coursesHours
    }
    
    private var progressPercentage: Double {
        min(totalHours / maxHours, 1.0)
    }
    
    var body: some View {
        GenericCard {
            VStack(alignment: .leading, spacing: 16) {
                // Titre
                HStack {
                    Text("Résumé hebdomadaire")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.black)
                    
                    Spacer()
                    
                    Text("\(Int(totalHours))h/\(Int(maxHours))h")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryRed)
                }
                
                // Barre de progression globale
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.lightGray.opacity(0.3))
                            .frame(height: 12)
                        
                        // Progression
                        HStack(spacing: 0) {
                            // Partie Jobs (vert)
                            if jobsHours > 0 {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.successGreen)
                                    .frame(width: geometry.size.width * CGFloat(jobsHours / maxHours), height: 12)
                            }
                            
                            // Partie Cours
                            if coursesHours > 0 {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.darkGray)
                                    .frame(width: geometry.size.width * CGFloat(coursesHours / maxHours), height: 12)
                            }
                        }
                    }
                }
                .frame(height: 12)
                
                // Légende
                HStack(spacing: 20) {
                    Label("\(Int(jobsHours))h Jobs", systemImage: "briefcase.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.successGreen)
                    
                    Label("\(Int(coursesHours))h Cours", systemImage: "book.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.darkGray)
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    WeeklySummaryCard()
        .padding()
        .background(AppColors.backgroundGray)
}

