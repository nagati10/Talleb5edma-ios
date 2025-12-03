# 🔧 Instructions pour ajouter Google Sign-In au projet

## ⚠️ Erreur actuelle
```
No such module 'GoogleSignIn'
```

Cette erreur apparaît car le package Google Sign-In n'a pas encore été ajouté au projet.

## 📝 Étapes pour ajouter le package

### Méthode 1 : Via l'interface Xcode (Recommandé)

1. **Ouvrez votre projet dans Xcode**
   - Double-cliquez sur `Taleb_5edma.xcodeproj`

2. **Ouvrez le menu Package Dependencies**
   - Dans la barre de menu : **File** → **Add Package Dependencies...**
   - Ou cliquez sur le projet dans le navigateur (icône bleue en haut à gauche)
   - Sélectionnez le projet "Taleb_5edma" (pas le target)
   - Allez dans l'onglet **Package Dependencies**

3. **Ajoutez le package Google Sign-In**
   - Cliquez sur le bouton **+** en bas à gauche de la section "Package Dependencies"
   - Dans le champ de recherche, collez cette URL :
     ```
     https://github.com/google/GoogleSignIn-iOS
     ```
   - Cliquez sur **Add Package**

4. **Sélectionnez le produit**
   - Dans la fenêtre qui s'ouvre, sélectionnez **GoogleSignIn** dans la liste des produits
   - Assurez-vous que le target "Taleb_5edma" est sélectionné à droite
   - Cliquez sur **Add Package**

5. **Vérifiez l'ajout**
   - Le package devrait apparaître dans la section "Package Dependencies" du projet
   - Vous devriez voir "GoogleSignIn-iOS" dans la liste

6. **Recompilez le projet**
   - Appuyez sur **⌘ + B** (Cmd + B) pour compiler
   - L'erreur devrait disparaître

### Méthode 2 : Via la ligne de commande (Alternative)

Si vous préférez utiliser la ligne de commande, vous pouvez utiliser `xcodebuild` mais la méthode graphique est plus simple.

## ✅ Vérification

Après avoir ajouté le package, vous devriez pouvoir :
- Compiler le projet sans erreur
- Voir le package dans la liste des dépendances
- Utiliser `import GoogleSignIn` dans vos fichiers Swift

## 🔍 Si l'erreur persiste

1. **Nettoyez le build**
   - **Product** → **Clean Build Folder** (⌘ + Shift + K)

2. **Fermez et rouvrez Xcode**
   - Parfois Xcode a besoin d'être redémarré pour reconnaître les nouveaux packages

3. **Vérifiez que le package est bien ajouté**
   - Dans Xcode, sélectionnez le projet
   - Allez dans l'onglet **Package Dependencies**
   - Vérifiez que "GoogleSignIn-iOS" est présent

4. **Vérifiez le target**
   - Sélectionnez le target "Taleb_5edma"
   - Allez dans l'onglet **General**
   - Dans "Frameworks, Libraries, and Embedded Content", vous devriez voir "GoogleSignIn"

## 📚 Ressources

- [Documentation officielle Google Sign-In iOS](https://developers.google.com/identity/sign-in/ios)
- [Guide Swift Package Manager](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)

