# Diagnostic des Notifications iOS

## 🔍 Checklist de Vérification

### 1. Vérifier les Logs de l'App

Lancez l'app et cherchez ces logs dans la console :

#### ✅ Logs de Succès Attendus :

```
🔔 Notification permission status: AuthorizationStatus.authorized
📱 iOS detected - waiting for APNS token...
📱 Checking for APNS token (attempt 1/10)...
✅ APNS Token received: ...
🔑 APNS token available, getting FCM token...
✅ FCM TOKEN SUCCESSFULLY RETRIEVED (iOS)!
🔑 Token: <votre-token-fcm>
📱 === AUTO-REGISTERING FCM TOKEN ===
👤 User Role: influencer (ou saloon)
✅ FCM token auto-registered successfully
```

#### ❌ Si vous voyez ces erreurs :

- `APNS Token not available yet` → Voir section 2
- `FCM token is not available yet` → Voir section 3
- `Failed to register FCM token` → Voir section 4

### 2. Vérifier la Configuration Xcode

1. Ouvrez `ios/Runner.xcworkspace` dans Xcode
2. Sélectionnez le target "Runner"
3. Onglet **Signing & Capabilities**
4. Vérifiez que **Push Notifications** apparaît dans la liste
5. Si absent, cliquez sur **+ Capability** et ajoutez-le

### 3. Vérifier les Entitlements

Vérifiez que ces fichiers contiennent bien la configuration :

**ios/Runner/RunnerDebug.entitlements** :
```xml
<key>aps-environment</key>
<string>development</string>
```

**ios/Runner/RunnerRelease.entitlements** :
```xml
<key>aps-environment</key>
<string>production</string>
```

### 4. Vérifier Firebase Console

1. Allez sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez votre projet
3. **Project Settings** → **Cloud Messaging**
4. Section **Apple app configuration**
5. Vérifiez que :
   - Le certificat/clé APNS est bien uploadé
   - Le statut est "Active" ou "Valid"
   - Pas d'erreur affichée

### 5. Vérifier les Permissions iOS

Sur votre iPhone/iPad :
1. **Settings** → **[Votre App]**
2. **Notifications**
3. Vérifiez que :
   - **Allow Notifications** est activé
   - **Alert Style** n'est pas "None"
   - Les types de notifications sont activés

### 6. Tester l'Envoi de Notification

#### Depuis Firebase Console :

1. Firebase Console → **Cloud Messaging**
2. Cliquez sur **Send your first message** ou **New notification**
3. Entrez un titre et un message
4. Cliquez sur **Send test message**
5. **Collez le token FCM** (copié depuis les logs de l'app)
6. Cliquez sur **Test**

#### Vérifier les Logs :

Si la notification est envoyée, vous devriez voir :
```
📨 Foreground message received: ...
📨 Background message received: ...
```

### 7. Vérifier que le Token est Enregistré

Dans les logs, cherchez :
```
📱 === REGISTERING FCM TOKEN ===
👤 User Role: influencer
🔗 Endpoint: /influencer-notification/register-token
📊 Response status: 200
✅ FCM token registered successfully
```

Si le status n'est pas 200, il y a un problème avec l'API.

### 8. Vérifier le Bundle ID

1. Dans Xcode, vérifiez le **Bundle Identifier** :
   - Target Runner → General → Bundle Identifier
2. Dans Firebase Console :
   - Project Settings → Your apps → iOS app
   - Vérifiez que le Bundle ID correspond

### 9. Vérifier GoogleService-Info.plist

1. Vérifiez que `ios/Runner/GoogleService-Info.plist` existe
2. Vérifiez que le Bundle ID dans le fichier correspond à votre app

### 10. Rebuild Complet

Après toutes les modifications :

```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter run --release --device-id=<votre-device-id>
```

## 🐛 Problèmes Courants et Solutions

### Problème : Token FCM obtenu mais notifications ne fonctionnent pas

**Causes possibles :**
1. Certificat APNS non configuré dans Firebase
2. Bundle ID ne correspond pas
3. App en mode Release mais certificat Development (ou vice versa)

**Solution :**
- Vérifiez le certificat dans Firebase Console
- Utilisez "Sandbox & Production" pour les deux environnements

### Problème : Notifications reçues mais pas affichées

**Causes possibles :**
1. Permissions non accordées
2. App en foreground sans gestion des notifications foreground

**Solution :**
- Vérifiez Settings → App → Notifications
- L'app gère déjà les notifications foreground (voir `firebase_notification_service.dart`)

### Problème : Token enregistré mais backend n'envoie pas

**Vérification :**
- Vérifiez que le token est bien stocké dans votre base de données
- Vérifiez que votre backend utilise le bon token
- Testez depuis Firebase Console d'abord

## 📋 Commandes de Diagnostic

### Vérifier les logs en temps réel :

```bash
flutter run --release --device-id=<votre-device-id> 2>&1 | grep -E "(FCM|APNS|notification|token)"
```

### Vérifier la configuration iOS :

```bash
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -showBuildSettings | grep -i bundle
```

## 🔗 Prochaines Étapes

1. **Copiez tous les logs** de l'app au démarrage et après login
2. **Testez depuis Firebase Console** avec le token FCM
3. **Vérifiez Firebase Console** que le certificat est bien configuré
4. **Vérifiez les permissions** sur l'appareil iOS

Si le problème persiste, partagez :
- Les logs complets au démarrage
- Les logs lors du login
- Les logs lors de l'enregistrement du token
- Le résultat du test depuis Firebase Console

