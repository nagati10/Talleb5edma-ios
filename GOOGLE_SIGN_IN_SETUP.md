# Configuration Google Sign-In

Ce guide vous explique comment configurer Google Sign-In pour l'application Taleb 5edma.

## 📋 Prérequis

1. Un compte Google Cloud Platform
2. Xcode installé sur votre Mac
3. L'application Xcode ouverte

## 🔧 Étapes de configuration

### ⚠️ ÉTAPE CRITIQUE : Ajouter le package Google Sign-In via Swift Package Manager

**Cette étape est OBLIGATOIRE avant de compiler le projet !**

1. Ouvrez votre projet dans Xcode
   - Double-cliquez sur `Taleb_5edma.xcodeproj`

2. Allez dans **File** → **Add Package Dependencies...**
   - Ou : Sélectionnez le projet (icône bleue) → Onglet **Package Dependencies** → Bouton **+**

3. Collez l'URL suivante dans le champ de recherche :
   ```
   https://github.com/google/GoogleSignIn-iOS
   ```

4. Cliquez sur **Add Package**

5. Sélectionnez **GoogleSignIn** dans la liste des produits
   - Assurez-vous que le target "Taleb_5edma" est sélectionné

6. Cliquez sur **Add Package**

7. **Vérifiez que le package est ajouté**
   - Le package devrait apparaître dans la section "Package Dependencies"
   - Compilez le projet (⌘ + B) pour vérifier qu'il n'y a plus d'erreur

**📌 Si vous voyez l'erreur "No such module 'GoogleSignIn'", c'est que cette étape n'a pas été effectuée !**

### 2. Créer un projet Google Cloud Platform

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un nouveau projet ou sélectionnez un projet existant
3. Activez l'API **Google Sign-In** pour votre projet

### 3. Configurer OAuth 2.0

1. Dans Google Cloud Console, allez dans **APIs & Services** → **Credentials**
2. Cliquez sur **Create Credentials** → **OAuth client ID**
3. Sélectionnez **iOS** comme type d'application
4. Entrez votre **Bundle Identifier** (ex: `Taleb5edma.Taleb-5edma`)
5. Copiez le **Client ID** généré

### 4. Configurer le Client ID dans l'application

Vous avez deux options :

#### Option A : Utiliser un fichier GoogleService-Info.plist (Recommandé)

1. Téléchargez le fichier `GoogleService-Info.plist` depuis Google Cloud Console
2. Ajoutez-le à votre projet Xcode dans le dossier `Taleb_5edma`
3. Assurez-vous qu'il est inclus dans le target de l'application

#### Option B : Configurer directement dans le code

1. Ouvrez `Taleb_5edma/Services/GoogleSignInService.swift`
2. Remplacez `"YOUR_GOOGLE_CLIENT_ID_HERE"` par votre vrai Client ID :
   ```swift
   let clientId = "VOTRE_CLIENT_ID_ICI"
   ```

### 5. Configurer l'URL Scheme

1. Dans Xcode, sélectionnez votre projet
2. Allez dans l'onglet **Info**
3. Ajoutez une nouvelle **URL Type** :
   - **Identifier**: `GoogleSignIn`
   - **URL Schemes**: Votre Client ID inversé (ex: `com.googleusercontent.apps.VOTRE_CLIENT_ID`)

   ⚠️ **Important**: L'URL Scheme doit être l'inverse de votre Client ID.
   Si votre Client ID est `123456789-abc.apps.googleusercontent.com`,
   l'URL Scheme doit être `com.googleusercontent.apps.123456789-abc`

### 6. Configurer le backend

Assurez-vous que votre backend NestJS a un endpoint `/auth/google` qui :
- Accepte un POST avec `{ "idToken": "..." }`
- Vérifie le token Google
- Crée ou connecte l'utilisateur
- Retourne un `AuthResponse` avec `user` et `access_token`

## ✅ Vérification

1. Compilez et lancez l'application
2. Cliquez sur "Continue with Google" dans l'écran de login ou sign up
3. Vous devriez voir la fenêtre de connexion Google s'ouvrir

## 🐛 Dépannage

### Erreur : "Google Sign-In n'est pas configuré"
- Vérifiez que vous avez bien configuré le Client ID
- Vérifiez que le package GoogleSignIn est bien ajouté au projet

### Erreur : "URL Scheme non configuré"
- Vérifiez que l'URL Scheme dans Info.plist correspond à votre Client ID inversé

### Erreur : "Endpoint introuvable (404)"
- Vérifiez que votre backend a bien l'endpoint `/auth/google`
- Vérifiez que l'URL de base dans `APIConfig.swift` est correcte

## 📚 Ressources

- [Documentation Google Sign-In iOS](https://developers.google.com/identity/sign-in/ios)
- [Guide de configuration Google Sign-In](https://developers.google.com/identity/sign-in/ios/start-integrating)

