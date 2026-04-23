# Fix: Framework 'Pods_Runner' not found

## ✅ Solution

### Étape 1 : Ouvrir le Workspace (IMPORTANT)

**NE PAS ouvrir `Runner.xcodeproj`**  
**OUVRIR `Runner.xcworkspace`** à la place

1. Fermez Xcode si ouvert
2. Ouvrez le fichier : `ios/Runner.xcworkspace` (pas `.xcodeproj`)
3. C'est crucial car CocoaPods nécessite le workspace

### Étape 2 : Nettoyer le Build

Dans Xcode :
1. **Product → Clean Build Folder** (⇧⌘K)
2. Attendez que le nettoyage soit terminé

### Étape 3 : Vérifier les Paramètres de Build

1. Dans Xcode, sélectionnez le projet **Runner** dans le navigateur
2. Sélectionnez la cible **Runner**
3. Allez dans l'onglet **Build Settings**
4. Cherchez **"Framework Search Paths"**
5. Vérifiez qu'il contient : `$(inherited)` et `"${PODS_CONFIGURATION_BUILD_DIR}"`

### Étape 4 : Vérifier les Configurations

1. Dans **Build Settings**, cherchez **"Configuration Files"**
2. Vérifiez que :
   - **Debug** : `Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig`
   - **Release** : `Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig`
   - **Profile** : `Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig`

### Étape 5 : Reconstruire

1. **Product → Build** (⌘B)
2. Si ça ne fonctionne toujours pas, essayez :
   ```bash
   cd ios
   flutter clean
   pod deintegrate
   pod install
   ```
   Puis dans Xcode : **Product → Clean Build Folder** puis **Product → Build**

## 🔍 Vérification

Si les pods sont correctement installés, vous devriez voir :
- `ios/Pods/` directory existe
- `ios/Pods/Target Support Files/Pods-Runner/` contient les fichiers `.xcconfig`
- `ios/Runner.xcworkspace` existe (pas seulement `.xcodeproj`)

## ⚠️ Erreurs Communes

1. **Ouvrir `.xcodeproj` au lieu de `.xcworkspace`** → Les pods ne seront pas trouvés
2. **Build folder pas nettoyé** → Anciens fichiers peuvent causer des conflits
3. **Configuration files manquants** → Les fichiers `.xcconfig` doivent être inclus

## 🚀 Alternative : Utiliser Flutter CLI

Si Xcode continue à avoir des problèmes, utilisez Flutter CLI :

```bash
cd konnected_beauty
flutter clean
cd ios
pod deintegrate
pod install
cd ..
flutter build ios --release
```

Puis ouvrez le workspace dans Xcode et build.

