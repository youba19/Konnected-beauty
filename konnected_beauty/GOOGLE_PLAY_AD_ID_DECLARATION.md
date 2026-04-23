# Déclaration d'identifiant publicitaire - Configuration "Non"

## Configuration actuelle

Votre app est configurée pour **ne pas utiliser l'identifiant publicitaire (Ad ID)**.

### Modifications appliquées

1. ✅ **Permission AD_ID retirée** du AndroidManifest.xml
2. ✅ **Firebase Analytics Ad ID désactivé** : `google_analytics_adid_collection_enabled = false`
3. ✅ **Bundle reconstruit** sans déclaration d'Ad ID

## Réponse dans Google Play Console

### Question : "Votre app utilise-t-elle un identifiant publicitaire ?"

**Réponse : NON** ✅

### Justification

Votre app utilise uniquement :
- ✅ **Firebase Cloud Messaging** pour les notifications push
- ✅ **Firebase Analytics** (avec Ad ID désactivé)
- ❌ **Aucun SDK publicitaire** (Google Mobile Ads, etc.)
- ❌ **Aucune publicité** dans l'app

### Détails techniques

- **Firebase Messaging** : N'utilise pas l'Ad ID, seulement les tokens FCM
- **Firebase Analytics** : Ad ID collection explicitement désactivé via `google_analytics_adid_collection_enabled = false`
- **Autres SDK** : Aucun SDK publicitaire présent dans les dépendances

## Vérification

Pour vérifier que votre app n'utilise pas l'Ad ID :

1. **Vérifier le manifest** : Aucune permission `com.google.android.gms.permission.AD_ID`
2. **Vérifier les dépendances** : Aucun SDK publicitaire dans `pubspec.yaml`
3. **Firebase Analytics** : Ad ID collection désactivé

## Fichiers modifiés

- `android/app/src/main/AndroidManifest.xml`
  - Permission AD_ID : ❌ Retirée
  - `google_analytics_adid_collection_enabled` : `false`

## Bundle créé

- **Fichier** : `build/app/outputs/bundle/release/app-release.aab`
- **Taille** : 49.9 MB
- **Version** : 1.0.3+19
- **Ad ID** : Non utilisé ✅

## Instructions pour Google Play Console

1. Téléversez le nouveau bundle
2. À la question "Votre app utilise-t-elle un identifiant publicitaire ?"
   - **Sélectionnez "Non"** ✅
3. Vous n'avez pas besoin de remplir les autres champs (Analyse, Publicité, etc.) car vous avez répondu "Non"

## Note importante

Si vous ajoutez plus tard un SDK qui utilise l'Ad ID (comme Google Mobile Ads), vous devrez :
1. Réactiver la permission AD_ID dans le manifest
2. Répondre "Oui" dans Google Play Console
3. Sélectionner les raisons d'utilisation appropriées



