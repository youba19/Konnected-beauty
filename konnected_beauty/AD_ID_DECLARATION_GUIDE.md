# Guide de déclaration d'identifiant publicitaire (Ad ID)

## Problème
Google Play Console exige que toutes les apps ciblant Android 13 (API 33) ou supérieur déclarent si elles utilisent un identifiant publicitaire (Ad ID).

## Solution appliquée

### 1. Permission ajoutée dans AndroidManifest.xml
```xml
<uses-permission android:name="com.google.android.gms.permission.AD_ID"/>
```

Cette permission déclare que l'app peut utiliser l'identifiant publicitaire.

### 2. Configuration Firebase Analytics
```xml
<meta-data
    android:name="google_analytics_adid_collection_enabled"
    android:value="true" />
```

Cette métadonnée indique que Firebase Analytics peut collecter l'Ad ID pour l'analyse.

## Options dans Google Play Console

Lorsque vous téléversez votre app, Google Play Console vous demandera :

**"Votre app utilise-t-elle un identifiant publicitaire ?"**

### Option 1 : Oui (recommandé si vous utilisez Firebase Analytics)
- ✅ **Sélectionnez "Oui"** si vous utilisez Firebase Analytics pour :
  - Mesurer les conversions publicitaires
  - Analyser le comportement des utilisateurs
  - Suivre les événements d'application

- **Justification** : Firebase Analytics peut utiliser l'Ad ID pour améliorer la précision des analyses.

### Option 2 : Non (si vous ne voulez pas utiliser l'Ad ID)
Si vous préférez ne pas utiliser l'Ad ID :

1. **Modifier AndroidManifest.xml** :
   - Retirer la permission : `<uses-permission android:name="com.google.android.gms.permission.AD_ID"/>`
   - Changer la métadonnée : `android:value="false"` pour `google_analytics_adid_collection_enabled`

2. **Dans Google Play Console** :
   - Sélectionnez "Non" pour la question sur l'Ad ID

## Vérification

Pour vérifier si votre app utilise réellement l'Ad ID :

1. **Vérifier les dépendances** :
   - `firebase_analytics` : Peut utiliser l'Ad ID
   - Autres SDK publicitaires : Vérifiez leur documentation

2. **Tester l'app** :
   - Utilisez des outils comme `adb shell dumpsys package` pour voir les permissions utilisées

## Recommandation

**Pour cette app** : Comme vous utilisez Firebase Analytics, il est recommandé de :
- ✅ Garder la permission Ad ID dans le manifest
- ✅ Sélectionner "Oui" dans Google Play Console
- ✅ Expliquer que l'Ad ID est utilisé uniquement pour Firebase Analytics

## Références

- [Google Play - Déclaration d'identifiant publicitaire](https://support.google.com/googleplay/android-developer/answer/9888179)
- [Firebase Analytics - Ad ID](https://firebase.google.com/docs/analytics/android/events)



