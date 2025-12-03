# Format DTO Backend pour /ai/routine/analyze

## 📋 Format JSON Attendu par le Backend

Le backend NestJS attend ce format exact pour la validation :

```json
{
  "evenements": [
    {
      "id": "string",
      "titre": "string",
      "type": "string",
      "date": "string (yyyy-MM-dd)",
      "heureDebut": "string (HH:mm)",
      "heureFin": "string (HH:mm)",
      "lieu": "string (optionnel)",
      "tarifHoraire": "number (optionnel)",
      "couleur": "string (optionnel)"
    }
  ],
  "disponibilites": [
    {
      "id": "string",
      "jour": "string",
      "heureDebut": "string (HH:mm)",
      "heureFin": "string (HH:mm) (optionnel)"
    }
  ],
  "preferences": {
    "educationLevel": "string (optionnel)",
    "studyField": "string (optionnel)",
    "searchTypes": ["string"] (optionnel),
    "mainMotivation": "string (optionnel)",
    "softSkills": ["string"] (optionnel),
    "languageLevels": [] (optionnel),
    "interests": ["string"] (optionnel)
  },
  "dateDebut": "string (yyyy-MM-dd)",
  "dateFin": "string (yyyy-MM-dd)"
}
```

## 🔧 DTO Backend NestJS Requis

### routine-input.dto.ts

```typescript
import { IsArray, IsString, IsOptional, IsDateString, ValidateNested, IsNumber } from 'class-validator';
import { Type } from 'class-transformer';

export class EvenementDto {
  @IsString()
  id: string;

  @IsString()
  titre: string;

  @IsString()
  type: string;

  @IsString()
  date: string; // Format: "yyyy-MM-dd"

  @IsString()
  heureDebut: string; // Format: "HH:mm"

  @IsString()
  heureFin: string; // Format: "HH:mm"

  @IsOptional()
  @IsString()
  lieu?: string;

  @IsOptional()
  @IsNumber()
  tarifHoraire?: number;

  @IsOptional()
  @IsString()
  couleur?: string;
}

export class DisponibiliteDto {
  @IsString()
  id: string;

  @IsString()
  jour: string;

  @IsString()
  heureDebut: string; // Format: "HH:mm"

  @IsOptional()
  @IsString()
  heureFin?: string; // Format: "HH:mm"
}

export class UserPreferencesDto {
  @IsOptional()
  @IsString()
  educationLevel?: string;

  @IsOptional()
  @IsString()
  studyField?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  searchTypes?: string[];

  @IsOptional()
  @IsString()
  mainMotivation?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  softSkills?: string[];

  @IsOptional()
  @IsArray()
  languageLevels?: any[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  interests?: string[];
}

export class RoutineInputDataDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => EvenementDto)
  evenements: EvenementDto[];

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DisponibiliteDto)
  disponibilites: DisponibiliteDto[];

  @IsOptional()
  @ValidateNested()
  @Type(() => UserPreferencesDto)
  preferences?: UserPreferencesDto;

  @IsString()
  @IsDateString()
  dateDebut: string; // Format: "yyyy-MM-dd"

  @IsString()
  @IsDateString()
  dateFin: string; // Format: "yyyy-MM-dd"
}
```

## ⚠️ Problème Actuel

L'erreur 400 indique que le backend ne valide pas correctement les données. Causes possibles :

1. **DTOs manquants** : Le backend n'a pas les DTOs avec les validations
2. **Format incorrect** : Les données envoyées ne correspondent pas au format attendu
3. **Validation trop stricte** : Les validations class-validator rejettent les données

## ✅ Solution

### Option 1 : Créer les DTOs dans le Backend (Recommandé)

Créer le fichier `src/ai-routine/dto/routine-input.dto.ts` avec le code ci-dessus.

### Option 2 : Simplifier la Validation (Temporaire)

Si vous voulez tester rapidement, simplifiez les validations :

```typescript
export class RoutineInputDataDto {
  evenements: any[];
  disponibilites: any[];
  preferences?: any;
  dateDebut: string;
  dateFin: string;
}
```

### Option 3 : Vérifier les Données Envoyées

Ajoutez des logs dans le controller backend pour voir ce qui est reçu :

```typescript
@Post('analyze')
async analyzeRoutine(@Request() req, @Body() data: any) {
  console.log('📥 Données reçues:', JSON.stringify(data, null, 2));
  // ... reste du code
}
```

## 🧪 Test

Pour tester, envoyez ce JSON minimal :

```json
{
  "evenements": [
    {
      "id": "test-1",
      "titre": "Test Cours",
      "type": "cours",
      "date": "2025-01-15",
      "heureDebut": "09:00",
      "heureFin": "11:00"
    }
  ],
  "disponibilites": [
    {
      "id": "test-1",
      "jour": "Lundi",
      "heureDebut": "14:00",
      "heureFin": "18:00"
    }
  ],
  "dateDebut": "2025-01-15",
  "dateFin": "2025-01-22"
}
```

