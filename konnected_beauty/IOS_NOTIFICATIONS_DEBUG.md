# Guide de Diagnostic - Notifications iOS

## 🔍 Vérification étape par étape

### 1. Vérifier les logs au démarrage

Lancez l'app et cherchez ces logs dans la console :

#### ✅ Logs attendus (succès) :
```
🔔 Notification permission status: AuthorizationStatus.authorized
📱 iOS detected - waiting for APNS token...
📱 Checking for APNS token (attempt 1/10)...
✅ APNS Token received: ...
🔑 APNS token available, getting FCM token...
✅ FCM TOKEN SUCCESSFULLY RETRIEVED (iOS)!
🔑 Token: <votre-token-fcm>
📱 === AUTO-REGISTERING FCM TOKEN ===
✅ FCM token auto-registered successfully
```

#### ❌ Logs d'erreur possibles :
- `APNS Token not available yet` → Voir section 2
- `FCM token is not available yet` → Voir section 3
- `Failed to register FCM token` → Voir section 4

### 2. Si "APNS Token not available yet"

**Causes possibles :**
1. ❌ **App testée sur iOS Simulator** (ne supporte pas les notifications push)
   - ✅ **Solution** : Utiliser un iPhone/iPad réel

2. ❌ **Push Notifications non activé dans Xcode**
   - ✅ **Solution** :
     - Ouvrir `ios/Runner.xcworkspace` dans Xcode
     - Sélectionner target "Runner"
     - Onglet "Signing & Capabilities"
     - Ajouter "Push Notifications" capability
     - Rebuild l'app

3. ❌ **Certificat APNS non configuré dans Firebase**
   - ✅ **Solution** :
     - Aller sur Firebase Console
     - Project Settings → Cloud Messaging
     - Télécharger certificat APNS ou configurer clé APNS

### 3. Si "FCM token is not available yet"

**Vérifier :**
- Le token APNS a-t-il été reçu ? (chercher `✅ APNS Token received`)
- Les permissions sont-elles accordées ? (Settings → App → Notifications)

### 4. Si "Failed to register FCM token"

**Vérifier les logs :**
```
📱 === REGISTERING FCM TOKEN ===
👤 User Role: influencer (ou saloon)
🔑 FCM Token: ...
🔗 Endpoint: /influencer-notification/register-token
📊 Response status: 200 (ou 201)
✅ FCM token registered successfully
```

**Si status != 200/201 :**
- Vérifier que l'utilisateur est bien connecté
- Vérifier que le token d'authentification est valide
- Vérifier l'endpoint API

### 5. Vérifier que le token est bien enregistré

**Après le login, cherchez :**
```
📱 === REGISTERING FCM TOKEN AFTER LOGIN ===
✅ FCM token available: ...
📱 === REGISTERING FCM TOKEN ===
✅ FCM token registered successfully after login
```

### 6. Tester l'envoi de notification

1. **Depuis Firebase Console :**
   - Cloud Messaging → Send test message
   - Entrer le token FCM (copié depuis les logs)
   - Envoyer

2. **Depuis votre backend :**
   - Vérifier que le token est bien stocké en base de données
   - Envoyer une notification via votre API

### 7. Vérifier les permissions iOS

**Dans l'appareil :**
- Settings → [Votre App] → Notifications
- Vérifier que "Allow Notifications" est activé
- Vérifier que "Alert Style" n'est pas "None"

### 8. Vérifier la configuration Firebase

**Dans Firebase Console :**
- Project Settings → Cloud Messaging
- Section "Apple app configuration"
- Vérifier que le certificat APNS est configuré
- Pour Development : certificat de développement
- Pour Production : certificat de production

### 9. Commandes de diagnostic

```bash
# Nettoyer et rebuild
flutter clean
cd ios
pod install
cd ..
flutter pub get
flutter run --release --device-id=<votre-device-id>
```

### 10. Logs à copier pour le support

Si le problème persiste, copiez ces logs :
1. Logs au démarrage de l'app
2. Logs lors du login
3. Logs lors de la réception du token FCM
4. Logs lors de l'enregistrement du token
5. Logs lors de l'envoi d'une notification test

## 📋 Checklist rapide

- [ ] App testée sur un **vrai appareil iOS** (pas simulateur)
- [ ] **Push Notifications** capability activée dans Xcode
- [ ] **Permissions** accordées dans Settings
- [ ] **Certificat APNS** configuré dans Firebase Console
- [ ] **Token FCM** reçu (voir logs)
- [ ] **Token FCM** enregistré dans le backend (voir logs)
- [ ] **GoogleService-Info.plist** présent dans ios/Runner/

## 🔗 Ressources

- [Firebase iOS Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Apple Push Notifications](https://developer.apple.com/documentation/usernotifications)

