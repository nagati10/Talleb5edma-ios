# Architecture des Écrans - Taleb 5edma

## Vue d'ensemble

L'application s'articule autour de **5 écrans principaux** accessibles via une **TabBar** en bas de l'écran :
1. **Accueil** 🏠 (Dashboard/Home)
2. **Calendrier** 📅
3. **Disponibilités** ⏰
4. **Profil** 👤
5. **Offres** 💼

---

## 📱 Écran 1 : Dashboard/Accueil

### Structure
```
┌─────────────────────────────────┐
│ Header Fixe                     │
│ ☰ Menu | 🔔 Notif | 👤 Profil  │
├─────────────────────────────────┤
│                                 │
│ Bonjour, Sarah 👋              │
│                                 │
│ [Résumé Hebdomadaire]          │
│ 15h/20h                        │
│ ████████░░░░░░░░░░░░            │
│                                 │
│ [Agenda du Jour]               │
│ • Event 1 (09:00)              │
│ • Event 2 (14:00)              │
│                                 │
│ [Mode Examens]                 │
│ ████████████ OFF/ON            │
│                                 │
│ [Voir calendrier] →            │
│                                 │
│ [Barre de recherche]           │
│ [Filtres] [QR] [Map] [AI-CV]   │
│                                 │
│ [Liste des Emplois]            │
└─────────────────────────────────┘
```

### Composants créés
- **DashboardHeaderView** : Header fixe avec menu ☰, notifications 🔔 (badge), profil 👤
- **WeeklySummaryCard** : Résumé hebdomadaire avec barre de progression (jobs/cours)
- **DailyAgendaCard** : Card agenda listant les événements du jour avec horaires cliquables
- **ExamModeToggle** : Toggle large pour activer/désactiver le mode examens
- **WorkloadBadge** : Badge coloré signalant la charge de travail

### Fonctionnalités
- ✅ Header fixe avec notifications (badge numérique)
- ✅ Section bienvenue personnalisée
- ✅ Résumé hebdomadaire avec barre de progression visuelle (15h/20h)
- ✅ Card agenda avec événements du jour (horaires cliquables)
- ✅ Toggle Mode Examens (OFF/ON dans une box)
- ✅ Bouton principal "Voir calendrier" → Navigation vers Écran 2
- ✅ Barre de recherche et filtres rapides
- ✅ Liste des emplois

---

## 📅 Écran 2 : Calendrier

### Structure
```
┌─────────────────────────────────┐
│ [<] Jour | Semaine | Mois [>]   │
├─────────────────────────────────┤
│                                 │
│ [Blocs horaires colorés]       │
│                                 │
│ 🔵 Cours (non modifiable)      │
│ 🟢 Jobs (modifiable)            │
│ ⚪ Pauses/Libre                 │
│ 🔴 Deadlines                    │
│                                 │
│ [+ Ajouter événement]          │
│                                 │
│ [Légende colorée]              │
└─────────────────────────────────┘
```

### Composants à créer
- **CalendarNavigationView** : Navigation jour/semaine/mois avec flèches ⟨⟩
- **TimeBlockView** : Bloc horaire coloré cliquable
- **EventDetailView** : Détails d'un événement
- **AddEventModal** : Formulaire pour créer un événement

### Fonctionnalités
- Navigation par jour, semaine ou mois (tabs + flèches)
- Blocs horaires colorés :
  - 🔵 Bleu : Cours (non modifiable)
  - 🟢 Vert : Jobs (modifiable)
  - ⚪ Gris : Pauses/Libre
  - 🔴 Rouge : Deadlines
- Chaque bloc est cliquable pour accéder aux détails
- Bouton [+ Ajouter événement] → Modal avec formulaire
- Légende colorée en bas

---

## ⏰ Écran 3 : Définir Disponibilité

### Structure
```
┌─────────────────────────────────┐
│ [Définir Disponibilité]        │
├─────────────────────────────────┤
│ ▼ Lundi                        │
│   [Card] 09:00-12:00 🟢       │
│   [Card] 14:00-18:00 🟢       │
│   [+ Ajouter]                  │
│                                 │
│ ▶ Mardi                        │
│ ▶ Mercredi                     │
│ ...                            │
│                                 │
│ [Checkboxes]                   │
│ ☑ Sync auto                    │
│ ☑ Marges avant/après           │
│                                 │
│ [Enregistrer]                  │
└─────────────────────────────────┘
```

### Composants à créer
- **AvailabilityAccordion** : Accordéon par jour
- **AvailabilityCard** : Card avec horaires, durée, badge couleur
- **AddAvailabilityModal** : Modal avec formulaire (jour, time pickers, récurrence)

### Fonctionnalités
- Accordéons par jour (Lundi, Mardi, etc.)
- Cards avec horaires, durée calculée automatiquement
- Badges couleur :
  - 🟢 Vert : Disponible
  - 🔴 Rouge : Fermé
  - 🟡 Jaune : Limité
- Bouton [+ Ajouter] → Modal avec :
  - Dropdown jour
  - Time pickers (début/fin)
  - Radio buttons récurrence
  - Boutons "Annuler"/"Ajouter"
- Checkboxes :
  - Synchronisation automatique
  - Marges avant/après jobs
- Bouton "Enregistrer" avec confirmation et toast

---

## 👤 Écran 4 : Mode Examens

### Structure
```
┌─────────────────────────────────┐
│ [Mode Examens]                 │
│                                 │
│ [Toggle Switch Large]          │
│ ████████████ ON/OFF            │
│                                 │
│ [Bénéfices]                    │
│ • Bloquer offres               │
│ • Masquer notifications        │
│ • Conserver jobs acceptés      │
│ • Rappels révision             │
│ • Suggestions pauses           │
│                                 │
│ [Date Picker Début]            │
│ [Date Picker Fin]              │
│ Durée: 15 jours                │
│                                 │
│ [Checkboxes]                   │
│ ☑ Récap quotidien              │
│ ☑ Rappels sommeil              │
│ ☑ Autoriser jobs urgents       │
│                                 │
│ [Activer Mode]                 │
└─────────────────────────────────┘
```

### Composants à créer
- **ExamModeView** : Vue principale du mode examens
- **ExamModeToggleLarge** : Toggle switch large avec affichage ON/OFF
- **ExamModeBenefitsList** : Liste à puces des bénéfices
- **ExamModeDatePickers** : Date pickers avec calcul automatique de durée
- **ExamModeCheckboxes** : Checkboxes configurables

### Fonctionnalités
- Toggle switch large pour activer/désactiver
- Affichage ON/OFF dans une box centrale
- Liste à puces des bénéfices :
  - Bloquer offres
  - Masquer notifications
  - Conserver jobs acceptés
  - Rappels révision
  - Suggestions pauses
- Date pickers pour période (début/fin)
- Durée calculée automatiquement
- Checkboxes configurables :
  - Récap quotidien
  - Rappels sommeil
  - Autoriser jobs urgents
- Bouton "Activer Mode" avec popup de confirmation et toast

---

## 💼 Écran 5 : Offres (Avis/Réclamations)

### Structure Avis
```
┌─────────────────────────────────┐
│ [📊 Statistiques]               │
├─────────────────────────────────┤
│                                 │
│ [Liste des Avis]               │
│ ┌─────────────────────────┐    │
│ │ ⭐⭐⭐⭐⭐              │    │
│ │ Commentaire...          │    │
│ │ [Photo] @Pseudo         │    │
│ └─────────────────────────┘    │
│                                 │
│                            [+]  │
│                                 │
└─────────────────────────────────┘
```

### Composants à créer
- **ReviewsListView** : Liste de tous les avis
- **AddReviewButton** : Bouton flottant [+] en bas à droite
- **ReviewCard** : Card affichant un avis (note, commentaire, photo, pseudo/anonyme)
- **AddReviewModal** : Modal pour ajouter un avis
- **StatisticsView** : Page de statistiques avec graphiques

### Fonctionnalités Avis
- Liste de tous les avis laissés par les utilisateurs
- Bouton [+] en bas à droite → Menu : "Laisser un avis" / "Faire une réclamation"
- Formulaire avis :
  - Note avec étoiles (1-5)
  - Commentaire
  - Photo (optionnelle)
  - Pseudo ou anonyme
- Validation → Avis visible immédiatement dans la liste
- Icône graphique en haut à droite → Statistiques :
  - Diagramme répartition des notes (1-5 étoiles)
  - Note moyenne
  - Nombre total d'avis
  - % avis anonymes
  - Nombre de réclamations

### Structure Réclamations
- Menu de sélection : Type de problème (application, paiement, compte, etc.)
- Message
- Captures d'écran/photos (optionnelles)
- Option anonyme
- Validation → Envoyé (visible uniquement par l'administrateur)

---

## 🔍 Écran : Détails de l'Offre (ScreenOffres)

### Structure
```
┌─────────────────────────────────┐
│ [← Retour] [❤️] [📤 Partager]  │
├─────────────────────────────────┤
│                                 │
│ [Image Carrousel]              │
│ [<] [•] [•] [•] [>]            │
│                                 │
│ Titre de l'offre               │
│ Salaire | Type                 │
│                                 │
│ [Matching] →                   │
│ [Discuter] →                   │
│                                 │
│ Description                    │
│ Exigences                      │
│ ...                            │
└─────────────────────────────────┘
```

### Composants à créer
- **OfferDetailHeader** : Flèche retour, cœur (sauvegarder), partager
- **OfferImageCarousel** : Carrousel d'images avec navigation gauche/droite
- **OfferMatchingButton** : Bouton "Matching" → Écran d'analyse
- **OfferChatButton** : Bouton "Discuter" → ChatItem

### Fonctionnalités
- Flèche retour → Retour à l'accueil
- ❤️ Cœur : Sauvegarder l'offre (rempli = sauvegardé)
- 📤 Partager : Partager l'offre
- Flèches gauche/droite : Naviguer entre les images
- Bouton "Matching" → Voir l'analyse de correspondance
- Bouton "Discuter" → Ouvrir le chat avec l'employeur

---

## 💬 Écran : ChatItem (Discussion)

### Structure
```
┌─────────────────────────────────┐
│ [← Retour] [📞] [📹]            │
├─────────────────────────────────┤
│                                 │
│ [Messages]                     │
│ ┌─────────────────┐            │
│ │ Message reçu    │            │
│ └─────────────────┘            │
│                                 │
│       ┌─────────────────┐      │
│       │ Message envoyé  │      │
│       └─────────────────┘      │
│                                 │
├─────────────────────────────────┤
│ [+] [📷] [🎤] [💬] [👍]        │
└─────────────────────────────────┘
```

### Composants à créer
- **ChatHeaderView** : Flèche retour, téléphone, caméra
- **ChatMessageView** : Affichage des messages
- **ChatInputView** : Zone de saisie avec boutons

### Fonctionnalités
- Flèche retour → Retour à l'offre
- 📞 Icône téléphone : Appel vocal
- 📹 Icône caméra : Appel vidéo
- Boutons en bas :
  - ➕ : Ajouter fichiers
  - 📷 : Ajouter photos
  - 🎤 : Messages vocaux
  - 💬 : Champ texte pour écrire
  - 😊 : Ajouter emojis
  - 👍 : Envoyer un like

---

## 📞 Écran : CallOverlay (Appel)

### Structure
```
┌─────────────────────────────────┐
│                                 │
│     [Vue caméra/vidéo]          │
│                                 │
│ [💬] [📹] [🔊] [🎤] [📞]       │
│                                 │
└─────────────────────────────────┘
```

### Composants à créer
- **CallOverlayView** : Overlay pendant l'appel
- **CallControlsView** : Contrôles de l'appel

### Fonctionnalités
- 💬 Bulle de chat : Ouvrir le chat pendant l'appel
- 📹 Icône caméra : Activer/désactiver la vidéo
- 🔊 Icône haut-parleur : Basculer vers le haut-parleur
- 🎤 Icône micro : Muter/démuter
- 📞 Icône raccrocher : Terminer l'appel

---

## 🎯 Écran : MatchCriterion (Analyse de Correspondance)

### Structure
```
┌─────────────────────────────────┐
│                                 │
│    Score: 92%                   │
│                                 │
│ [Grille de critères]           │
│ Localisation: ████░░ 80%       │
│ Compétences: ██████ 95%        │
│ ...                            │
│                                 │
│ [← Back To Job Details]        │
│ [⚙️ Update Preferences]        │
└─────────────────────────────────┘
```

### Composants à créer
- **MatchScoreView** : Score principal (pourcentage global)
- **MatchCriteriaGrid** : Grille avec détails par critère
- **MatchNavigationButtons** : Boutons de navigation

### Fonctionnalités
- Score principal : Pourcentage global de match (ex: 92%)
- Grille : Détails par critère :
  - Localisation : 80%
  - Compétences : 95%
  - Salaire : 85%
  - Horaires : 90%
- Bouton "← Back To Job Details" → Retour aux détails de l'offre
- Lien "⚙️ Update Preferences" → Modifier les préférences

---

## 🎨 Navigation & TabBar

### TabBar (Bottom Navigation)
```
┌─────────────────────────────────┐
│ 🏠 Accueil | 📅 Calendrier     │
│ ⏰ Dispo | 👤 Profil | 💼 Offres│
└─────────────────────────────────┘
```

### Ordre des onglets
1. **Accueil** 🏠 (tag: 0)
2. **Calendrier** 📅 (tag: 1)
3. **Dispo** ⏰ (tag: 2)
4. **Profil** 👤 (tag: 3)
5. **Offres** 💼 (tag: 4)

---

## 📋 Checklist des Composants

### ✅ Créés
- [x] DashboardHeaderView
- [x] WeeklySummaryCard
- [x] DailyAgendaCard
- [x] ExamModeToggle
- [x] WorkloadBadge
- [x] EventRow
- [x] DashboardView réorganisé

### 🔨 À créer
- [ ] CalendarNavigationView
- [ ] TimeBlockView
- [ ] EventDetailView
- [ ] AddEventModal
- [ ] AvailabilityAccordion
- [ ] AvailabilityCard
- [ ] AddAvailabilityModal
- [ ] ExamModeView (complet)
- [ ] ExamModeBenefitsList
- [ ] ExamModeDatePickers
- [ ] ReviewsListView
- [ ] ReviewCard
- [ ] AddReviewModal
- [ ] StatisticsView
- [ ] OfferImageCarousel
- [ ] OfferMatchingButton
- [ ] ChatHeaderView
- [ ] ChatMessageView
- [ ] ChatInputView
- [ ] CallOverlayView
- [ ] MatchScoreView
- [ ] MatchCriteriaGrid

---

## 🎨 Palette de Couleurs

Utiliser la palette définie dans `AppColors.swift` :
- **Rouge bordeaux** : `AppColors.primaryRed` (#CF1919)
- **Gris** : `AppColors.backgroundGray`, `AppColors.lightGray`, etc.
- **Vert** : `AppColors.successGreen` (pour jobs/disponibilités)
- **Bleu** : `Color.blue` (pour cours)

---

## 📝 Notes Importantes

1. **Cohérence** : Tous les composants doivent utiliser `AppColors` pour les couleurs
2. **Réutilisabilité** : Créer des composants réutilisables (GenericCard, etc.)
3. **Navigation** : Utiliser `NavigationLink` ou `sheet()` selon le contexte
4. **Données** : Créer des ViewModels pour gérer les données de chaque écran
5. **Accessibilité** : Ajouter des labels et descriptions pour VoiceOver

---

*Document créé le 10/11/2025*
*Dernière mise à jour : Organisation des écrans selon spécifications*

