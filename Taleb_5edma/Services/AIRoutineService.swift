//
//  AIRoutineService.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import Foundation

/// Service d'IA pour analyser et suggérer une routine équilibrée
/// Utilise Google Gemini Pro via le backend, avec fallback sur analyse locale
class AIRoutineService {
    
    // MARK: - Properties
    
    private let baseURL: String = APIConfig.baseURL
    
    /// Session URL pour les requêtes réseau
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        return URLSession(configuration: configuration)
    }()
    
    /// Token d'authentification
    private var authToken: String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    /// Indique si on doit utiliser le backend (true) ou l'analyse locale (false)
    var useBackend: Bool = true
    
    // MARK: - Analyse de Routine
    
    /// Analyse la routine de l'utilisateur et génère des recommandations
    /// Essaie d'abord le backend (Gemini), puis fallback sur analyse locale
    func analyserRoutine(
        evenements: [Evenement],
        disponibilites: [Disponibilite],
        preferences: UserPreferences?,
        dateDebut: Date = Date(),
        dateFin: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
        manualActivityHours: Double = 0.0
    ) async throws -> RoutineBalance {
        
        // Essayer d'abord le backend (Gemini)
        if useBackend {
            do {
                return try await analyserRoutineBackend(
                    evenements: evenements,
                    disponibilites: disponibilites,
                    preferences: preferences,
                    dateDebut: dateDebut,
                    dateFin: dateFin,
                    manualActivityHours: manualActivityHours
                )
            } catch {
                print("⚠️ AIRoutineService - Erreur backend, fallback sur analyse locale: \(error.localizedDescription)")
                // Fallback sur analyse locale
                return try analyserRoutineLocale(
                    evenements: evenements,
                    disponibilites: disponibilites,
                    preferences: preferences,
                    dateDebut: dateDebut,
                    dateFin: dateFin,
                    manualActivityHours: manualActivityHours
                )
            }
        } else {
            // Utiliser directement l'analyse locale
            return try analyserRoutineLocale(
                evenements: evenements,
                disponibilites: disponibilites,
                preferences: preferences,
                dateDebut: dateDebut,
                dateFin: dateFin,
                manualActivityHours: manualActivityHours
            )
        }
    }
    
    // MARK: - Analyse via Backend (Gemini)
    
    /// Analyse la routine via le backend qui utilise Google Gemini Pro
    private func analyserRoutineBackend(
        evenements: [Evenement],
        disponibilites: [Disponibilite],
        preferences: UserPreferences?,
        dateDebut: Date,
        dateFin: Date,
        manualActivityHours: Double = 0.0
    ) async throws -> RoutineBalance {
        
        // Préparer les données
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Convertir les événements et disponibilités en DTOs simplifiés
        let evenementsDTOs = evenements.map { EvenementDTO(from: $0) }
        let disponibilitesDTOs = disponibilites.map { DisponibiliteDTO(from: $0) }
        
        let inputData = RoutineInputData(
            evenements: evenementsDTOs,
            disponibilites: disponibilitesDTOs,
            preferences: preferences,
            dateDebut: dateFormatter.string(from: dateDebut),
            dateFin: dateFormatter.string(from: dateFin)
        )
        
        print("🟢 AIRoutineService - Préparation données:")
        print("   - \(evenementsDTOs.count) événements")
        print("   - \(disponibilitesDTOs.count) disponibilités")
        print("   - Préférences: \(preferences != nil ? "présentes" : "absentes")")
        print("   - Période: \(dateFormatter.string(from: dateDebut)) → \(dateFormatter.string(from: dateFin))")
        
        // Appeler le backend
        guard let url = URL(string: APIConfig.analyzeRoutineEndpoint) else {
            throw AIError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Ajouter le token d'authentification
        guard let token = authToken else {
            throw AIError.notAuthenticated
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Encoder les données
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // Logger les données envoyées pour debug
        do {
            let jsonData = try encoder.encode(inputData)
            request.httpBody = jsonData
            
            // Logger le JSON envoyé (pour debug) - formaté pour lisibilité
            if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let prettyJson = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyJson, encoding: .utf8) {
                print("🟢 AIRoutineService - Données envoyées (formatées):")
                print(prettyString)
            } else if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🟢 AIRoutineService - Données envoyées: \(jsonString)")
            }
            
            print("🟢 AIRoutineService - Appel backend Gemini: \(url.absoluteString)")
            print("🟢 AIRoutineService - \(evenementsDTOs.count) événements, \(disponibilitesDTOs.count) disponibilités")
        } catch {
            print("🔴 AIRoutineService - Erreur encodage: \(error.localizedDescription)")
            if let encodingError = error as? EncodingError {
                print("🔴 Détails encodage: \(encodingError)")
            }
            throw AIError.invalidResponse
        }
        
        // Faire la requête
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Gérer les erreurs
            let errorMessage = String(data: data, encoding: .utf8) ?? "Erreur serveur"
            print("🔴 AIRoutineService - Erreur serveur (\(httpResponse.statusCode)): \(errorMessage)")
            
            // Logger les détails de l'erreur pour debug
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔴 Détails erreur: \(errorJson)")
                if let errors = errorJson["errors"] as? [[String: Any]] {
                    for error in errors {
                        print("🔴   - \(error)")
                    }
                }
            }
            
            if httpResponse.statusCode == 401 {
                throw AIError.notAuthenticated
            } else if httpResponse.statusCode == 429 {
                throw AIError.rateLimitExceeded
            } else {
                throw AIError.serverError(httpResponse.statusCode)
            }
        }
        
        // Décoder la réponse
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            // La réponse peut être dans un wrapper { success: true, data: {...} }
            if let wrapper = try? decoder.decode(AIResponseWrapper.self, from: data) {
                print("✅ AIRoutineService - Analyse Gemini réussie")
                return wrapper.data
            } else {
                // Ou directement RoutineBalance
                let balance = try decoder.decode(RoutineBalance.self, from: data)
                print("✅ AIRoutineService - Analyse Gemini réussie")
                return balance
            }
        } catch {
            print("🔴 AIRoutineService - Erreur décodage: \(error.localizedDescription)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔴 Réponse serveur: \(responseString)")
            }
            throw AIError.decodingError
        }
    }
    
    // MARK: - Analyse Locale (Fallback)
    
    /// Analyse locale avec algorithmes (fallback si backend indisponible)
    private func analyserRoutineLocale(
        evenements: [Evenement],
        disponibilites: [Disponibilite],
        preferences: UserPreferences?,
        dateDebut: Date,
        dateFin: Date,
        manualActivityHours: Double = 0.0
    ) throws -> RoutineBalance {
        
        // Calculer les statistiques hebdomadaires
        let analyseHebdo = calculerAnalyseHebdomadaire(
            evenements: evenements,
            dateDebut: dateDebut,
            dateFin: dateFin,
            manualActivityHours: manualActivityHours
        )
        
        // Générer les recommandations
        let recommandations = genererRecommandations(
            analyseHebdo: analyseHebdo,
            evenements: evenements,
            disponibilites: disponibilites,
            preferences: preferences
        )
        
        // Générer les suggestions d'optimisation
        let suggestions = genererSuggestionsOptimisation(
            evenements: evenements,
            disponibilites: disponibilites,
            analyseHebdo: analyseHebdo
        )
        
        // Calculer le score d'équilibre
        let score = calculerScoreEquilibre(analyseHebdo: analyseHebdo)
        
        return RoutineBalance(
            id: UUID().uuidString,
            dateAnalyse: Date(),
            scoreEquilibre: score,
            recommandations: recommandations,
            analyseHebdomadaire: analyseHebdo,
            suggestionsOptimisation: suggestions
        )
    }
    
    // MARK: - Calculs d'Analyse
    
    /// Calcule l'analyse hebdomadaire des activités
    private func calculerAnalyseHebdomadaire(
        evenements: [Evenement],
        dateDebut: Date,
        dateFin: Date,
        manualActivityHours: Double = 0.0
    ) -> AnalyseHebdomadaire {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Normaliser les dates de début et fin (enlever l'heure pour la comparaison)
        let calendar = Calendar.current
        let dateDebutNormalisee = calendar.startOfDay(for: dateDebut)
        let dateFinNormalisee = calendar.startOfDay(for: dateFin)
        
        print("🟢 AIRoutineService - Filtrage événements:")
        print("   - Date début: \(dateFormatter.string(from: dateDebutNormalisee))")
        print("   - Date fin: \(dateFormatter.string(from: dateFinNormalisee))")
        print("   - Total événements: \(evenements.count)")
        
        // Filtrer les événements dans la plage de dates
        let evenementsFiltres = evenements.filter { evenement in
            guard let eventDate = dateFormatter.date(from: evenement.date) else {
                print("⚠️ Événement \(evenement.titre) - Date invalide: \(evenement.date)")
                return false
            }
            let eventDateNormalisee = calendar.startOfDay(for: eventDate)
            let isInRange = eventDateNormalisee >= dateDebutNormalisee && eventDateNormalisee <= dateFinNormalisee
            print("   - Événement '\(evenement.titre)' (\(evenement.date)): \(isInRange ? "✅ inclus" : "❌ exclu")")
            return isInRange
        }
        
        var heuresTravail: Double = 0
        var heuresEtudes: Double = 0
        var heuresRepos: Double = 0
        var heuresActivites: Double = 0
        
        // Analyser chaque événement réel de l'utilisateur
        print("🟢 AIRoutineService - Analyse de \(evenementsFiltres.count) événements réels")
        
        for evenement in evenementsFiltres {
            let duree = calculerDureeHeures(heureDebut: evenement.heureDebut, heureFin: evenement.heureFin)
            
            // Utiliser le type réel de l'événement
            let typeNormalise = evenement.type.lowercased().trimmingCharacters(in: .whitespaces)
            
            print("  📅 Événement: \(evenement.titre) - Type: \(typeNormalise) - Durée: \(String(format: "%.1f", duree))h")
            
            switch typeNormalise {
            case "job":
                heuresTravail += duree
            case "cours":
                heuresEtudes += duree
            case "deadline":
                // Les deadlines comptent pour moitié études, moitié travail
                heuresEtudes += duree * 0.5
                heuresTravail += duree * 0.5
            default:
                // Tout autre type est considéré comme activité personnelle
                heuresActivites += duree
            }
        }
        
        // Ajouter les heures d'activités manuelles
        heuresActivites += manualActivityHours
        
        print("🟢 AIRoutineService - Total calculé: Travail=\(String(format: "%.1f", heuresTravail))h, Études=\(String(format: "%.1f", heuresEtudes))h, Activités=\(String(format: "%.1f", heuresActivites))h (dont \(String(format: "%.1f", manualActivityHours))h manuelles)")
        
        // Calculer les heures de repos (temps libre)
        let heuresTotales = heuresTravail + heuresEtudes + heuresActivites
        let heuresDisponibles = 16.0 * 7.0 // 16 heures par jour sur 7 jours (en excluant le sommeil)
        heuresRepos = max(0, heuresDisponibles - heuresTotales)
        
        let total = heuresTravail + heuresEtudes + heuresRepos + heuresActivites
        
        let repartition = AnalyseHebdomadaire.RepartitionActivites(
            pourcentageTravail: total > 0 ? (heuresTravail / total) * 100 : 0,
            pourcentageEtudes: total > 0 ? (heuresEtudes / total) * 100 : 0,
            pourcentageRepos: total > 0 ? (heuresRepos / total) * 100 : 0,
            pourcentageActivites: total > 0 ? (heuresActivites / total) * 100 : 0
        )
        
        return AnalyseHebdomadaire(
            heuresTravail: heuresTravail,
            heuresEtudes: heuresEtudes,
            heuresRepos: heuresRepos,
            heuresActivites: heuresActivites,
            heuresTotales: total,
            repartition: repartition
        )
    }
    
    /// Calcule la durée en heures entre deux heures
    /// Gère le cas où l'heure de fin est le lendemain (ex: 23:00 → 02:00)
    private func calculerDureeHeures(heureDebut: String, heureFin: String) -> Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let debutComponents = parseTimeComponents(heureDebut),
              let finComponents = parseTimeComponents(heureFin) else {
            print("⚠️ Calcul durée - Format invalide: \(heureDebut) → \(heureFin)")
            return 0
        }
        
        let debutMinutes = debutComponents.heure * 60 + debutComponents.minute
        var finMinutes = finComponents.heure * 60 + finComponents.minute
        
        // Si l'heure de fin est avant l'heure de début, c'est le lendemain
        if finMinutes < debutMinutes {
            finMinutes += 24 * 60 // Ajouter 24 heures
        }
        
        let dureeMinutes = finMinutes - debutMinutes
        let dureeHeures = Double(dureeMinutes) / 60.0
        
        print("   ⏱️ Durée calculée: \(heureDebut) → \(heureFin) = \(String(format: "%.2f", dureeHeures))h")
        
        return max(0, dureeHeures)
    }
    
    /// Parse les composants d'une heure (HH:mm)
    private func parseTimeComponents(_ timeString: String) -> (heure: Int, minute: Int)? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let heure = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        return (heure: heure, minute: minute)
    }
    
    // MARK: - Génération de Recommandations
    
    /// Génère des recommandations basées sur l'analyse
    private func genererRecommandations(
        analyseHebdo: AnalyseHebdomadaire,
        evenements: [Evenement],
        disponibilites: [Disponibilite],
        preferences: UserPreferences?
    ) -> [Recommandation] {
        
        var recommandations: [Recommandation] = []
        
        // Recommandation sur le travail
        if analyseHebdo.repartition.pourcentageTravail > 50 {
            recommandations.append(Recommandation(
                id: UUID().uuidString,
                type: .travail,
                titre: "Trop d'heures de travail",
                description: "Vous consacrez \(String(format: "%.1f", analyseHebdo.repartition.pourcentageTravail))% de votre temps au travail. Pensez à équilibrer avec vos études et votre repos.",
                priorite: .haute,
                actionSuggeree: "Réduire les heures de travail ou les répartir différemment"
            ))
        } else if analyseHebdo.repartition.pourcentageTravail < 10 && analyseHebdo.heuresTravail < 5 {
            recommandations.append(Recommandation(
                id: UUID().uuidString,
                type: .travail,
                titre: "Peu d'heures de travail",
                description: "Vous avez peu d'heures de travail cette semaine. C'est l'occasion de vous concentrer sur vos études.",
                priorite: .basse,
                actionSuggeree: nil
            ))
        }
        
        // Recommandation sur les études
        if analyseHebdo.repartition.pourcentageEtudes < 20 {
            recommandations.append(Recommandation(
                id: UUID().uuidString,
                type: .etudes,
                titre: "Temps d'étude insuffisant",
                description: "Vous ne consacrez que \(String(format: "%.1f", analyseHebdo.repartition.pourcentageEtudes))% de votre temps aux études. Pensez à augmenter votre temps de révision.",
                priorite: .haute,
                actionSuggeree: "Planifier plus de sessions d'étude"
            ))
        }
        
        // Recommandation sur le repos
        if analyseHebdo.repartition.pourcentageRepos < 30 {
            recommandations.append(Recommandation(
                id: UUID().uuidString,
                type: .repos,
                titre: "Manque de repos",
                description: "Vous avez seulement \(String(format: "%.1f", analyseHebdo.repartition.pourcentageRepos))% de temps libre. Le repos est essentiel pour maintenir votre équilibre.",
                priorite: .haute,
                actionSuggeree: "Planifier des moments de détente et de repos"
            ))
        }
        
        // Recommandation sur les activités personnelles
        if analyseHebdo.repartition.pourcentageActivites < 5 {
            recommandations.append(Recommandation(
                id: UUID().uuidString,
                type: .activites,
                titre: "Activités personnelles limitées",
                description: "Pensez à inclure des activités que vous aimez dans votre planning pour maintenir votre motivation.",
                priorite: .moyenne,
                actionSuggeree: "Ajouter des activités personnelles à votre calendrier"
            ))
        }
        
        // Recommandation sur la santé
        // Calculer uniquement les heures d'activités (sans le repos)
        let heuresActivitesTotales = analyseHebdo.heuresTravail + analyseHebdo.heuresEtudes + analyseHebdo.heuresActivites
        if heuresActivitesTotales > 80 {
            recommandations.append(Recommandation(
                id: UUID().uuidString,
                type: .sante,
                titre: "Planning très chargé",
                description: "Vous avez \(String(format: "%.1f", heuresActivitesTotales)) heures d'activités cette semaine. Assurez-vous de bien dormir et de prendre soin de votre santé.",
                priorite: .haute,
                actionSuggeree: "Réduire la charge ou mieux répartir les activités"
            ))
        }
        
        // Recommandation sur l'optimisation
        if disponibilites.isEmpty {
            recommandations.append(Recommandation(
                id: UUID().uuidString,
                type: .optimisation,
                titre: "Définir vos disponibilités",
                description: "Définir vos disponibilités permettra à l'application de mieux vous suggérer des offres adaptées.",
                priorite: .moyenne,
                actionSuggeree: "Ajouter vos disponibilités dans l'onglet 'Dispo'"
            ))
        }
        
        return recommandations
    }
    
    // MARK: - Génération de Suggestions d'Optimisation
    
    /// Génère des suggestions d'optimisation du planning
    private func genererSuggestionsOptimisation(
        evenements: [Evenement],
        disponibilites: [Disponibilite],
        analyseHebdo: AnalyseHebdomadaire
    ) -> [SuggestionOptimisation] {
        
        var suggestions: [SuggestionOptimisation] = []
        
        // Analyser les jours surchargés
        // Calculer les heures par jour en tenant compte des événements qui passent minuit
        var heuresParJour: [String: Double] = [:]
        
        for event in evenements {
            let dureeTotale = calculerDureeHeures(heureDebut: event.heureDebut, heureFin: event.heureFin)
            
            // Vérifier si l'événement passe minuit
            let debutComponents = parseTimeComponents(event.heureDebut)
            let finComponents = parseTimeComponents(event.heureFin)
            
            guard let debut = debutComponents, let fin = finComponents else { continue }
            
            let debutMinutes = debut.heure * 60 + debut.minute
            let finMinutes = fin.heure * 60 + fin.minute
            let passeMinuit = finMinutes < debutMinutes
            
            if passeMinuit {
                // L'événement passe minuit : diviser entre deux jours
                // Partie du jour de début : de l'heure de début à 23:59
                let minutesJourDebut = (23 * 60 + 59) - debutMinutes + 1 // +1 pour inclure la minute 23:59
                let heuresJourDebut = Double(minutesJourDebut) / 60.0
                
                // Partie du jour suivant : de 00:00 à l'heure de fin
                let minutesJourSuivant = finMinutes
                let heuresJourSuivant = Double(minutesJourSuivant) / 60.0
                
                // Ajouter au jour de début
                heuresParJour[event.date, default: 0.0] += heuresJourDebut
                
                // Calculer la date du jour suivant
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let dateDebut = dateFormatter.date(from: event.date),
                   let dateSuivant = Calendar.current.date(byAdding: .day, value: 1, to: dateDebut) {
                    let dateSuivantString = dateFormatter.string(from: dateSuivant)
                    heuresParJour[dateSuivantString, default: 0.0] += heuresJourSuivant
                }
            } else {
                // L'événement ne passe pas minuit : tout le temps est dans le même jour
                heuresParJour[event.date, default: 0.0] += dureeTotale
            }
        }
        
        // Générer des suggestions pour les jours surchargés
        for (date, heuresJour) in heuresParJour {
            // Limiter à 24 heures maximum (un jour ne peut pas avoir plus de 24h)
            let heuresLimitees = min(heuresJour, 24.0)
            
            if heuresLimitees > 10 {
                suggestions.append(SuggestionOptimisation(
                    id: UUID().uuidString,
                    jour: formaterDate(date),
                    type: .deplacement,
                    description: "Ce jour est très chargé avec \(String(format: "%.1f", heuresLimitees)) heures d'activités. Considérez déplacer certaines activités.",
                    avantage: "Réduire la fatigue et améliorer la productivité",
                    impact: .positif
                ))
            }
        }
        
        // Suggérer des pauses si nécessaire
        if analyseHebdo.repartition.pourcentageRepos < 25 {
            suggestions.append(SuggestionOptimisation(
                id: UUID().uuidString,
                jour: "Cette semaine",
                type: .pause,
                description: "Ajoutez des pauses régulières entre vos activités pour maintenir votre énergie.",
                avantage: "Améliorer la concentration et réduire le stress",
                impact: .tresPositif
            ))
        }
        
        // Suggérer le regroupement d'activités similaires
        let evenementsParType = Dictionary(grouping: evenements) { $0.type }
        for (type, events) in evenementsParType where events.count > 3 {
            suggestions.append(SuggestionOptimisation(
                id: UUID().uuidString,
                jour: "Cette semaine",
                type: .regroupement,
                description: "Vous avez \(events.count) événements de type '\(type)'. Regroupez-les si possible pour optimiser votre temps.",
                avantage: "Réduire les transitions et améliorer l'efficacité",
                impact: .positif
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Calcul du Score d'Équilibre
    
    /// Calcule un score d'équilibre de 0 à 100
    private func calculerScoreEquilibre(analyseHebdo: AnalyseHebdomadaire) -> Double {
        var score: Double = 100
        
        // Pénalités pour déséquilibres
        let repartition = analyseHebdo.repartition
        
        // Travail excessif
        if repartition.pourcentageTravail > 50 {
            score -= 20
        } else if repartition.pourcentageTravail > 40 {
            score -= 10
        }
        
        // Études insuffisantes
        if repartition.pourcentageEtudes < 20 {
            score -= 15
        } else if repartition.pourcentageEtudes < 30 {
            score -= 5
        }
        
        // Repos insuffisant
        if repartition.pourcentageRepos < 25 {
            score -= 20
        } else if repartition.pourcentageRepos < 30 {
            score -= 10
        }
        
        // Activités personnelles insuffisantes
        if repartition.pourcentageActivites < 5 {
            score -= 10
        }
        
        // Charge totale excessive (uniquement les heures d'activités, sans le repos)
        let heuresActivitesTotales = analyseHebdo.heuresTravail + analyseHebdo.heuresEtudes + analyseHebdo.heuresActivites
        if heuresActivitesTotales > 80 {
            score -= 15
        } else if heuresActivitesTotales > 70 {
            score -= 5
        }
        
        // Bonus pour équilibre
        if repartition.pourcentageTravail >= 20 && repartition.pourcentageTravail <= 40 &&
           repartition.pourcentageEtudes >= 25 && repartition.pourcentageEtudes <= 40 &&
           repartition.pourcentageRepos >= 30 && repartition.pourcentageRepos <= 50 {
            score += 10
        }
        
        return max(0, min(100, score))
    }
    
    // MARK: - Helpers
    
    private func formaterDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale(identifier: "fr_FR")
            displayFormatter.dateFormat = "EEEE d MMMM"
            return displayFormatter.string(from: date).capitalized
        }
        
        return dateString
    }
}

