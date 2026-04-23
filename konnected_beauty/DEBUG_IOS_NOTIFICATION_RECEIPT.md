# Debug : Notification iOS Non Reçue

## ✅ Ce qui fonctionne (d'après les logs)

- ✅ APNS token reçu : `7666c70d7e79fcda16c3f6bd9c67f7ef0a48639d29368640eff33ac1d31396c8`
- ✅ FCM token récupéré : `cxGgBvR5_U4gudNkBdGQO4:APA91bENYh98l4gj61DywvGHtqm4ATMluHhWPUOJRKtuunUrTIXZHtxnAgu-xqkgqa7qFhpmRrzzNsL-9mHzrjcdUCXfGEX0K02_inAeIyDSs5fhe0to5jY`
- ✅ Permissions accordées
- ✅ Handlers configurés

## 🔍 Points à Vérifier

### 1. Format de la Notification depuis Firebase Console

**IMPORTANT :** Sur iOS, la notification DOIT avoir un payload `notification`, pas seulement `data`.

#### ✅ Format CORRECT (doit fonctionner) :
```json
{
  "notification": {
    "title": "Test Notification",
    "body": "This is a test message"
  }
}
```

#### ❌ Format INCORRECT (ne fonctionnera PAS sur iOS en background) :
```json
{
  "data": {
    "title": "Test Notification",
    "body": "This is a test message"
  }
}
```

### 2. Token FCM Utilisé

Votre token FCM actuel :
```
cxGgBvR5_U4gudNkBdGQO4:APA91bENYh98l4gj61DywvGHtqm4ATMluHhWPUOJRKtuunUrTIXZHtxnAgu-xqkgqa7qFhpmRrzzNsL-9mHzrjcdUCXfGEX0K02_inAeIyDSs5fhe0to5jY
```

**Vérifiez que vous utilisez EXACTEMENT ce token dans Firebase Console.**

### 3. Certificat APNS dans Firebase Console

1. Allez dans **Firebase Console → Project Settings → Cloud Messaging**
2. Vérifiez la section **iOS app configuration**
3. Le certificat APNS doit être **"Active"** (vert)
4. Si ce n'est pas le cas :
   - Téléchargez le certificat depuis Xcode
   - Uploadez-le dans Firebase Console

### 4. Test dans Différents États

Testez la notification dans 3 états différents :

#### A. App en FOREGROUND (ouverte)
- Vous devriez voir dans les logs :
  ```
  📨 === FOREGROUND MESSAGE RECEIVED ===
  📨 === NOTIFICATION RECEIVED IN FOREGROUND (iOS) ===
  ```

#### B. App en BACKGROUND (minimisée)
- Vous devriez voir dans les logs Xcode :
  ```
  📨 BACKGROUND MESSAGE RECEIVED
  ```
- La notification devrait apparaître dans le centre de notifications iOS

#### C. App TERMINATED (fermée)
- La notification devrait apparaître
- Quand vous tapez dessus, l'app s'ouvre
- Vous devriez voir dans les logs :
  ```
  📨 === APP OPENED FROM TERMINATED STATE ===
  ```

### 5. Vérifier les Logs Xcode

**IMPORTANT :** Les logs de notifications en background apparaissent dans **Xcode Console**, pas dans Flutter logs.

1. Ouvrez Xcode
2. Connectez votre appareil
3. Allez dans **Window → Devices and Simulators**
4. Sélectionnez votre appareil
5. Cliquez sur **"Open Console"**
6. Envoyez une notification depuis Firebase Console
7. Cherchez les logs avec `📨`

### 6. Permissions iOS

Vérifiez dans **Réglages → Konected → Notifications** :
- ✅ Autoriser les notifications
- ✅ Alertes
- ✅ Sons
- ✅ Badges

## 🧪 Test Étape par Étape

1. **Copiez le token FCM** depuis les logs
2. **Ouvrez Firebase Console → Cloud Messaging → Send test message**
3. **Collez le token FCM**
4. **Remplissez** :
   - Notification title: `Test Notification`
   - Notification text: `This is a test message`
   - ⚠️ **NE PAS** mettre seulement dans "Additional options → Custom data"
5. **Cliquez sur "Test"**
6. **Vérifiez les logs** selon l'état de l'app

## 🚨 Si ça ne fonctionne toujours pas

1. **Vérifiez le certificat APNS** dans Firebase Console (doit être "Active")
2. **Vérifiez le format** de la notification (doit avoir `notification.title` et `notification.body`)
3. **Vérifiez les logs Xcode** (pas seulement Flutter)
4. **Testez avec l'app en background** (minimisée)
5. **Vérifiez les permissions iOS** dans Réglages

## 📝 Note Importante

Sur iOS, les notifications avec payload `notification` sont affichées automatiquement par le système en background/terminated. En foreground, elles nécessitent le delegate `UNUserNotificationCenter` qui est déjà configuré dans `AppDelegate.swift`.

