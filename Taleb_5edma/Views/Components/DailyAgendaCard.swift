//
//  DailyAgendaCard.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Modèle pour un événement du jour
struct DailyEvent: Identifiable {
    let id: String
    let title: String
    let time: String
    let type: EventType
    let location: String?
    
    enum EventType {
        case job
        case course
        case deadline
        
        var color: Color {
            switch self {
            case .job: return AppColors.successGreen
            case .course: return AppColors.darkGray
            case .deadline: return AppColors.primaryRed
            }
        }
        
        var icon: String {
            switch self {
            case .job: return "briefcase.fill"
            case .course: return "book.fill"
            case .deadline: return "exclamationmark.triangle.fill"
            }
        }
    }
}

/// Card agenda listant les événements du jour
struct DailyAgendaCard: View {
    let events: [DailyEvent]
    let onEventTap: (DailyEvent) -> Void
    
    var body: some View {
        GenericCard {
            VStack(alignment: .leading, spacing: 12) {
                // En-tête
                HStack {
                    Text("Aujourd'hui")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.black)
                    
                    Spacer()
                    
                    // Badge de charge de travail
                    if !events.isEmpty {
                        WorkloadBadge(count: events.count)
                    }
                }
                
                if events.isEmpty {
                    Text("Aucun événement aujourd'hui")
                        .font(.subheadline)
                        .foregroundColor(AppColors.mediumGray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    // Liste des événements
                    VStack(spacing: 12) {
                        ForEach(events) { event in
                            DailyEventRow(event: event) {
                                onEventTap(event)
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Badge indiquant la charge de travail
struct WorkloadBadge: View {
    let count: Int
    
    private var badgeColor: Color {
        switch count {
        case 0...2: return AppColors.successGreen
        case 3...4: return .orange
        default: return AppColors.primaryRed
        }
    }
    
    var body: some View {
        Text("\(count) événement\(count > 1 ? "s" : "")")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .cornerRadius(8)
    }
}

/// Ligne d'événement cliquable pour l'agenda du jour
struct DailyEventRow: View {
    let event: DailyEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icône colorée
                Image(systemName: event.type.icon)
                    .font(.title3)
                    .foregroundColor(event.type.color)
                    .frame(width: 32)
                
                // Informations
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.black)
                    
                    HStack(spacing: 8) {
                        Text(event.time)
                            .font(.caption)
                            .foregroundColor(AppColors.primaryRed)
                        
                        if let location = event.location {
                            Text("•")
                                .foregroundColor(AppColors.mediumGray)
                            Text(location)
                                .font(.caption)
                                .foregroundColor(AppColors.mediumGray)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.mediumGray)
            }
            .padding()
            .background(event.type.color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        DailyAgendaCard(
            events: [
                DailyEvent(
                    id: "1",
                    title: "Assistant de chantier",
                    time: "09:00 - 13:00",
                    type: .job,
                    location: "Centre ville Tunis"
                ),
                DailyEvent(
                    id: "2",
                    title: "Mathématiques",
                    time: "14:00 - 16:00",
                    type: .course,
                    location: "Salle A101"
                ),
                DailyEvent(
                    id: "3",
                    title: "Deadline Projet",
                    time: "23:59",
                    type: .deadline,
                    location: nil
                )
            ],
            onEventTap: { _ in }
        )
    }
    .padding()
    .background(AppColors.backgroundGray)
}

