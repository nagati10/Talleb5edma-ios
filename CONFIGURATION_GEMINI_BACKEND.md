# 🔧 Configuration Gemini dans le Backend NestJS

## ⚠️ Problème Actuel

Le backend retourne l'erreur :
```
"GEMINI_API_KEY est requise. Veuillez l'ajouter dans votre fichier .env"
```

## ✅ Solution : Configurer la Clé API Gemini

### Étape 1 : Obtenir la Clé API Gemini (5 minutes)

1. Aller sur https://makersuite.google.com/app/apikey
2. Se connecter avec votre compte Google
3. Cliquer sur "Create API Key"
4. Copier la clé générée (format: `AIza...`)

### Étape 2 : Ajouter la Clé dans le Backend

#### Option A : Fichier .env (Recommandé)

Créer ou modifier le fichier `.env` à la racine de votre projet backend :

```bash
# .env
GEMINI_API_KEY=AIzaSy...votre_cle_ici
REDIS_HOST=localhost
REDIS_PORT=6379
```

#### Option B : Variables d'Environnement Système

```bash
export GEMINI_API_KEY=AIzaSy...votre_cle_ici
```

### Étape 3 : Vérifier la Configuration

Dans votre service backend (`ai-routine.service.ts`), vérifiez que la clé est bien chargée :

```typescript
constructor(
  @Inject(CACHE_MANAGER) private cacheManager: Cache,
) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    this.logger.error('GEMINI_API_KEY non définie dans les variables d\'environnement');
    throw new Error('GEMINI_API_KEY est requise');
  }
  
  this.genAI = new GoogleGenerativeAI(apiKey);
  this.model = this.genAI.getGenerativeModel({ 
    model: 'gemini-1.5-flash', // ⚠️ IMPORTANT: Utiliser gemini-1.5-flash (gemini-pro n'existe plus)
    generationConfig: {
      temperature: 0.7,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 2048,
    },
  });
}
```

### Étape 4 : Redémarrer le Backend

Après avoir ajouté la clé, redémarrez votre serveur NestJS :

```bash
npm run start:dev
```

## 🧪 Test

Une fois configuré, testez l'endpoint :

```bash
curl -X POST http://localhost:3005/ai/routine/analyze \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "evenements": [
      {
        "id": "test-1",
        "titre": "Cours Math",
        "type": "cours",
        "date": "2025-11-24",
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
    "dateDebut": "2025-11-24",
    "dateFin": "2025-12-01"
  }'
```

## ✅ Résultat Attendu

Une fois configuré, vous devriez voir :
- ✅ L'analyse Gemini fonctionne
- ✅ Des recommandations personnalisées générées
- ✅ Plus d'erreur 500

## 🔒 Sécurité

⚠️ **Important** : Ne jamais commiter le fichier `.env` dans Git !

Ajoutez `.env` dans `.gitignore` :
```
.env
.env.local
```

## 📝 Checklist

- [ ] Clé API Gemini obtenue
- [ ] Fichier `.env` créé avec `GEMINI_API_KEY`
- [ ] Backend redémarré
- [ ] Test de l'endpoint réussi
- [ ] `.env` ajouté à `.gitignore`

---

Une fois la clé configurée, l'analyse Gemini fonctionnera automatiquement ! 🚀

