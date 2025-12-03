//
//  DonutChartView.swift
//  Taleb_5edma
//
//  Created by Apple on 16/11/2025.
//

import SwiftUI

/// Structure représentant un segment du graphique en donut
struct DonutSegment: Identifiable {
    let id = UUID()
    let value: Double
    let color: Color
    let label: String
}

/// Vue de graphique en donut pour afficher les statistiques d'heures de travail
/// Inspiré du design de l'écran "Activity"
struct DonutChartView: View {
    let segments: [DonutSegment]
    let centerText: String
    let centerSubtext: String
    let lineWidth: CGFloat
    
    init(
        segments: [DonutSegment],
        centerText: String,
        centerSubtext: String = "",
        lineWidth: CGFloat = 30
    ) {
        self.segments = segments
        self.centerText = centerText
        self.centerSubtext = centerSubtext
        self.lineWidth = lineWidth
    }
    
    private var totalValue: Double {
        segments.reduce(0) { $0 + $1.value }
    }
    
    private var angles: [Double] {
        var currentAngle: Double = -90 // Commencer en haut
        return segments.map { segment in
            let percentage = segment.value / totalValue
            let angle = currentAngle
            currentAngle += percentage * 360
            return angle
        }
    }
    
    var body: some View {
        ZStack {
            // Graphique en donut
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 - lineWidth / 2
                
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    let percentage = segment.value / totalValue
                    let startAngle = angles[index]
                    let endAngle = startAngle + (percentage * 360)
                    
                    Path { path in
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(startAngle),
                            endAngle: .degrees(endAngle),
                            clockwise: false
                        )
                    }
                    .stroke(segment.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                }
            }
            
            // Texte au centre
            VStack(spacing: 4) {
                Text(centerText)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.darkerGray)
                
                if !centerSubtext.isEmpty {
                    Text(centerSubtext)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mediumGray)
                }
            }
        }
    }
}

/// Card complète avec le graphique en donut et les statistiques
struct WorkStatsCard: View {
    let jobsHours: Double
    let coursesHours: Double
    let otherHours: Double
    let totalHours: Double
    
    @State private var selectedMonth: String = "Mois"
    
    private var segments: [DonutSegment] {
        var segs: [DonutSegment] = []
        
        if jobsHours > 0 {
            segs.append(DonutSegment(
                value: jobsHours,
                color: AppColors.primaryRed,
                label: "Travail"
            ))
        }
        
        if coursesHours > 0 {
            segs.append(DonutSegment(
                value: coursesHours,
                color: AppColors.accentBlue,
                label: "Cours"
            ))
        }
        
        if otherHours > 0 {
            segs.append(DonutSegment(
                value: otherHours,
                color: AppColors.mediumGray,
                label: "Autre"
            ))
        }
        
        return segs
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header avec sélecteur de mois
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heures travaillées")
                        .font(.subheadline)
                        .foregroundColor(AppColors.mediumGray)
                    
                    Text("\(Int(totalHours))h")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.darkerGray)
                }
                
                Spacer()
                
                // Sélecteur de mois
                Menu {
                    Button("Janvier") { selectedMonth = "Janvier" }
                    Button("Février") { selectedMonth = "Février" }
                    Button("Mars") { selectedMonth = "Mars" }
                    Button("Avril") { selectedMonth = "Avril" }
                    Button("Mai") { selectedMonth = "Mai" }
                    Button("Juin") { selectedMonth = "Juin" }
                    Button("Juillet") { selectedMonth = "Juillet" }
                    Button("Août") { selectedMonth = "Août" }
                    Button("Septembre") { selectedMonth = "Septembre" }
                    Button("Octobre") { selectedMonth = "Octobre" }
                    Button("Novembre") { selectedMonth = "Novembre" }
                    Button("Décembre") { selectedMonth = "Décembre" }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedMonth)
                            .font(.subheadline)
                            .foregroundColor(AppColors.darkerGray)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.darkerGray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.lightGray, lineWidth: 1)
                    )
                }
            }
            
            // Graphique en donut
            DonutChartView(
                segments: segments,
                centerText: "\(Int(totalHours))h",
                centerSubtext: "Total"
            )
            .frame(height: 200)
            
            // Légende
            VStack(spacing: 12) {
                ForEach(segments) { segment in
                    HStack {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 12, height: 12)
                        
                        Text(segment.label)
                            .font(.subheadline)
                            .foregroundColor(AppColors.darkGray)
                        
                        Spacer()
                        
                        Text("\(Int(segment.value))h")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.darkerGray)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    AppColors.accentBlue.opacity(0.1),
                    AppColors.primaryRed.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    WorkStatsCard(
        jobsHours: 15,
        coursesHours: 5,
        otherHours: 2,
        totalHours: 22
    )
    .padding()
    .background(AppColors.backgroundGray)
}

