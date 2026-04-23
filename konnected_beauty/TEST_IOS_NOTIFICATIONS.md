# Test des Notifications iOS - Guide Étape par Étape

## 🔍 Diagnostic Complet

### Étape 1 : Vérifier les Logs au Démarrage

Lancez l'app et **copiez TOUS les logs** qui contiennent :
- `🔔` (notifications)
- `📱` (iOS/APNS)
- `🔑` (token FCM)
- `✅` ou `❌` (succès/erreur)

**Cherchez spécifiquement :**

1. **Permission :**
   ```
   🔔 Notification permission status: AuthorizationStatus.authorized
   ✅ User granted notification permission
   ```

2. **Token APNS :**
   ```
   📱 Checking for APNS token (attempt 1/10)...
   ✅ APNS Token received: ...
   ```

3. **Token FCM :**
   ```
   ✅ FCM TOKEN SUCCESSFULLY RETRIEVED (iOS)!
   🔑 Token: <votre-token-complet>
   ```

4. **Enregistrement du token :**
   ```
   📱 === AUTO-REGISTERING FCM TOKEN ===
   ✅ FCM token auto-registered successfully
   ```

### Étape 2 : Tester depuis Firebase Console

1. **Copiez le token FCM** depuis les logs (le token complet après `🔑 Token:`)

2. Allez sur [Firebase Console](https://console.firebase.google.com)
   - Sélectionnez votre projet
   - **Cloud Messaging** → **Send your first message**

3. **Créez une notification test :**
   - Titre : "Test Notification"
   - Texte : "This is a test message"
   - Cliquez sur **Send test message**
   - Collez votre **token FCM** (copié depuis les logs)
   - Cliquez sur **Test**

4. **Vérifiez les logs de l'app :**
   - Si l'app est **en foreground**, cherchez : `📨 Foreground message received`
   - Si l'app est **en background**, la notification devrait apparaître automatiquement
   - Si l'app est **fermée**, ouvrez-la et cherchez : `📨 App opened from terminated state`

### Étape 3 : Vérifier la Configuration Firebase

1. **Firebase Console** → **Project Settings** → **Cloud Messaging**
2. Section **Apple app configuration**
3. Vérifiez :
   - ✅ Certificat/clé APNS est uploadé
   - ✅ Statut : "Active" ou "Valid"
   - ✅ Pas d'erreur rouge
   - ✅ Bundle ID correspond à votre app

### Étape 4 : Vérifier Xcode

1. Ouvrez `ios/Runner.xcworkspace` dans Xcode
2. Sélectionnez target **Runner**
3. Onglet **Signing & Capabilities**
4. Vérifiez que **Push Notifications** apparaît dans la liste
5. Si absent :
   - Cliquez sur **+ Capability**
   - Ajoutez **Push Notifications**

### Étape 5 : Vérifier les Permissions sur l'Appareil

Sur votre iPhone/iPad :
1. **Settings** → **[Votre App]**
2. **Notifications**
3. Vérifiez :
   - ✅ **Allow Notifications** = ON
   - ✅ **Alert Style** = Banners ou Alerts (pas "None")
   - ✅ **Sounds** = ON
   - ✅ **Badges** = ON

### Étape 6 : Vérifier le Bundle ID

1. Dans Xcode : **Target Runner** → **General** → **Bundle Identifier**
2. Notez le Bundle ID (ex: `com.example.konnectedbeauty`)
3. Dans Firebase Console : **Project Settings** → **Your apps** → iOS app
4. Vérifiez que le Bundle ID correspond exactement

### Étape 7 : Test Complet

1. **Fermez complètement l'app** (swipe up depuis le multitasking)
2. **Envoyez une notification test** depuis Firebase Console
3. **Vérifiez** :
   - La notification apparaît-elle sur l'écran de verrouillage ?
   - La notification apparaît-elle dans le centre de notifications ?
   - En cliquant sur la notification, l'app s'ouvre-t-elle ?

## 🐛 Problèmes Courants

### Problème : Token FCM obtenu mais pas de notifications

**Vérifications :**
1. Le token est-il bien enregistré dans votre backend ?
   - Cherchez dans les logs : `✅ FCM token registered successfully`
   - Vérifiez la réponse de l'API (status 200)

2. Le certificat APNS est-il bien configuré dans Firebase ?
   - Firebase Console → Cloud Messaging → Apple app configuration
   - Vérifiez qu'il n'y a pas d'erreur

3. Testez depuis Firebase Console directement
   - Si ça fonctionne depuis Firebase → problème backend
   - Si ça ne fonctionne pas → problème configuration Firebase/iOS

### Problème : Notifications reçues mais pas affichées

**Causes :**
1. Permissions non accordées → Vérifiez Settings
2. App en foreground sans gestion → Vérifiez les logs `📨 Foreground message received`
3. Mode Do Not Disturb activé → Désactivez-le temporairement

### Problème : "APNS Token not available"

**Solutions :**
1. Utiliser un **vrai appareil** (pas simulateur)
2. Activer **Push Notifications** dans Xcode
3. Configurer le **certificat APNS** dans Firebase
4. Rebuild l'app complètement

## 📋 Checklist Finale

- [ ] App testée sur **vrai appareil iOS** (pas simulateur)
- [ ] **Push Notifications** activé dans Xcode
- [ ] **Permissions** accordées dans Settings
- [ ] **Certificat APNS** configuré dans Firebase Console
- [ ] **Token FCM** reçu (voir logs)
- [ ] **Token FCM** enregistré dans backend (voir logs)
- [ ] **Test depuis Firebase Console** fonctionne
- [ ] **Bundle ID** correspond entre Xcode et Firebase

## 🔗 Commandes Utiles

### Voir les logs en temps réel :
```bash
flutter run --release --device-id=<votre-device-id> 2>&1 | grep -E "(FCM|APNS|notification|token|🔔|📱|🔑)"
```

### Rebuild complet :
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter run --release --device-id=<votre-device-id>
```

## 📝 Informations à Partager pour le Support

Si le problème persiste, partagez :

1. **Logs complets** au démarrage de l'app
2. **Logs lors du login** (enregistrement du token)
3. **Token FCM complet** (depuis les logs)
4. **Résultat du test** depuis Firebase Console
5. **Screenshot** de Firebase Console → Cloud Messaging → Apple app configuration
6. **Screenshot** de Xcode → Signing & Capabilities (montrant Push Notifications)

