# 🔴 Notification iOS Non Reçue - Guide de Diagnostic

## 📋 Checklist de Diagnostic

### ✅ Étape 1 : Vérifier les Logs

**Quand vous envoyez une notification depuis Firebase Console, regardez les logs :**

#### A. Si vous voyez ces logs = La notification arrive à l'appareil
```
📨 === FOREGROUND MESSAGE RECEIVED ===
📨 === NOTIFICATION RECEIVED IN FOREGROUND (iOS) ===
📨 === REMOTE NOTIFICATION RECEIVED (AppDelegate) ===
📨 BACKGROUND MESSAGE RECEIVED
```

**→ Si vous voyez ces logs :** La notification arrive, mais peut-être qu'elle n'est pas affichée. Passez à l'Étape 2.

#### B. Si vous NE voyez AUCUN de ces logs = La notification n'arrive PAS à l'appareil

**→ Si vous ne voyez pas ces logs :** Le problème est que Firebase ne peut pas envoyer la notification à votre appareil. Passez à l'Étape 3.

---

### ✅ Étape 2 : Notification Arrive Mais Pas Affichée

Si vous voyez les logs mais pas la notification visuelle :

#### 2.1 Vérifier les Permissions iOS
1. **Réglages** → **Konected** → **Notifications**
2. Vérifiez que :
   - ✅ **Autoriser les notifications** est activé
   - ✅ **Alerte** est activé
   - ✅ **Bannière** est activé
   - ✅ **Son** est activé

#### 2.2 Vérifier l'État de l'App
- **Foreground (app ouverte)** : La notification devrait apparaître en haut de l'écran
- **Background (app minimisée)** : La notification devrait apparaître dans le centre de notifications
- **Terminated (app fermée)** : La notification devrait apparaître dans le centre de notifications

#### 2.3 Vérifier le Format de la Notification

Dans Firebase Console → Send test message, utilisez ce format :

```
Notification title: Test Notification
Notification text: This is a test message
FCM registration token: [votre token FCM]
```

⚠️ **NE PAS** mettre seulement dans "Additional options → Custom data"

---

### ✅ Étape 3 : Notification N'Arrive Pas (Aucun Log)

Si vous ne voyez AUCUN log de notification reçue, le problème est que Firebase ne peut pas envoyer la notification.

#### 3.1 Vérifier la Clé APNs dans Firebase Console (CRITIQUE)

1. **Firebase Console** : https://console.firebase.google.com
2. **Sélectionnez votre projet** : `konected-beauty`
3. **Project Settings** (⚙️) → **Cloud Messaging**
4. **Section "Apple app configuration"** ou **"iOS app configuration"**
5. **Vérifiez le statut de la clé APNs** :
   - ✅ **"Active"** (vert) = Correct
   - ❌ **"Inactive"** = PROBLÈME
   - ❌ **"Missing"** ou rien = PROBLÈME

#### 3.2 Si la Clé APNs n'est PAS Active

##### Option A : Configurer une Clé APNs (.p8) - RECOMMANDÉ

1. **Apple Developer** : https://developer.apple.com/account/resources/authkeys/list
2. **Créez une nouvelle clé** :
   - Cliquez sur **+** pour créer une nouvelle clé
   - **Key Name** : `Konnected Beauty Push Notifications`
   - ✅ Cochez **"Apple Push Notifications service (APNs)"**
   - Cliquez sur **Continue** puis **Register**
3. **Téléchargez la clé** (.p8) - **IMPORTANT : Une seule fois !**
4. **Notez le Key ID** (affiché après création)
5. **Notez votre Team ID** (en haut à droite de la page Apple Developer)
6. **Dans Firebase Console** :
   - Project Settings → Cloud Messaging
   - Section "Apple app configuration"
   - Choisissez **"APNs Authentication Key"**
   - Upload le fichier `.p8`
   - Entrez le **Key ID**
   - Entrez le **Team ID**
   - Cliquez sur **"Upload"**

##### Option B : Vérifier une Clé Existante

1. **Firebase Console** → Cloud Messaging
2. Si une clé existe, vérifiez :
   - ✅ Statut = "Active"
   - ✅ Key ID est correct
   - ✅ Team ID est correct
   - ✅ Bundle ID correspond

#### 3.3 Vérifier le Bundle ID

**IMPORTANT** : Le Bundle ID dans Firebase doit correspondre EXACTEMENT à celui de votre app.

1. **Dans Xcode** :
   - Ouvrez `ios/Runner.xcworkspace`
   - Sélectionnez le projet **Runner**
   - Onglet **General**
   - Vérifiez **Bundle Identifier** (ex: `com.example.konected`)

2. **Dans Firebase Console** :
   - Project Settings → Your apps → iOS app
   - Vérifiez que le **Bundle ID** correspond exactement

#### 3.4 Vérifier le FCM Token

1. **Copiez le FCM token depuis les logs** :
   ```
   fBsWeD_D6kI4n5rskkXJbU:APA91bEmyQlc4OXg2VNNygEZyvixevS9C5tdBYO-Ws9j66c06wjF1D3o4j7-GjM7JxTWxGRNIZwpGHECecU4fTHIK6eURTOJkxSd5j6Gr5vGvxLmQRqh9ps
   ```

2. **Dans Firebase Console** → Send test message :
   - Utilisez EXACTEMENT ce token
   - Vérifiez qu'il n'y a pas d'espaces avant/après

---

## 🔍 Diagnostic Détaillé

### Vérifier les Logs AppDelegate

**Dans Xcode Console**, cherchez ces logs au démarrage de l'app :

```
🚀 === APPDELEGATE DID FINISH LAUNCHING ===
✅ Firebase configured in AppDelegate
✅ UNUserNotificationCenter delegate set
📱 Registering for remote notifications...
✅ registerForRemoteNotifications() called
📱 === APNS TOKEN RECEIVED IN APPDELEGATE ===
```

**Si vous ne voyez pas "APNS TOKEN RECEIVED" :**
- ❌ Push Notifications capability n'est pas activée dans Xcode
- ❌ L'appareil n'est pas un vrai iPhone (simulateur)
- ❌ Les entitlements sont incorrects

### Vérifier les Logs Flutter

**Dans Flutter Console**, cherchez ces logs :

```
✅ APNS Token received in Dart: 8047879E32777E764D20...
✅ FCM TOKEN SUCCESSFULLY RETRIEVED (iOS)!
🔑 Token: fBsWeD_D6kI4n5rskkXJbU:APA91bE...
```

**Si vous voyez ces logs :** Les tokens sont corrects, le problème est probablement la clé APNs dans Firebase Console.

---

## 🧪 Test Complet

### Test 1 : Vérifier la Configuration

1. ✅ Firebase initialisé dans l'app (logs montrent "Firebase initialized")
2. ✅ APNS token reçu (logs montrent "APNS Token received")
3. ✅ FCM token obtenu (logs montrent "FCM TOKEN SUCCESSFULLY RETRIEVED")
4. ❓ Clé APNs active dans Firebase Console (vérification manuelle requise)

### Test 2 : Envoyer une Notification de Test

1. **Firebase Console** → **Cloud Messaging** → **"Send test message"**
2. **FCM registration token** : Utilisez le token depuis les logs
3. **Notification title** : `Test Notification`
4. **Notification text** : `This is a test message`
5. **Cliquez sur "Test"**

### Test 3 : Vérifier les Logs Après Envoi

**Immédiatement après avoir cliqué sur "Test" :**

#### Si la notification arrive :
```
📨 === FOREGROUND MESSAGE RECEIVED ===
📨 Title: Test Notification
📨 Body: This is a test message
```

#### Si la notification n'arrive PAS :
- Aucun log de notification reçue
- Probable cause : Clé APNs inactive ou manquante dans Firebase Console

---

## 🚨 Causes Probables (Par Ordre de Fréquence)

### 1. **Clé APNs Non Configurée ou Inactive** (90% des cas)
- **Symptôme** : Aucun log de notification reçue
- **Solution** : Configurer la clé APNs dans Firebase Console (voir Étape 3.2)

### 2. **Bundle ID Ne Correspond Pas** (5% des cas)
- **Symptôme** : Clé APNs active mais notifications n'arrivent pas
- **Solution** : Vérifier que Bundle ID correspond entre Xcode et Firebase

### 3. **Format de Notification Incorrect** (3% des cas)
- **Symptôme** : Notification envoyée mais pas affichée
- **Solution** : Utiliser "Notification title" et "Notification text" (pas seulement Custom data)

### 4. **Permissions iOS Désactivées** (2% des cas)
- **Symptôme** : Logs montrent notification reçue mais pas affichée
- **Solution** : Vérifier Réglages → Konected → Notifications

---

## 📝 Checklist Finale

Avant de tester à nouveau, vérifiez :

- [ ] Clé APNs configurée dans Firebase Console
- [ ] Statut de la clé APNs = "Active" (vert)
- [ ] Bundle ID correspond entre Xcode et Firebase
- [ ] FCM token utilisé est le bon (depuis les logs)
- [ ] Format de notification correct (title + text)
- [ ] Permissions iOS activées (Réglages → Konected → Notifications)
- [ ] Test sur un vrai iPhone (pas simulateur)
- [ ] App en foreground, background, et terminated (tester les 3 états)

---

## 💡 Prochaines Étapes

1. **Vérifiez d'abord la clé APNs dans Firebase Console** (Étape 3.1)
2. **Si elle n'est pas active, configurez-la** (Étape 3.2)
3. **Attendez 2-3 minutes** après configuration
4. **Testez à nouveau** avec le même FCM token
5. **Vérifiez les logs** pour voir si la notification arrive

---

## 🔗 Liens Utiles

- **Firebase Console** : https://console.firebase.google.com
- **Apple Developer Keys** : https://developer.apple.com/account/resources/authkeys/list
- **Firebase Cloud Messaging Docs** : https://firebase.google.com/docs/cloud-messaging

