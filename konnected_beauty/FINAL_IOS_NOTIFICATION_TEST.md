# Test Final : Notifications iOS

## ✅ Ce qui est Configuré

- ✅ API Firebase Cloud Messaging (V1) activée
- ✅ Clé APNs configurée dans Firebase
- ✅ APNS token reçu dans l'app
- ✅ FCM token récupéré
- ✅ Permissions accordées
- ✅ Handlers configurés

## 🔍 Test Étape par Étape

### Étape 1 : Vérifier le Token FCM

Votre token FCM actuel (depuis les logs) :
```
et0ssskhlEYlssguy6H6PA:APA91bFr6PEZpz31g-mCrI9OOsRvAbWshJM1DeFDPel39P1DgC5ShdGrXFxtpTw861qcGexBE4rx_eRxUK3L8S-l4Fd_CksPN5PeWVUvB0858stmwEFjsgY
```

⚠️ **IMPORTANT** : Le token peut changer si vous réinstallez l'app. Vérifiez toujours les logs pour le token le plus récent.

### Étape 2 : Envoyer une Notification depuis Firebase Console

1. **Allez dans Firebase Console** : https://console.firebase.google.com/
2. **Sélectionnez votre projet** : `konected-beauty`
3. **Allez dans** : Cloud Messaging → Send test message
4. **Collez le token FCM** ci-dessus
5. **Remplissez** :
   - **Notification title** : `Test Notification`
   - **Notification text** : `This is a test message`
   - ⚠️ **NE PAS** mettre seulement dans "Additional options → Custom data"
6. **Cliquez sur "Test"**

### Étape 3 : Tester dans 3 États Différents

#### A. App en FOREGROUND (ouverte)

1. **Gardez l'app ouverte** sur votre appareil
2. **Envoyez la notification** depuis Firebase Console
3. **Cherchez dans les logs Flutter** :
   ```
   📨 === FOREGROUND MESSAGE RECEIVED ===
   📨 === NOTIFICATION RECEIVED IN FOREGROUND (iOS) ===
   ```
4. **La notification devrait apparaître** en haut de l'écran

#### B. App en BACKGROUND (minimisée)

1. **Minimisez l'app** (appuyez sur le bouton home)
2. **Envoyez la notification** depuis Firebase Console
3. **Cherchez dans les logs Xcode** (pas Flutter) :
   - Ouvrez Xcode
   - Window → Devices and Simulators
   - Sélectionnez votre appareil
   - Cliquez sur "Open Console"
   - Cherchez : `📨 BACKGROUND MESSAGE RECEIVED`
4. **La notification devrait apparaître** dans le centre de notifications iOS

#### C. App TERMINATED (fermée)

1. **Fermez complètement l'app** (swipe up depuis le multitâche)
2. **Envoyez la notification** depuis Firebase Console
3. **La notification devrait apparaître** dans le centre de notifications iOS
4. **Quand vous tapez dessus**, l'app s'ouvre
5. **Cherchez dans les logs** :
   ```
   📨 === APP OPENED FROM TERMINATED STATE ===
   ```

### Étape 4 : Vérifier les Logs

#### Si la notification ARRIVE :

**Foreground** :
```
📨 === FOREGROUND MESSAGE RECEIVED ===
📨 === NOTIFICATION RECEIVED IN FOREGROUND (iOS) ===
```

**Background** (dans Xcode Console) :
```
📨 BACKGROUND MESSAGE RECEIVED
```

**Terminated** :
```
📨 === APP OPENED FROM TERMINATED STATE ===
```

#### Si la notification N'ARRIVE PAS :

- **Aucun log** = Problème de configuration Firebase ou format de notification
- **Logs mais pas d'affichage** = Problème de permissions iOS ou configuration AppDelegate

## 🚨 Problèmes Courants

### 1. Aucun Log de Notification Reçue

**Causes possibles** :
- ❌ Clé APNs inactive dans Firebase Console
- ❌ Bundle ID ne correspond pas entre Xcode et Firebase
- ❌ Format de notification incorrect (seulement dans "data" au lieu de "notification")
- ❌ Token FCM incorrect ou expiré

**Solutions** :
1. Vérifiez que la clé APNs est "Active" dans Firebase Console
2. Vérifiez que le Bundle ID correspond exactement
3. Utilisez le format correct : `notification.title` et `notification.body`
4. Vérifiez le token FCM dans les logs (il peut changer)

### 2. Logs Présents mais Notification Non Affichée

**Causes possibles** :
- ❌ Permissions iOS désactivées
- ❌ AppDelegate ne gère pas correctement les notifications

**Solutions** :
1. Vérifiez dans Réglages → Konected → Notifications
2. Activez toutes les options (Alertes, Sons, Badges)
3. Vérifiez que `AppDelegate.swift` a les méthodes `userNotificationCenter`

### 3. Notification Affichée mais App Ne S'Ouvre Pas

**Causes possibles** :
- ❌ Handler `onMessageOpenedApp` ne fonctionne pas
- ❌ Handler `getInitialMessage` ne fonctionne pas

**Solutions** :
- Vérifiez les logs pour voir si les handlers sont appelés
- Vérifiez que `AppDelegate.swift` appelle `super.userNotificationCenter`

## 📝 Checklist Finale

Avant de tester, vérifiez :

- [ ] Clé APNs est "Active" dans Firebase Console
- [ ] Bundle ID correspond entre Xcode et Firebase
- [ ] API Firebase Cloud Messaging (V1) activée ✅
- [ ] Token FCM utilisé est le bon (depuis les logs)
- [ ] Format de notification correct (notification.title et notification.body)
- [ ] Permissions iOS activées (Réglages → Konected → Notifications)
- [ ] App en mode release (pour tester les notifications en conditions réelles)
- [ ] Appareil physique (pas simulateur)

## 🎯 Test Final

1. **Vérifiez tous les points de la checklist**
2. **Envoyez une notification de test** depuis Firebase Console
3. **Testez dans les 3 états** (foreground, background, terminated)
4. **Vérifiez les logs** selon l'état de l'app
5. **Partagez les résultats** :
   - Avez-vous vu des logs de notification reçue ?
   - La notification est-elle affichée ?
   - Dans quel(s) état(s) ça fonctionne/ne fonctionne pas ?

## 💡 Note Importante

Si vous voyez des **logs de notification reçue** mais que la notification n'est **pas affichée**, le problème vient des permissions iOS ou de la configuration AppDelegate.

Si vous **ne voyez aucun log**, le problème vient de la configuration Firebase (clé APNs, Bundle ID, format de notification).

