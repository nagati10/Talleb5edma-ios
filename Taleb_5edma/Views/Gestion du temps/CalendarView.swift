//
//  CalendarView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingCreateEvenement = false
    @State private var selectedEvenement: Evenement?
    @State private var showingDatePicker = false
    
    var body: some View {
            ZStack {
                AppColors.backgroundGray
                    .ignoresSafeArea()
                
            VStack(spacing: 0) {
                // Header avec mois et bouton ajouter
                headerSection
                
                // Calendrier horizontal compact
                horizontalCalendarSection
                
                // Timeline verticale avec événements
                timelineSection
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadAllData()
            }
        }
        .sheet(isPresented: $showingCreateEvenement) {
            CreateEvenementView(
                viewModel: viewModel.evenementViewModel,
                selectedDate: viewModel.selectedDate
            ) { createdDate in
                /// Recharger les événements après création
                /// 
                /// MODIFICATION : Rechargement explicite des événements après création pour garantir
                /// que la liste est à jour. Le Combine subscriber dans CalendarViewModel mettra aussi
                /// à jour refreshID, déclenchant un re-rendu du calendrier.
                Task {
                    await viewModel.evenementViewModel.loadEvenements()
                    // Mettre à jour la date sélectionnée si l'événement est créé pour un autre jour
                    if let createdDate = createdDate {
                        viewModel.selectedDate = createdDate
                    }
                }
            }
        }
        .sheet(item: $selectedEvenement) { evenement in
            EditEvenementView(
                evenement: evenement,
                viewModel: viewModel.evenementViewModel
            ) {
                // Recharger les événements après modification
                Task {
                    await viewModel.evenementViewModel.loadEvenements()
                }
            }
        }
        .alert("Erreur", isPresented: $viewModel.evenementViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.evenementViewModel.errorMessage ?? "Une erreur est survenue")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Bouton mois avec icône calendrier - Ouvre le sélecteur de date
            Button(action: {
                showingDatePicker = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                    Text(formatMonthYear(viewModel.currentMonth))
                        .font(.headline)
                        .foregroundColor(AppColors.black)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.white)
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Boutons de navigation mois précédent/suivant
            HStack(spacing: 12) {
                Button(action: {
                    changeMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.primaryRed)
                        .frame(width: 36, height: 36)
                        .background(AppColors.primaryRed.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    changeMonth(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.primaryRed)
                        .frame(width: 36, height: 36)
                        .background(AppColors.primaryRed.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Spacer()
            
            // Bouton ajouter événement
            Button(action: {
                showingCreateEvenement = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(AppColors.primaryRed)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.white)
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                VStack {
                    let calendar = Calendar.current
                    let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? Date()
                    let endDate = calendar.date(from: DateComponents(year: 2030, month: 12, day: 31)) ?? Date()
                    
                    DatePicker(
                        "Sélectionner une date",
                        selection: Binding(
                            get: { viewModel.currentMonth },
                            set: { newDate in
                                viewModel.currentMonth = newDate
                                viewModel.selectedDate = newDate
                            }
                        ),
                        in: startDate...endDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    
                    Spacer()
                }
                .navigationTitle("Sélectionner une date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Terminé") {
                            showingDatePicker = false
                            // Faire défiler vers la date sélectionnée après sélection
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.refreshID = UUID()
                            }
                        }
                        .foregroundColor(AppColors.primaryRed)
                    }
                }
            }
        }
    }
    
    private func changeMonth(by months: Int) {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: months, to: viewModel.currentMonth) {
            // Limiter à la plage 2025-2030
            let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? Date()
            let endDate = calendar.date(from: DateComponents(year: 2030, month: 12, day: 31)) ?? Date()
            
            if newMonth >= startDate && newMonth <= endDate {
                viewModel.currentMonth = newMonth
                // Mettre à jour la date sélectionnée vers le premier jour du nouveau mois
                if let firstDay = calendar.dateInterval(of: .month, for: newMonth)?.start {
                    viewModel.selectedDate = firstDay
                }
                // Forcer le rafraîchissement pour mettre à jour le scroll
                viewModel.refreshID = UUID()
            }
        }
    }
    
    // MARK: - Horizontal Calendar Section
    
    private var horizontalCalendarSection: some View {
        VStack(spacing: 12) {
            // Jours de la semaine
            HStack(spacing: 0) {
                ForEach(["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.mediumGray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
                    
            // Dates avec plusieurs semaines (passées et futures)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(daysInExtendedRange(), id: \.self) { date in
                            DayButton(
                                date: date,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                                hasEvents: !viewModel.getEvenementsForDate(date).isEmpty,
                                onTap: {
                                    viewModel.selectedDate = date
                                    // Faire défiler vers la date sélectionnée
                                    withAnimation {
                                        proxy.scrollTo(date, anchor: .center)
                                    }
                                }
                            )
                            .id(date)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                /// Utiliser refreshID pour forcer le re-rendu quand les événements changent
                /// 
                /// PROBLÈME RÉSOLU : Après création d'un événement, le calendrier ne se mettait pas à jour.
                /// 
                /// MODIFICATION : Le refreshID change quand la liste d'événements change (via Combine dans CalendarViewModel),
                /// forçant SwiftUI à re-rendre cette ScrollView et afficher les nouveaux événements.
                .id(viewModel.refreshID)
                .onAppear {
                    /// Faire défiler vers aujourd'hui au chargement initial
                    let today = Date()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(today, anchor: .center)
                        }
                    }
                }
                .onChange(of: viewModel.refreshID) { _, _ in
                    /// Faire défiler vers la date sélectionnée après rafraîchissement
                    /// Cela garantit que la vue reste synchronisée avec les données après création/modification d'événements
                    let selectedDate = viewModel.selectedDate
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(selectedDate, anchor: .center)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(AppColors.white)
    }
    
    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Titre "Aujourd'hui" ou date sélectionnée
                HStack {
                    Text(isToday(viewModel.selectedDate) ? "Aujourd'hui" : formatDate(viewModel.selectedDate))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.black)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.mediumGray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Timeline avec heures et événements
                timelineView
            }
        }
    }
    
    private var timelineView: some View {
        ZStack(alignment: .topLeading) {
            // Ligne de temps verticale
            VStack(spacing: 0) {
                ForEach(6..<24, id: \.self) { hour in
                    TimelineHourRow(hour: hour)
                }
            }
            .padding(.leading, 60)
            .padding(.trailing, 20)
            
            // Événements positionnés
            let events = viewModel.getEvenementsForDate(viewModel.selectedDate)
            ForEach(events) { evenement in
                EventTimelineCard(
                    evenement: evenement,
                    selectedDate: viewModel.selectedDate,
                    onTap: {
                        selectedEvenement = evenement
                    },
                    onDelete: {
                        Task {
                            _ = await viewModel.evenementViewModel.deleteEvenement(evenement.id)
                            await viewModel.evenementViewModel.loadEvenements()
                        }
                    }
                )
            }
        }
        .padding(.top, 8)
        .id(viewModel.refreshID)
    }
    
    // MARK: - Helper Methods
    
    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).capitalized
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private func daysInCurrentWeek() -> [Date] {
        let calendar = Calendar.current
        let today = viewModel.selectedDate
        guard let firstDay = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        
        var days: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
    
    /// Retourne une plage étendue de dates depuis 2025 jusqu'à 2030
    private func daysInExtendedRange() -> [Date] {
        let calendar = Calendar.current
        
        // Commencer au 1er janvier 2025
        var startComponents = DateComponents()
        startComponents.year = 2025
        startComponents.month = 1
        startComponents.day = 1
        guard let startDate = calendar.date(from: startComponents),
              let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start else {
            return daysInCurrentWeek()
        }
        
        // Finir au 31 décembre 2030
        var endComponents = DateComponents()
        endComponents.year = 2030
        endComponents.month = 12
        endComponents.day = 31
        guard let endDate = calendar.date(from: endComponents) else {
            return daysInCurrentWeek()
        }
        
        var days: [Date] = []
        var currentDate = startOfWeek
        
        // Générer tous les jours de la plage
        while currentDate <= endDate {
            days.append(currentDate)
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        return days
    }
}

// MARK: - Day Button

struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            // Jour de la semaine
            Text(dayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(dayNameColor)
            
            // Date
            Text("\(dayNumber)")
                .font(.system(size: 16, weight: isSelected ? .bold : (isPast ? .regular : .medium)))
                .foregroundColor(dateTextColor)
                .frame(width: 40, height: 40)
                .background(dateBackgroundColor)
                .clipShape(Circle())
                        .overlay(
                    Circle()
                        .stroke(dateBorderColor, lineWidth: isPast ? 0 : (isToday ? 2 : 1))
                )
            
            // Indicateur d'événements
            if hasEvents {
                Circle()
                    .fill(eventIndicatorColor)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(width: 50)
        .opacity(isPast ? 0.5 : 1.0) // Réduire l'opacité pour les dates passées
        .onTapGesture {
            onTap()
        }
    }
    
    // MARK: - Computed Properties
    
    private var isPast: Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isFuture: Bool {
        Calendar.current.startOfDay(for: date) > Calendar.current.startOfDay(for: Date())
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(3).uppercased()
    }
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    private var dayNameColor: Color {
        if isSelected {
            return AppColors.primaryRed
        } else if isPast {
            return AppColors.mediumGray.opacity(0.6)
        } else if isToday {
            return AppColors.primaryRed
        } else {
            return AppColors.mediumGray
        }
    }
    
    private var dateTextColor: Color {
        if isSelected {
            return .white
        } else if isPast {
            return AppColors.mediumGray
        } else if isToday {
            return AppColors.primaryRed
        } else {
            return AppColors.black
        }
    }
    
    private var dateBackgroundColor: Color {
        if isSelected {
            return AppColors.primaryRed
        } else if isToday {
            return AppColors.primaryRed.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var dateBorderColor: Color {
        if isSelected {
            return AppColors.primaryRed
        } else if isToday {
            return AppColors.primaryRed
        } else if isFuture {
            return AppColors.mediumGray.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var eventIndicatorColor: Color {
        if isSelected {
            return .white
        } else if isPast {
            return AppColors.mediumGray
        } else {
            return AppColors.primaryRed
        }
    }
}

// MARK: - Timeline Hour Row

struct TimelineHourRow: View {
    let hour: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Heure
            Text(String(format: "%02d:00", hour))
                .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.mediumGray)
                .frame(width: 50, alignment: .trailing)
            
            // Ligne horizontale
            Rectangle()
                .fill(AppColors.lightGray.opacity(0.3))
                .frame(height: 1)
                .padding(.top, 8)
        }
        .frame(height: 60)
    }
}

// MARK: - Event Timeline Card

struct EventTimelineCard: View {
    let evenement: Evenement
    let selectedDate: Date
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        let startTime = parseTime(evenement.heureDebut)
        let endTime = parseTime(evenement.heureFin)
        let duration = endTime - startTime
        let topOffset = CGFloat((startTime - 6) * 60) + CGFloat((startTime - 6) * 4)
        let height = CGFloat(duration * 60) + CGFloat((duration - 1) * 4)
        
        return HStack(alignment: .top, spacing: 12) {
            Spacer()
                .frame(width: 50)
            
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 12) {
                    // Barre de couleur verticale
                    RoundedRectangle(cornerRadius: 2)
                        .fill(eventColor)
                        .frame(width: 4)
                    
                    // Contenu de l'événement
                    VStack(alignment: .leading, spacing: 6) {
                        Text(evenement.titre)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(eventTextColor)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Label(evenement.heureDebut + " - " + evenement.heureFin, systemImage: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(eventSecondaryTextColor)
                            
                            if let lieu = evenement.lieu {
                                Label(lieu, systemImage: "location")
                                    .font(.system(size: 12))
                                    .foregroundColor(eventSecondaryTextColor)
                }
            }
                        
                        // Type
                        Text(evenement.type.capitalized)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(eventBadgeBackgroundColor)
                            .foregroundColor(eventBadgeTextColor)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    // Menu actions
                    Menu {
                        Button("Modifier", action: onTap)
                        Button("Supprimer", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundColor(eventSecondaryTextColor)
                            .padding(8)
                    }
                }
                .padding(12)
                .background(eventBackgroundColor)
                .cornerRadius(12)
                .shadow(color: eventShadowColor, radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.trailing, 20)
        .offset(y: topOffset)
        .frame(height: max(height, 60), alignment: .top)
        .opacity(isPast ? 0.6 : 1.0)
    }
    
    // MARK: - Computed Properties
    
    private var isPast: Bool {
        let eventDateTime = getEventDateTime()
        return eventDateTime < Date()
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private func getEventDateTime() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = evenement.date
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = evenement.heureFin // Utiliser l'heure de fin pour déterminer si l'événement est passé
        
        let dateTimeString = "\(dateString) \(timeString)"
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        return dateTimeFormatter.date(from: dateTimeString) ?? Date()
    }
    
    private var eventColor: Color {
        let baseColor = colorFromHex(evenement.couleur ?? "#FF5733")
        return isPast ? baseColor.opacity(0.5) : baseColor
    }
    
    private var eventTextColor: Color {
        return isPast ? AppColors.mediumGray : AppColors.black
    }
    
    private var eventSecondaryTextColor: Color {
        return isPast ? AppColors.mediumGray.opacity(0.7) : AppColors.mediumGray
    }
    
    private var eventBackgroundColor: Color {
        return isPast ? AppColors.backgroundGray : AppColors.white
    }
    
    private var eventBadgeBackgroundColor: Color {
        let baseColor = colorFromHex(evenement.couleur ?? "#FF5733")
        return isPast ? baseColor.opacity(0.1) : baseColor.opacity(0.2)
    }
    
    private var eventBadgeTextColor: Color {
        let baseColor = colorFromHex(evenement.couleur ?? "#FF5733")
        return isPast ? baseColor.opacity(0.6) : baseColor
    }
    
    private var eventShadowColor: Color {
        return isPast ? .black.opacity(0.03) : .black.opacity(0.08)
    }
    
    private func parseTime(_ timeString: String) -> Int {
        let components = timeString.split(separator: ":")
        if components.count == 2, let hour = Int(components[0]) {
            return hour
        }
        return 0
    }
    
    private func colorFromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
}

// MARK: - CreateEvenementView

struct CreateEvenementView: View {
    @ObservedObject var viewModel: EvenementViewModel
    @Environment(\.dismiss) var dismiss
    
    let selectedDate: Date
    let onDismiss: (Date?) -> Void
    
    @State private var titre = ""
    @State private var type = "cours"
    @State private var date: Date
    @State private var heureDebut = Date()
    @State private var heureFin = Date()
    @State private var lieu = ""
    @State private var tarifHoraire = ""
    @State private var couleurSelectionnee = 0
    
    init(viewModel: EvenementViewModel, selectedDate: Date, onDismiss: @escaping (Date?) -> Void) {
        self.viewModel = viewModel
        self.selectedDate = selectedDate
        self.onDismiss = onDismiss
        _date = State(initialValue: selectedDate)
    }
    
    // Liste de couleurs prédéfinies
    let couleurs: [(nom: String, hex: String)] = [
        ("Rouge", "#FF5733"),
        ("Bleu", "#3498DB"),
        ("Vert", "#2ECC71"),
        ("Orange", "#F39C12"),
        ("Violet", "#9B59B6"),
        ("Rose", "#E91E63"),
        ("Turquoise", "#1ABC9C"),
        ("Jaune", "#F1C40F"),
        ("Rouge bordeaux", "#CF1919"),
        ("Gris", "#95A5A6")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informations de base") {
                    TextField("Titre", text: $titre)
                    Picker("Type", selection: $type) {
                        Text("Cours").tag("cours")
                        Text("Job").tag("job")
                        Text("Deadline").tag("deadline")
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Horaires") {
                    DatePicker("Heure début", selection: $heureDebut, displayedComponents: .hourAndMinute)
                    DatePicker("Heure fin", selection: $heureFin, displayedComponents: .hourAndMinute)
                }
                
                Section("Détails (optionnel)") {
                    TextField("Lieu", text: $lieu)
                    
                    if type == "job" {
                        TextField("Tarif horaire", text: $tarifHoraire)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Couleur", selection: $couleurSelectionnee) {
                        ForEach(0..<couleurs.count, id: \.self) { index in
                            HStack {
                                Circle()
                                    .fill(colorFromHex(couleurs[index].hex))
                                    .frame(width: 20, height: 20)
                                Text(couleurs[index].nom)
                            }
                            .tag(index)
                        }
                    }
                }
            }
            .navigationTitle("Nouvel événement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Créer") {
                        createEvenement()
                    }
                    .disabled(titre.isEmpty || viewModel.isLoading)
                }
            }
        }
    }
    
    private func createEvenement() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let heureDebutString = timeFormatter.string(from: heureDebut)
        let heureFinString = timeFormatter.string(from: heureFin)
        
        let request = CreateEvenementRequest(
            titre: titre,
            type: type,
            date: dateString,
            heureDebut: heureDebutString,
            heureFin: heureFinString,
            lieu: lieu.isEmpty ? nil : lieu,
            tarifHoraire: type == "job" && !tarifHoraire.isEmpty ? Double(tarifHoraire) : nil,
            couleur: couleurs[couleurSelectionnee].hex
        )
        
        Task {
            print("🟢 CreateEvenementView - Début de la création")
            let success = await viewModel.createEvenement(request)
            print("🟢 CreateEvenementView - Résultat création: \(success)")
            
            if success {
                // Attendre un peu pour s'assurer que le serveur a bien enregistré
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconde
                
                // Recharger les événements pour s'assurer que tout est à jour
                print("🟢 CreateEvenementView - Rechargement des événements")
                await viewModel.loadEvenements()
                print("🟢 CreateEvenementView - Événements rechargés: \(viewModel.evenements.count)")
                
                dismiss()
                // Passer la date de l'événement créé pour mettre à jour la sélection
                onDismiss(date)
            } else {
                print("🔴 CreateEvenementView - Échec de la création")
            }
        }
    }
    
    // Helper pour convertir hex string en Color
    private func colorFromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
}

// MARK: - EditEvenementView

struct EditEvenementView: View {
    let evenement: Evenement
    @ObservedObject var viewModel: EvenementViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var titre: String
    @State private var type: String
    @State private var date: Date
    @State private var heureDebut: Date
    @State private var heureFin: Date
    @State private var lieu: String
    @State private var tarifHoraire: String
    @State private var couleurSelectionnee: Int
    
    let onDismiss: () -> Void
    
    // Liste de couleurs prédéfinies
    let couleurs: [(nom: String, hex: String)] = [
        ("Rouge", "#FF5733"),
        ("Bleu", "#3498DB"),
        ("Vert", "#2ECC71"),
        ("Orange", "#F39C12"),
        ("Violet", "#9B59B6"),
        ("Rose", "#E91E63"),
        ("Turquoise", "#1ABC9C"),
        ("Jaune", "#F1C40F"),
        ("Rouge bordeaux", "#CF1919"),
        ("Gris", "#95A5A6")
    ]
    
    init(evenement: Evenement, viewModel: EvenementViewModel, onDismiss: @escaping () -> Void) {
        self.evenement = evenement
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // Convertir les heures String en Date
        let heureDebutDate = timeFormatter.date(from: evenement.heureDebut) ?? Date()
        let heureFinDate = timeFormatter.date(from: evenement.heureFin) ?? Date()
        
        // Trouver l'index de la couleur dans la liste
        let couleurHex = evenement.couleur ?? "#FF5733"
        let couleursList: [(nom: String, hex: String)] = [
            ("Rouge", "#FF5733"),
            ("Bleu", "#3498DB"),
            ("Vert", "#2ECC71"),
            ("Orange", "#F39C12"),
            ("Violet", "#9B59B6"),
            ("Rose", "#E91E63"),
            ("Turquoise", "#1ABC9C"),
            ("Jaune", "#F1C40F"),
            ("Rouge bordeaux", "#CF1919"),
            ("Gris", "#95A5A6")
        ]
        let couleurIndex = couleursList.firstIndex(where: { $0.hex == couleurHex }) ?? 0
        
        _titre = State(initialValue: evenement.titre)
        _type = State(initialValue: evenement.type)
        _date = State(initialValue: dateFormatter.date(from: evenement.date) ?? Date())
        _heureDebut = State(initialValue: heureDebutDate)
        _heureFin = State(initialValue: heureFinDate)
        _lieu = State(initialValue: evenement.lieu ?? "")
        _tarifHoraire = State(initialValue: evenement.tarifHoraire.map { String($0) } ?? "")
        _couleurSelectionnee = State(initialValue: couleurIndex)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informations de base") {
                    TextField("Titre", text: $titre)
                    Picker("Type", selection: $type) {
                        Text("Cours").tag("cours")
                        Text("Job").tag("job")
                        Text("Deadline").tag("deadline")
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Horaires") {
                    DatePicker("Heure début", selection: $heureDebut, displayedComponents: .hourAndMinute)
                    DatePicker("Heure fin", selection: $heureFin, displayedComponents: .hourAndMinute)
                }
                
                Section("Détails (optionnel)") {
                    TextField("Lieu", text: $lieu)
                    
                    if type == "job" {
                        TextField("Tarif horaire", text: $tarifHoraire)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Couleur", selection: $couleurSelectionnee) {
                        ForEach(0..<couleurs.count, id: \.self) { index in
                            HStack {
                                Circle()
                                    .fill(colorFromHex(couleurs[index].hex))
                                    .frame(width: 20, height: 20)
                                Text(couleurs[index].nom)
                            }
                            .tag(index)
                        }
                    }
                }
            }
            .navigationTitle("Modifier l'événement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        updateEvenement()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
    
    private func updateEvenement() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let heureDebutString = timeFormatter.string(from: heureDebut)
        let heureFinString = timeFormatter.string(from: heureFin)
        
        let request = UpdateEvenementRequest(
            titre: titre,
            type: type,
            date: dateString,
            heureDebut: heureDebutString,
            heureFin: heureFinString,
            lieu: lieu.isEmpty ? nil : lieu,
            tarifHoraire: type == "job" && !tarifHoraire.isEmpty ? Double(tarifHoraire) : nil,
            couleur: couleurs[couleurSelectionnee].hex
        )
        
        Task {
            print("🟢 EditEvenementView - Début de la mise à jour")
            let success = await viewModel.updateEvenement(id: evenement.id, request)
            print("🟢 EditEvenementView - Résultat mise à jour: \(success)")
            
            if success {
                // Attendre un peu pour s'assurer que le serveur a bien enregistré
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconde
                
                // Recharger les événements pour s'assurer que tout est à jour
                print("🟢 EditEvenementView - Rechargement des événements")
                await viewModel.loadEvenements()
                print("🟢 EditEvenementView - Événements rechargés: \(viewModel.evenements.count)")
                
                dismiss()
                onDismiss()
            } else {
                print("🔴 EditEvenementView - Échec de la mise à jour")
            }
        }
    }
    
    // Helper pour convertir hex string en Color
    private func colorFromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
}

#Preview {
    CalendarView()
}
