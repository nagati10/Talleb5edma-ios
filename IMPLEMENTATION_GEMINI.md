# 🚀 Implémentation Google Gemini Pro - Guide Complet

## 📋 Étapes d'Implémentation

### Étape 1 : Obtenir la Clé API Gemini (5 minutes)

1. Aller sur https://makersuite.google.com/app/apikey
2. Se connecter avec votre compte Google
3. Cliquer sur "Create API Key"
4. Copier la clé API générée
5. **C'est tout ! Aucun paiement requis**

---

## 🔧 Backend NestJS

### Installation des Dépendances

```bash
cd votre-backend-nestjs
npm install @google/generative-ai
npm install @nestjs/cache-manager cache-manager cache-manager-redis-store
npm install crypto
```

### Structure des Fichiers

```
backend/
├── src/
│   ├── ai-routine/
│   │   ├── ai-routine.module.ts
│   │   ├── ai-routine.controller.ts
│   │   ├── ai-routine.service.ts
│   │   └── dto/
│   │       └── routine-input.dto.ts
│   └── app.module.ts
```

---

## 📝 Code Backend Complet

### 1. DTO pour les Données d'Entrée

```typescript
// src/ai-routine/dto/routine-input.dto.ts
export class RoutineInputDataDto {
  evenements: EvenementDto[];
  disponibilites: DisponibiliteDto[];
  preferences?: UserPreferencesDto;
  dateDebut: string;
  dateFin: string;
}

export class EvenementDto {
  id: string;
  titre: string;
  type: string;
  date: string;
  heureDebut: string;
  heureFin: string;
  lieu?: string;
  tarifHoraire?: number;
  couleur?: string;
}

export class DisponibiliteDto {
  id: string;
  jour: string;
  heureDebut: string;
  heureFin?: string;
}

export class UserPreferencesDto {
  educationLevel?: string;
  studyField?: string;
  searchTypes?: string[];
  mainMotivation?: string;
  softSkills?: string[];
  languageLevels?: any[];
  interests?: string[];
}
```

### 2. Module AI Routine

```typescript
// src/ai-routine/ai-routine.module.ts
import { Module } from '@nestjs/common';
import { CacheModule } from '@nestjs/cache-manager';
import { AIRoutineController } from './ai-routine.controller';
import { AIRoutineService } from './ai-routine.service';
import * as redisStore from 'cache-manager-redis-store';

@Module({
  imports: [
    CacheModule.register({
      store: redisStore,
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      ttl: 3600, // 1 heure
    }),
  ],
  controllers: [AIRoutineController],
  providers: [AIRoutineService],
  exports: [AIRoutineService],
})
export class AIRoutineModule {}
```

### 3. Service avec Gemini

```typescript
// src/ai-routine/ai-routine.service.ts
import { Injectable, Inject, Logger } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { createHash } from 'crypto';
import { RoutineInputDataDto } from './dto/routine-input.dto';

@Injectable()
export class AIRoutineService {
  private readonly logger = new Logger(AIRoutineService.name);
  private genAI: GoogleGenerativeAI;
  private model: any;

  constructor(
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
  ) {
    // Initialiser Gemini avec la clé API
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      this.logger.error('GEMINI_API_KEY non définie dans les variables d\'environnement');
      throw new Error('GEMINI_API_KEY est requise');
    }

    this.genAI = new GoogleGenerativeAI(apiKey);
    this.model = this.genAI.getGenerativeModel({ 
      model: 'gemini-1.5-flash', // Utiliser gemini-1.5-flash (gratuit et rapide) ou gemini-1.5-pro (meilleure qualité)
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      },
    });

    this.logger.log('✅ Google Gemini Pro initialisé avec succès');
  }

  async analyzeRoutine(
    userId: string,
    data: RoutineInputDataDto,
  ): Promise<any> {
    // 1. Générer un hash des données pour le cache
    const dataHash = this.generateDataHash(data);
    const cacheKey = `routine_analysis_${userId}_${dataHash}`;

    // 2. Vérifier le cache
    try {
      const cached = await this.cacheManager.get<any>(cacheKey);
      if (cached) {
        this.logger.log(`✅ Cache hit pour utilisateur ${userId}`);
        return cached;
      }
    } catch (error) {
      this.logger.warn('Erreur lors de la lecture du cache, continuation sans cache');
    }

    this.logger.log(`❌ Cache miss pour utilisateur ${userId}, appel Gemini...`);

    // 3. Calculer les statistiques
    const stats = this.calculateStats(data);

    // 4. Créer le prompt
    const prompt = this.createPrompt(data, stats);

    try {
      // 5. Appeler Gemini
      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();

      // 6. Parser la réponse JSON
      let aiResponse;
      try {
        // Extraire le JSON de la réponse (peut contenir du markdown)
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          aiResponse = JSON.parse(jsonMatch[0]);
        } else {
          throw new Error('Aucun JSON trouvé dans la réponse');
        }
      } catch (parseError) {
        this.logger.error('Erreur lors du parsing JSON:', parseError);
        this.logger.error('Réponse Gemini:', text);
        throw new Error('Erreur lors du parsing de la réponse Gemini');
      }

      // 7. Convertir en format RoutineBalance
      const routineBalance = this.convertToRoutineBalance(aiResponse, stats);

      // 8. Mettre en cache
      try {
        await this.cacheManager.set(cacheKey, routineBalance, 3600);
      } catch (cacheError) {
        this.logger.warn('Erreur lors de la mise en cache, continuation sans cache');
      }

      this.logger.log(`✅ Analyse terminée pour utilisateur ${userId}, score: ${routineBalance.scoreEquilibre}`);
      return routineBalance;

    } catch (error) {
      this.logger.error('Erreur lors de l\'appel Gemini:', error);
      throw new Error(`Erreur lors de l'analyse IA: ${error.message}`);
    }
  }

  private generateDataHash(data: RoutineInputDataDto): string {
    // Créer un hash des données pour identifier les analyses identiques
    const dataString = JSON.stringify({
      evenements: data.evenements.map(e => ({
        date: e.date,
        type: e.type,
        heureDebut: e.heureDebut,
        heureFin: e.heureFin,
      })),
      disponibilites: data.disponibilites,
      preferences: data.preferences,
      dateDebut: data.dateDebut,
      dateFin: data.dateFin,
    });
    
    return createHash('sha256')
      .update(dataString)
      .digest('hex')
      .substring(0, 16);
  }

  private calculateStats(data: RoutineInputDataDto): any {
    const dateFormatter = new DateFormatter('yyyy-MM-dd');
    
    // Filtrer les événements dans la plage de dates
    const dateDebut = new Date(data.dateDebut);
    const dateFin = new Date(data.dateFin);
    
    const evenementsFiltres = data.evenements.filter(evenement => {
      const eventDate = new Date(evenement.date);
      return eventDate >= dateDebut && eventDate <= dateFin;
    });

    let heuresTravail = 0;
    let heuresEtudes = 0;
    let heuresActivites = 0;

    for (const evenement of evenementsFiltres) {
      const duree = this.calculerDureeHeures(
        evenement.heureDebut,
        evenement.heureFin
      );

      switch (evenement.type.toLowerCase()) {
        case 'job':
          heuresTravail += duree;
          break;
        case 'cours':
          heuresEtudes += duree;
          break;
        case 'deadline':
          heuresEtudes += duree * 0.5;
          heuresTravail += duree * 0.5;
          break;
        default:
          heuresActivites += duree;
      }
    }

    const heuresTotales = heuresTravail + heuresEtudes + heuresActivites;
    const heuresDisponibles = 16.0 * 7.0; // 16h/jour × 7 jours
    const heuresRepos = Math.max(0, heuresDisponibles - heuresTotales);
    const total = heuresTravail + heuresEtudes + heuresRepos + heuresActivites;

    return {
      heuresTravail,
      heuresEtudes,
      heuresRepos,
      heuresActivites,
      heuresTotales: total,
      pourcentageTravail: total > 0 ? (heuresTravail / total) * 100 : 0,
      pourcentageEtudes: total > 0 ? (heuresEtudes / total) * 100 : 0,
      pourcentageRepos: total > 0 ? (heuresRepos / total) * 100 : 0,
      pourcentageActivites: total > 0 ? (heuresActivites / total) * 100 : 0,
    };
  }

  private calculerDureeHeures(heureDebut: string, heureFin: string): number {
    const [h1, m1] = heureDebut.split(':').map(Number);
    const [h2, m2] = heureFin.split(':').map(Number);
    
    const debutMinutes = h1 * 60 + m1;
    const finMinutes = h2 * 60 + m2;
    
    const dureeMinutes = finMinutes - debutMinutes;
    return Math.max(0, dureeMinutes / 60.0);
  }

  private createPrompt(data: RoutineInputDataDto, stats: any): string {
    const evenementsText = data.evenements.length > 0
      ? data.evenements.map(e => 
          `- ${e.titre} (${e.type}) : ${e.date} de ${e.heureDebut} à ${e.heureFin}${e.lieu ? ` à ${e.lieu}` : ''}`
        ).join('\n')
      : 'Aucun événement';

    const disponibilitesText = data.disponibilites.length > 0
      ? data.disponibilites.map(d => 
          `- ${d.jour} : ${d.heureDebut}${d.heureFin ? ` - ${d.heureFin}` : ' (toute la journée)'}`
        ).join('\n')
      : 'Aucune disponibilité définie';

    return `Tu es un assistant IA spécialisé dans l'équilibre vie-études-travail pour les étudiants tunisiens.

Analyse cette routine hebdomadaire et génère des recommandations personnalisées.

STATISTIQUES HEBDOMADAIRES :
- Heures de travail : ${stats.heuresTravail.toFixed(1)}h (${stats.pourcentageTravail.toFixed(1)}%)
- Heures d'études : ${stats.heuresEtudes.toFixed(1)}h (${stats.pourcentageEtudes.toFixed(1)}%)
- Heures de repos : ${stats.heuresRepos.toFixed(1)}h (${stats.pourcentageRepos.toFixed(1)}%)
- Heures d'activités personnelles : ${stats.heuresActivites.toFixed(1)}h (${stats.pourcentageActivites.toFixed(1)}%)

ÉVÉNEMENTS DE LA SEMAINE :
${evenementsText}

DISPONIBILITÉS :
${disponibilitesText}

${data.preferences ? `PRÉFÉRENCES UTILISATEUR :
- Niveau d'étude : ${data.preferences.educationLevel || 'Non spécifié'}
- Domaine : ${data.preferences.studyField || 'Non spécifié'}
- Motivation : ${data.preferences.mainMotivation || 'Non spécifiée'}
` : ''}

Génère une analyse complète en JSON avec ce format EXACT (réponds UNIQUEMENT en JSON, sans texte avant ou après) :

{
  "scoreEquilibre": 0-100,
  "recommandations": [
    {
      "type": "travail|etudes|repos|activites|sante|social|optimisation",
      "titre": "Titre court et clair",
      "description": "Description détaillée et personnalisée (2-3 phrases)",
      "priorite": "haute|moyenne|basse",
      "actionSuggeree": "Action concrète et réalisable"
    }
  ],
  "suggestionsOptimisation": [
    {
      "jour": "Jour concerné ou 'Cette semaine'",
      "type": "deplacement|ajout|suppression|regroupement|pause",
      "description": "Description de l'optimisation",
      "avantage": "Avantage concret",
      "impact": "tresPositif|positif|neutre"
    }
  ]
}

Règles importantes :
- Sois spécifique et adapté au contexte tunisien
- Les recommandations doivent être pratiques et réalisables
- Le score doit refléter l'équilibre réel (0-100)
- Minimum 2-3 recommandations, maximum 6
- Minimum 1-2 suggestions d'optimisation
- Réponds UNIQUEMENT en JSON valide, sans markdown, sans code blocks`;
  }

  private convertToRoutineBalance(aiResponse: any, stats: any): any {
    // Générer des IDs uniques
    const generateId = () => Math.random().toString(36).substring(2, 15);

    return {
      id: generateId(),
      dateAnalyse: new Date().toISOString(),
      scoreEquilibre: Math.max(0, Math.min(100, aiResponse.scoreEquilibre || 50)),
      recommandations: (aiResponse.recommandations || []).map((r: any) => ({
        id: generateId(),
        type: r.type || 'optimisation',
        titre: r.titre || 'Recommandation',
        description: r.description || '',
        priorite: r.priorite || 'moyenne',
        actionSuggeree: r.actionSuggeree || null,
      })),
      analyseHebdomadaire: {
        heuresTravail: stats.heuresTravail,
        heuresEtudes: stats.heuresEtudes,
        heuresRepos: stats.heuresRepos,
        heuresActivites: stats.heuresActivites,
        heuresTotales: stats.heuresTotales,
        repartition: {
          pourcentageTravail: stats.pourcentageTravail,
          pourcentageEtudes: stats.pourcentageEtudes,
          pourcentageRepos: stats.pourcentageRepos,
          pourcentageActivites: stats.pourcentageActivites,
        },
      },
      suggestionsOptimisation: (aiResponse.suggestionsOptimisation || []).map((s: any) => ({
        id: generateId(),
        jour: s.jour || 'Cette semaine',
        type: s.type || 'optimisation',
        description: s.description || '',
        avantage: s.avantage || '',
        impact: s.impact || 'neutre',
      })),
    };
  }
}

// Helper pour DateFormatter (si nécessaire)
class DateFormatter {
  constructor(private format: string) {}
  // Implémentation simplifiée
}
```

### 4. Controller

```typescript
// src/ai-routine/ai-routine.controller.ts
import { Controller, Post, Body, UseGuards, Request, HttpException, HttpStatus } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // Ajustez le chemin selon votre structure
import { AIRoutineService } from './ai-routine.service';
import { RoutineInputDataDto } from './dto/routine-input.dto';

@Controller('ai/routine')
@UseGuards(JwtAuthGuard) // Protection par authentification JWT
export class AIRoutineController {
  constructor(private readonly aiRoutineService: AIRoutineService) {}

  @Post('analyze')
  async analyzeRoutine(
    @Request() req, // Contient l'utilisateur authentifié depuis le JWT
    @Body() data: RoutineInputDataDto,
  ) {
    try {
      // Récupérer l'ID utilisateur depuis le token JWT
      const userId = req.user?.id || req.user?.sub || req.user?._id;
      
      if (!userId) {
        throw new HttpException(
          'Utilisateur non authentifié',
          HttpStatus.UNAUTHORIZED,
        );
      }

      // Valider les données
      if (!data.evenements || !Array.isArray(data.evenements)) {
        throw new HttpException(
          'Les événements sont requis',
          HttpStatus.BAD_REQUEST,
        );
      }

      // Appeler le service d'analyse
      const analysis = await this.aiRoutineService.analyzeRoutine(userId, data);
      
      return {
        success: true,
        data: analysis,
      };
    } catch (error) {
      throw new HttpException(
        error.message || 'Erreur lors de l\'analyse',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
```

### 5. Ajouter au Module Principal

```typescript
// src/app.module.ts
import { Module } from '@nestjs/common';
import { AIRoutineModule } from './ai-routine/ai-routine.module';
// ... autres imports

@Module({
  imports: [
    // ... autres modules
    AIRoutineModule,
  ],
  // ...
})
export class AppModule {}
```

### 6. Variables d'Environnement

```bash
# .env
GEMINI_API_KEY=your_gemini_api_key_here
REDIS_HOST=localhost
REDIS_PORT=6379
```

---

## 📱 Modification iOS

### Mettre à jour APIConfig

```swift
// Utils/APIConfig.swift
// Ajouter dans la section Endpoints

/// Endpoint pour analyser la routine avec IA (POST /ai/routine/analyze)
static var analyzeRoutineEndpoint: String {
    return endpoint("/ai/routine/analyze")
}
```

### Modifier AIRoutineService

```swift
// Services/AIRoutineService.swift
import Foundation

/// Service d'IA pour analyser et suggérer une routine équilibrée
/// Utilise Google Gemini Pro via le backend
class AIRoutineService {
    
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
    
    /// Analyse la routine de l'utilisateur via le backend (avec Gemini)
    func analyserRoutine(
        evenements: [Evenement],
        disponibilites: [Disponibilite],
        preferences: UserPreferences?,
        dateDebut: Date = Date(),
        dateFin: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    ) async throws -> RoutineBalance {
        
        // Préparer les données
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let inputData = RoutineInputData(
            evenements: evenements,
            disponibilites: disponibilites,
            preferences: preferences,
            dateDebut: dateFormatter.string(from: dateDebut),
            dateFin: dateFormatter.string(from: dateFin)
        )
        
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
        request.httpBody = try encoder.encode(inputData)
        
        print("🟢 AIRoutineService - Appel backend: \(url.absoluteString)")
        
        // Faire la requête
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Gérer les erreurs
            if httpResponse.statusCode == 401 {
                throw AIError.notAuthenticated
            } else if httpResponse.statusCode == 429 {
                throw AIError.rateLimitExceeded
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Erreur serveur"
                print("🔴 AIRoutineService - Erreur serveur: \(errorMessage)")
                throw AIError.serverError(httpResponse.statusCode)
            }
        }
        
        // Décoder la réponse
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // La réponse peut être dans un wrapper { success: true, data: {...} }
        if let wrapper = try? decoder.decode(AIResponseWrapper.self, from: data) {
            return wrapper.data
        } else {
            // Ou directement RoutineBalance
            return try decoder.decode(RoutineBalance.self, from: data)
        }
    }
}

// MARK: - Error Types

enum AIError: LocalizedError {
    case networkError
    case notAuthenticated
    case serverError(Int)
    case rateLimitExceeded
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Erreur de connexion réseau"
        case .notAuthenticated:
            return "Vous devez être connecté pour utiliser cette fonctionnalité"
        case .serverError(let code):
            return "Erreur serveur (\(code))"
        case .rateLimitExceeded:
            return "Trop de requêtes. Veuillez réessayer plus tard"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        }
    }
}

// MARK: - Response Wrapper

struct AIResponseWrapper: Codable {
    let success: Bool
    let data: RoutineBalance
}
```

### Mettre à jour RoutineBalanceViewModel

```swift
// ViewModels/RoutineBalanceViewModel.swift
// Modifier la méthode analyserRoutine pour utiliser le backend

@MainActor
func analyserRoutine(
    evenements: [Evenement] = [],
    disponibilites: [Disponibilite] = [],
    preferences: UserPreferences? = nil,
    dateDebut: Date = Date(),
    dateFin: Date? = nil
) async {
    isLoading = true
    errorMessage = nil
    
    // Utiliser les données passées ou depuis les ViewModels
    let events = evenements.isEmpty ? (evenementViewModel?.evenements ?? []) : evenements
    let dispo = disponibilites.isEmpty ? (availabilityViewModel?.disponibilites ?? []) : disponibilites
    
    // Calculer la date de fin
    let fin = dateFin ?? Calendar.current.date(byAdding: .day, value: 7, to: dateDebut) ?? Date()
    
    do {
        print("🟢 RoutineBalanceViewModel - Début de l'analyse avec Gemini")
        
        // Appeler le service qui utilise maintenant le backend
        let balance = try await aiRoutineService.analyserRoutine(
            evenements: events,
            disponibilites: dispo,
            preferences: preferences,
            dateDebut: dateDebut,
            dateFin: fin
        )
        
        routineBalance = balance
        print("🟢 RoutineBalanceViewModel - Analyse terminée. Score: \(balance.scoreEquilibre)")
        
    } catch {
        print("🔴 RoutineBalanceViewModel - Erreur: \(error.localizedDescription)")
        handleError(error)
    }
    
    isLoading = false
}
```

---

## 🧪 Test de l'Implémentation

### Test Backend

```bash
# Tester l'endpoint
curl -X POST http://localhost:3005/ai/routine/analyze \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "evenements": [
      {
        "id": "1",
        "titre": "Cours Math",
        "type": "cours",
        "date": "2025-01-15",
        "heureDebut": "09:00",
        "heureFin": "11:00"
      }
    ],
    "disponibilites": [
      {
        "id": "1",
        "jour": "Lundi",
        "heureDebut": "14:00",
        "heureFin": "18:00"
      }
    ],
    "dateDebut": "2025-01-15",
    "dateFin": "2025-01-22"
  }'
```

### Test iOS

L'analyse se lancera automatiquement depuis `RoutineBalanceView` quand l'utilisateur ouvre l'écran.

---

## ✅ Checklist d'Implémentation

- [ ] Obtenir la clé API Gemini
- [ ] Installer les dépendances backend
- [ ] Créer les fichiers backend (module, service, controller, DTO)
- [ ] Configurer Redis (optionnel mais recommandé)
- [ ] Ajouter variables d'environnement
- [ ] Tester l'endpoint backend
- [ ] Modifier AIRoutineService iOS
- [ ] Mettre à jour RoutineBalanceViewModel
- [ ] Tester dans l'app iOS
- [ ] Vérifier les logs et erreurs

---

## 🎯 Résultat Attendu

Une fois implémenté, l'application utilisera **Google Gemini Pro** pour générer des recommandations intelligentes et personnalisées pour chaque étudiant, **100% gratuitement** ! 🚀

