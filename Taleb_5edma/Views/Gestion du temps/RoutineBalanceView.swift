//
//  RoutineBalanceView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

/// Vue principale pour afficher l'analyse de routine équilibrée par IA
struct RoutineBalanceView: View {
    @StateObject private var viewModel: RoutineBalanceViewModel
    @State private var showingDetails = false
    @State private var showingManualHours = false
    
    let evenementViewModel: EvenementViewModel
    let availabilityViewModel: AvailabilityViewModel
    
    init(
        evenementViewModel: EvenementViewModel,
        availabilityViewModel: AvailabilityViewModel
    ) {
        self.evenementViewModel = evenementViewModel
        self.availabilityViewModel = availabilityViewModel
        _viewModel = StateObject(wrappedValue: RoutineBalanceViewModel())
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGray
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header avec score
                    headerSection
                    
                    // Analyse hebdomadaire
                    if let balance = viewModel.routineBalance {
                        analyseSection(balance: balance)
                        
                        // Recommandations
                        recommandationsSection(recommandations: balance.recommandations)
                        
                        // Suggestions d'optimisation
                        suggestionsSection(suggestions: balance.suggestionsOptimisation)
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Mettre à jour les références (déclenchera les observers)
            viewModel.evenementViewModel = evenementViewModel
            viewModel.availabilityViewModel = availabilityViewModel
            
            Task {
                // Toujours recharger les données pour avoir les dernières
                await evenementViewModel.loadEvenements()
                await availabilityViewModel.loadDisponibilites()
                
                // Lancer l'analyse avec les données réelles
                await viewModel.analyserRoutine(
                    evenements: evenementViewModel.evenements,
                    disponibilites: availabilityViewModel.disponibilites
                )
            }
        }
        .onChange(of: evenementViewModel.evenements.count) { oldCount, newCount in
            // Recharger l'analyse quand le nombre d'événements change
            if newCount != oldCount {
                Task {
                    await viewModel.analyserRoutine(
                        evenements: evenementViewModel.evenements,
                        disponibilites: availabilityViewModel.disponibilites
                    )
                }
            }
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Équilibre de vie")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.black)
                    
                    Text("Analyse IA de votre routine")
                        .font(.subheadline)
                        .foregroundColor(AppColors.mediumGray)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.rechargerAnalyse()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primaryRed)
                        .padding(12)
                        .background(AppColors.primaryRed.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            if let balance = viewModel.routineBalance {
                ScoreCard(score: balance.scoreEquilibre, niveau: viewModel.niveauEquilibre, couleur: viewModel.couleurScore)
            } else if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(16)
    }
    
    // MARK: - Analyse Section
    
    private func analyseSection(balance: RoutineBalance) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Répartition hebdomadaire")
                    .font(.headline)
                    .foregroundColor(AppColors.black)
                
                Spacer()
                
                // Bouton pour ajouter/modifier les heures manuelles
                Button(action: {
                    showingManualHours = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.manualActivityHours > 0 ? "clock.badge.checkmark" : "clock.badge.plus")
                            .font(.system(size: 14))
                        Text(viewModel.manualActivityHours > 0 ? "\(String(format: "%.1f", viewModel.manualActivityHours))h" : "Ajouter")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#F39C12"))
                    .cornerRadius(8)
                }
            }
            
            // Graphique circulaire ou barres
            RepartitionChart(analyse: balance.analyseHebdomadaire)
            
            // Détails des heures
            VStack(spacing: 12) {
                StatRow(
                    label: "Travail",
                    value: String(format: "%.1f h", balance.analyseHebdomadaire.heuresTravail),
                    percentage: balance.analyseHebdomadaire.repartition.pourcentageTravail,
                    color: AppColors.primaryRed
                )
                
                StatRow(
                    label: "Études",
                    value: String(format: "%.1f h", balance.analyseHebdomadaire.heuresEtudes),
                    percentage: balance.analyseHebdomadaire.repartition.pourcentageEtudes,
                    color: Color(hex: "#3498DB")
                )
                
                StatRow(
                    label: "Repos",
                    value: String(format: "%.1f h", balance.analyseHebdomadaire.heuresRepos),
                    percentage: balance.analyseHebdomadaire.repartition.pourcentageRepos,
                    color: Color(hex: "#2ECC71")
                )
                
                StatRow(
                    label: "Activités",
                    value: String(format: "%.1f h", balance.analyseHebdomadaire.heuresActivites),
                    percentage: balance.analyseHebdomadaire.repartition.pourcentageActivites,
                    color: Color(hex: "#F39C12")
                )
                
                // Afficher les heures manuelles si elles existent
                if viewModel.manualActivityHours > 0 {
                    HStack {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#F39C12"))
                        
                        Text("Dont \(String(format: "%.1f", viewModel.manualActivityHours))h ajoutées manuellement")
                            .font(.caption)
                            .foregroundColor(AppColors.mediumGray)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(16)
        .sheet(isPresented: $showingManualHours) {
            ManualActivityHoursView(
                semaineDebut: getSemaineDebut(),
                heuresActuelles: viewModel.manualActivityHours
            ) { heures in
                viewModel.saveManualActivityHours(heures, for: getSemaineDebut())
            }
        }
    }
    
    // MARK: - Recommandations Section
    
    private func recommandationsSection(recommandations: [Recommandation]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommandations")
                .font(.headline)
                .foregroundColor(AppColors.black)
            
            if recommandations.isEmpty {
                Text("Aucune recommandation pour le moment. Votre routine est bien équilibrée !")
                    .font(.subheadline)
                    .foregroundColor(AppColors.mediumGray)
                    .padding()
            } else {
                ForEach(recommandations) { recommandation in
                    RecommandationCard(recommandation: recommandation)
                }
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(16)
    }
    
    // MARK: - Suggestions Section
    
    private func suggestionsSection(suggestions: [SuggestionOptimisation]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggestions d'optimisation")
                .font(.headline)
                .foregroundColor(AppColors.black)
            
            if suggestions.isEmpty {
                Text("Aucune suggestion d'optimisation pour le moment.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.mediumGray)
                    .padding()
            } else {
                ForEach(suggestions) { suggestion in
                    SuggestionCard(suggestion: suggestion)
                }
            }
        }
        .padding()
        .background(AppColors.white)
        .cornerRadius(16)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(AppColors.mediumGray)
            
            Text("Aucune analyse disponible")
                .font(.headline)
                .foregroundColor(AppColors.black)
            
            Text("Ajoutez des événements et disponibilités pour obtenir une analyse de votre routine.")
                .font(.subheadline)
                .foregroundColor(AppColors.mediumGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Helper Methods
    
    /// Calcule le lundi de la semaine actuelle au format "yyyy-MM-dd"
    private func getSemaineDebut() -> String {
        let calendar = Calendar.current
        let aujourdhui = Date()
        let components = calendar.dateComponents([.weekday, .yearForWeekOfYear, .weekOfYear], from: aujourdhui)
        let weekday = components.weekday ?? 1
        let joursDepuisLundi = (weekday == 1) ? -6 : (2 - weekday)
        let lundi = calendar.date(byAdding: .day, value: joursDepuisLundi, to: aujourdhui) ?? aujourdhui
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: lundi)
    }
}

// MARK: - Score Card

struct ScoreCard: View {
    let score: Double
    let niveau: String
    let couleur: Color
    
    var body: some View {
        HStack(spacing: 20) {
            // Cercle avec score
            ZStack {
                Circle()
                    .stroke(couleur.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score / 100))
                    .stroke(couleur, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(score))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(couleur)
                    Text("/100")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mediumGray)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Score d'équilibre")
                    .font(.subheadline)
                    .foregroundColor(AppColors.mediumGray)
                
                Text(niveau)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(couleur)
                
                Text(getDescription(score: score))
                    .font(.caption)
                    .foregroundColor(AppColors.mediumGray)
            }
            
            Spacer()
        }
    }
    
    private func getDescription(score: Double) -> String {
        if score >= 80 {
            return "Votre routine est bien équilibrée !"
        } else if score >= 60 {
            return "Bon équilibre, quelques améliorations possibles"
        } else if score >= 40 {
            return "Équilibre moyen, des ajustements recommandés"
        } else {
            return "Équilibre à améliorer, suivez les recommandations"
        }
    }
}

// MARK: - Repartition Chart

struct RepartitionChart: View {
    let analyse: AnalyseHebdomadaire
    
    var body: some View {
        HStack(spacing: 0) {
            // Barre de progression horizontale
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Travail
                    Rectangle()
                        .fill(AppColors.primaryRed)
                        .frame(width: geometry.size.width * CGFloat(analyse.repartition.pourcentageTravail / 100))
                    
                    // Études
                    Rectangle()
                        .fill(Color(hex: "#3498DB"))
                        .frame(width: geometry.size.width * CGFloat(analyse.repartition.pourcentageEtudes / 100))
                    
                    // Repos
                    Rectangle()
                        .fill(Color(hex: "#2ECC71"))
                        .frame(width: geometry.size.width * CGFloat(analyse.repartition.pourcentageRepos / 100))
                    
                    // Activités
                    Rectangle()
                        .fill(Color(hex: "#F39C12"))
                        .frame(width: geometry.size.width * CGFloat(analyse.repartition.pourcentageActivites / 100))
                }
                .cornerRadius(8)
            }
            .frame(height: 20)
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.black)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.black)
            
            Text("\(String(format: "%.0f", percentage))%")
                .font(.caption)
                .foregroundColor(AppColors.mediumGray)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Recommandation Card

struct RecommandationCard: View {
    let recommandation: Recommandation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForType(recommandation.type))
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: recommandation.priorite.color))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommandation.titre)
                        .font(.headline)
                        .foregroundColor(AppColors.black)
                    
                    HStack {
                        Text(recommandation.type.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: recommandation.priorite.color).opacity(0.1))
                            .foregroundColor(Color(hex: recommandation.priorite.color))
                            .cornerRadius(4)
                        
                        Text(recommandation.priorite.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: recommandation.priorite.color).opacity(0.1))
                            .foregroundColor(Color(hex: recommandation.priorite.color))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
            }
            
            Text(recommandation.description)
                .font(.subheadline)
                .foregroundColor(AppColors.mediumGray)
            
            if let action = recommandation.actionSuggeree {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#F39C12"))
                    
                    Text(action)
                        .font(.caption)
                        .foregroundColor(AppColors.mediumGray)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(AppColors.backgroundGray)
        .cornerRadius(12)
    }
    
    private func iconForType(_ type: TypeRecommandation) -> String {
        switch type {
        case .travail: return "briefcase.fill"
        case .etudes: return "book.fill"
        case .repos: return "moon.fill"
        case .activites: return "heart.fill"
        case .sante: return "cross.case.fill"
        case .social: return "person.2.fill"
        case .optimisation: return "gearshape.fill"
        }
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let suggestion: SuggestionOptimisation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForType(suggestion.type))
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: suggestion.impact.color))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.jour)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.black)
                    
                    Text(suggestion.type.rawValue)
                        .font(.caption)
                        .foregroundColor(AppColors.mediumGray)
                }
                
                Spacer()
                
                Text(suggestion.impact.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: suggestion.impact.color).opacity(0.1))
                    .foregroundColor(Color(hex: suggestion.impact.color))
                    .cornerRadius(4)
            }
            
            Text(suggestion.description)
                .font(.subheadline)
                .foregroundColor(AppColors.mediumGray)
            
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#F39C12"))
                
                Text(suggestion.avantage)
                    .font(.caption)
                    .foregroundColor(AppColors.mediumGray)
            }
        }
        .padding()
        .background(AppColors.backgroundGray)
        .cornerRadius(12)
    }
    
    private func iconForType(_ type: TypeOptimisation) -> String {
        switch type {
        case .deplacement: return "arrow.left.arrow.right"
        case .ajout: return "plus.circle.fill"
        case .suppression: return "minus.circle.fill"
        case .regroupement: return "square.stack.3d.up.fill"
        case .pause: return "pause.circle.fill"
        }
    }
}

#Preview {
    RoutineBalanceView(
        evenementViewModel: EvenementViewModel(),
        availabilityViewModel: AvailabilityViewModel()
    )
}

