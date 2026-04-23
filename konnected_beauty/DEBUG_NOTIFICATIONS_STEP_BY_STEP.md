# Debug des Notifications iOS - Guide Étape par Étape

## 🔍 Diagnostic Complet

### Étape 1 : Vérifier les Logs au Démarrage

Lancez l'app et **copiez TOUS les logs** qui commencent par :
- `🔔` (notifications)
- `📱` (iOS/APNS)
- `🔑` (token FCM)
- `✅` ou `❌`

**Logs CRITIQUES à vérifier :**

1. **Initialisation Firebase :**
   ```
   ✅ Firebase initialized successfully
   ✅ Background message handler registered
   🔔 Initializing Firebase Notification Service...
   ✅ Firebase Notification Service initialized
   ```

2. **Configuration des handlers :**
   ```
   🔔 === CONFIGURING MESSAGE HANDLERS ===
   ✅ Message handlers configured successfully
   ```

3. **Permission :**
   ```
   🔔 Notification permission status: AuthorizationStatus.authorized
   ✅ User granted notification permission
   ```

4. **Token APNS :**
   ```
   📱 === APNS TOKEN RECEIVED IN APPDELEGATE ===
   📱 APNS Token: <token-complet>
   ✅ APNS token set in Firebase Messaging
   ```

5. **Token FCM :**
   ```
   ✅ FCM TOKEN SUCCESSFULLY RETRIEVED (iOS)!
   🔑 Token: <token-complet>
   ```

6. **Enregistrement du token :**
   ```
   📱 === AUTO-REGISTERING FCM TOKEN ===
   ✅ FCM token auto-registered successfully
   ```

### Étape 2 : Tester depuis Firebase Console

1. **Copiez le token FCM complet** depuis les logs (après `🔑 Token:`)

2. **Firebase Console** → **Cloud Messaging** → **Send your first message**

3. **Créez une notification :**
   - Titre : "Test Notification"
   - Texte : "This is a test message"
   - Cliquez sur **Send test message**
   - Collez votre **token FCM complet**
   - Cliquez sur **Test**

4. **Vérifiez les logs selon l'état de l'app :**

   **Si l'app est EN FOREGROUND (ouverte) :**
   ```
   📨 === FOREGROUND MESSAGE RECEIVED ===
   📨 Message ID: ...
   📨 Title: Test Notification
   📨 Body: This is a test message
   🔔 === SHOWING LOCAL NOTIFICATION ===
   ✅ Local notification displayed successfully
   ```

   **Si l'app est EN BACKGROUND :**
   - La notification devrait apparaître automatiquement
   - En cliquant dessus, vous devriez voir :
   ```
   📨 === BACKGROUND MESSAGE OPENED ===
   ```

   **Si l'app est FERMÉE :**
   - La notification devrait apparaître
   - En ouvrant l'app depuis la notification :
   ```
   📨 === APP OPENED FROM TERMINATED STATE ===
   ```

### Étape 3 : Vérifier le Format de la Notification

**Important :** Pour iOS, la notification DOIT avoir un payload `notification` :

```json
{
  "notification": {
    "title": "Test Notification",
    "body": "This is a test message"
  },
  "data": {
    "key": "value"
  }
}
```

**❌ Ne fonctionne PAS sur iOS (data-only) :**
```json
{
  "data": {
    "title": "Test",
    "body": "Message"
  }
}
```

### Étape 4 : Vérifier le Certificat APNS dans Firebase

1. **Firebase Console** → **Project Settings** → **Cloud Messaging**
2. Section **Apple app configuration**
3. Vérifiez :
   - ✅ Certificat/clé APNS uploadé
   - ✅ Statut : "Active" ou "Valid"
   - ✅ Pas d'erreur rouge
   - ✅ Bundle ID correspond

### Étape 5 : Vérifier le Mode (Development vs Production)

**Important :** Le certificat APNS doit correspondre au mode :

- **Mode Debug/Development :** Certificat "Sandbox" ou "Sandbox & Production"
- **Mode Release :** Certificat "Production" ou "Sandbox & Production"

**Vérifiez dans Xcode :**
- Target Runner → Signing & Capabilities
- Vérifiez le mode (Debug ou Release)

**Vérifiez les Entitlements :**
- `RunnerDebug.entitlements` → `aps-environment: development`
- `RunnerRelease.entitlements` → `aps-environment: production`

### Étape 6 : Test Complet

1. **Fermez complètement l'app** (swipe up depuis multitasking)
2. **Envoyez une notification test** depuis Firebase Console
3. **Vérifiez :**
   - La notification apparaît-elle sur l'écran de verrouillage ?
   - La notification apparaît-elle dans le centre de notifications ?
   - En cliquant, l'app s'ouvre-t-elle ?

## 🐛 Problèmes Spécifiques

### Problème : Aucun log de notification reçue

**Causes possibles :**
1. Token FCM non enregistré dans Firebase
2. Certificat APNS non configuré ou invalide
3. Bundle ID ne correspond pas
4. Notification envoyée avec mauvais format

**Solutions :**
- Vérifiez que le token est bien enregistré (logs)
- Vérifiez le certificat dans Firebase Console
- Testez depuis Firebase Console directement

### Problème : Logs montrent notification reçue mais pas affichée

**Causes possibles :**
1. Permissions non accordées
2. Mode Do Not Disturb activé
3. App en foreground mais notification locale échoue

**Solutions :**
- Vérifiez Settings → App → Notifications
- Désactivez Do Not Disturb temporairement
- Vérifiez les logs : `✅ Local notification displayed successfully`

### Problème : Notification reçue en background mais pas en foreground

**Causes possibles :**
- Handler foreground non configuré (mais c'est déjà fait)
- Erreur dans `_showLocalNotification`

**Solutions :**
- Vérifiez les logs : `🔔 === SHOWING LOCAL NOTIFICATION ===`
- Vérifiez les erreurs : `❌ Error displaying local notification`

## 📋 Checklist Finale

- [ ] Firebase initialisé (logs : `✅ Firebase initialized`)
- [ ] Service de notifications initialisé (logs : `✅ Firebase Notification Service initialized`)
- [ ] Handlers configurés (logs : `✅ Message handlers configured`)
- [ ] Permission accordée (logs : `AuthorizationStatus.authorized`)
- [ ] Token APNS reçu (logs : `✅ APNS Token received`)
- [ ] Token FCM obtenu (logs : `✅ FCM TOKEN SUCCESSFULLY RETRIEVED`)
- [ ] Token enregistré (logs : `✅ FCM token auto-registered`)
- [ ] Test depuis Firebase Console fonctionne
- [ ] Logs montrent notification reçue quand envoyée

## 🔗 Commandes Utiles

### Voir tous les logs de notifications :
```bash
flutter run --release --device-id=<device-id> 2>&1 | grep -E "(🔔|📱|🔑|📨|notification|FCM|APNS)"
```

### Rebuild complet :
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter run --release --device-id=<device-id>
```

## 📝 Informations à Partager

Si le problème persiste, partagez :

1. **Tous les logs** au démarrage de l'app (de `✅ Firebase initialized` jusqu'à `✅ FCM token auto-registered`)
2. **Token FCM complet** (depuis les logs)
3. **Résultat du test** depuis Firebase Console (notification reçue ou non)
4. **Logs lors de l'envoi** d'une notification test (si l'app est ouverte)
5. **Screenshot** de Firebase Console → Cloud Messaging → Apple app configuration

