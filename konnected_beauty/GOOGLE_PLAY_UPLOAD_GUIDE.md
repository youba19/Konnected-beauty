# Guide de téléversement sur Google Play Console

## Fichiers à téléverser

### 1. App Bundle (OBLIGATOIRE)
- **Fichier** : `build/app/outputs/bundle/release/app-release.aab`
- **Taille** : 27.9 MB
- **Version** : 1.0.3+14
- **Target SDK** : 35
- **Support 16KB** : Configuré ✅

### 2. Fichier de désobscurcissement (RECOMMANDÉ)
- **Fichier** : `build/app/outputs/mapping/release/mapping.txt`
- **Taille** : 12 MB
- **Description** : Nécessaire pour désobscurcir les rapports de crash et les ANR
- **Emplacement dans Google Play Console** : 
  - Allez dans **Version** → **App Bundle Explorer** → **Téléverser le fichier de désobscurcissement**

### 3. Symboles de débogage natifs (RECOMMANDÉ)
- **Note** : Pour les apps Flutter, les symboles natifs sont généralement inclus dans le bundle.
- Si Google Play demande explicitement un fichier de symboles natifs :
  - Les symboles sont générés automatiquement lors de la construction
  - Ils peuvent être extraits du bundle si nécessaire
  - Flutter gère les symboles natifs différemment des apps Android natives

## Configuration actuelle

### ✅ Résolu
1. **API cible 35** : Configuré ✅
2. **Support 16KB page size** : Configuré ✅
3. **R8/ProGuard activé** : Configuré ✅
4. **Fichier de mapping généré** : Disponible ✅

### ⚠️ Avertissements restants

#### 1. Appareils non supportés (28 appareils)
- **Cause** : Changement de targetSdk à 35 ou autres modifications de configuration
- **Action** : C'est un avertissement, pas une erreur. Vous pouvez continuer.
- **Impact** : Ces appareils ne recevront pas les mises à jour, mais l'app fonctionnera toujours pour les utilisateurs existants
- **Recommandation** : Vérifiez dans Google Play Console quels appareils sont concernés et évaluez si c'est acceptable

#### 2. Symboles de débogage natifs
- **Statut** : Pour Flutter, les symboles sont généralement inclus dans le bundle
- **Action** : Si Google Play demande explicitement un fichier, vous pouvez :
  1. Extraire les symboles du bundle
  2. Ou ignorer cet avertissement (les symboles sont déjà dans le bundle)

## Instructions de téléversement

### Étape 1 : Téléverser l'App Bundle
1. Connectez-vous à [Google Play Console](https://play.google.com/console)
2. Sélectionnez votre app
3. Allez dans **Production** (ou **Testing** → **Internal testing**)
4. Cliquez sur **Créer une nouvelle version**
5. Téléversez `app-release.aab`
6. Remplissez les notes de version

### Étape 2 : Téléverser le fichier de mapping (optionnel mais recommandé)
1. Dans la page de version, allez dans **App Bundle Explorer**
2. Cliquez sur **Téléverser le fichier de désobscurcissement**
3. Téléversez `mapping.txt`

### Étape 3 : Gérer les avertissements
- **Appareils non supportés** : Acceptez l'avertissement si vous êtes d'accord avec la perte de compatibilité
- **Symboles natifs** : Pour Flutter, cet avertissement peut généralement être ignoré car les symboles sont dans le bundle

## Informations techniques

- **Version Code** : 14
- **Version Name** : 1.0.3
- **Min SDK** : 21 (Android 5.0)
- **Target SDK** : 35 (Android 15)
- **Compile SDK** : 34
- **R8/ProGuard** : Activé
- **Obfuscation** : Activée
- **Shrink Resources** : Activé

## Notes importantes

1. **Conservez le fichier mapping.txt** : Vous en aurez besoin pour désobscurcir les rapports de crash futurs
2. **Version Code** : Ne peut pas être réutilisé. Si vous devez créer une nouvelle version, incrémentez le versionCode dans `pubspec.yaml`
3. **Appareils non supportés** : Vérifiez la liste des appareils concernés dans Google Play Console avant de publier

## Commandes utiles

### Reconstruire le bundle
```bash
flutter clean
flutter pub get
flutter build appbundle --release --split-debug-info=build/app/debug-info --obfuscate
```

### Localiser les fichiers
```bash
# App Bundle
ls -lh build/app/outputs/bundle/release/app-release.aab

# Fichier de mapping
ls -lh build/app/outputs/mapping/release/mapping.txt
```



