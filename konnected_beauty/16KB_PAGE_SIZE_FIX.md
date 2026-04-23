# Solution pour le support 16KB Page Size

## Problème
Google Play Console indique : "Votre appli ne prend pas en charge les tailles de page de mémoire de 16 ko"

## Cause
Le support 16KB page size nécessite que :
1. Toutes les bibliothèques natives (.so) soient compilées avec l'alignement 16KB
2. Le moteur Flutter et les plugins soient compatibles avec 16KB
3. Le NDK utilisé supporte 16KB (NDK r26+)

## Solution recommandée

### Option 1 : Mettre à jour Flutter (RECOMMANDÉ)
Flutter 3.22.3 est une version ancienne. Les versions récentes de Flutter (3.24+) incluent le support 16KB.

```bash
# Mettre à jour Flutter
flutter upgrade

# Vérifier la version
flutter --version

# Reconstruire le bundle
flutter clean
flutter pub get
flutter build appbundle --release --split-debug-info=build/app/debug-info --obfuscate
```

### Option 2 : Vérifier les bibliothèques natives
Si vous ne pouvez pas mettre à jour Flutter immédiatement, vérifiez quelles bibliothèques ne sont pas alignées :

```bash
# Extraire et vérifier les bibliothèques natives du bundle
bundletool dump native --bundle=app-release.aab | grep -i "page size"

# Ou utiliser readelf sur les .so files
readelf -l lib/arm64-v8a/*.so | grep -i pagesize
```

### Option 3 : Mettre à jour les plugins
Certains plugins peuvent avoir des bibliothèques natives non compatibles. Mettez à jour tous les plugins :

```bash
flutter pub upgrade
```

## Configuration actuelle

### ✅ Déjà configuré
- Target SDK : 35
- NDK configuration avec abiFilters
- Métadonnées dans AndroidManifest.xml
- Packaging options configurées

### ⚠️ À vérifier
- Version de Flutter (actuellement 3.22.3 - ancienne)
- Version du NDK utilisé par Flutter
- Compatibilité des plugins avec 16KB

## Actions immédiates

1. **Mettre à jour Flutter** (si possible)
   ```bash
   flutter upgrade
   ```

2. **Mettre à jour les dépendances**
   ```bash
   flutter pub upgrade
   ```

3. **Reconstruire le bundle**
   ```bash
   flutter clean
   flutter build appbundle --release --split-debug-info=build/app/debug-info --obfuscate
   ```

4. **Tester avec un émulateur 16KB** (optionnel mais recommandé)
   - Créer un émulateur Android avec page size 16KB
   - Tester l'application

## Solution temporaire (SI VOUS NE POUVEZ PAS METTRE À JOUR FLUTTER)

Si vous ne pouvez absolument pas mettre à jour Flutter maintenant, vous pouvez temporairement réduire le targetSdk à 34 :

```gradle
// Dans android/app/build.gradle
targetSdk = 34  // Au lieu de 35
```

Et dans AndroidManifest.xml :
```xml
<uses-sdk android:targetSdkVersion="34" android:minSdkVersion="21" />
```

⚠️ **ATTENTION** : Cette solution n'est que temporaire. Google Play exigera API 35 à partir de novembre 2025.

## Note importante

Le support 16KB est **obligatoire** pour les apps ciblant API 35 à partir du 1er novembre 2025. 

**La seule solution permanente est de mettre à jour Flutter vers une version récente (3.24+).**

Un script automatique est disponible : `update_flutter_and_build.sh`

## Références

- [Android 16KB Page Size Guide](https://developer.android.com/guide/practices/page-sizes)
- [Flutter Release Notes](https://docs.flutter.dev/release/breaking-changes)

