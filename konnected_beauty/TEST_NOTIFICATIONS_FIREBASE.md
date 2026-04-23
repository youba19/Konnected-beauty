# Guide de Test des Notifications iOS

## ✅ Configuration Vérifiée

D'après vos logs, tout est correctement configuré :
- ✅ Token APNS reçu dans AppDelegate
- ✅ Token APNS passé à Firebase Messaging
- ✅ Token FCM récupéré avec succès
- ✅ Permissions accordées
- ✅ Handlers de notifications configurés

## 🔑 Votre Token FCM

```
cdI14rzQWkWlquyMF303Lo:APA91bGayXkhCIhqLgQAXcNg-KVcu__lpMN33N8OtURDi8O_lhmByMoRl04dHnKw1HDiosmXzTFbaUJY6Qe7C2kkNHWUYV_MiIlOW0-8tGhWTLiFCZr8bNk
```

## 📱 Tester depuis Firebase Console

### Étape 1 : Ouvrir Firebase Console

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet : **konected-beauty**
3. Dans le menu de gauche, cliquez sur **Cloud Messaging**

### Étape 2 : Envoyer une Notification de Test

1. Cliquez sur **"Send test message"** ou **"Envoyer un message de test"**
2. Dans le champ **"FCM registration token"**, collez votre token FCM :
   ```
   cdI14rzQWkWlquyMF303Lo:APA91bGayXkhCIhqLgQAXcNg-KVcu__lpMN33N8OtURDi8O_lhmByMoRl04dHnKw1HDiosmXzTFbaUJY6Qe7C2kkNHWUYV_MiIlOW0-8tGhWTLiFCZr8bNk
   ```
3. Remplissez les champs :
   - **Notification title** : `Test Notification`
   - **Notification text** : `This is a test message`
4. Cliquez sur **"Test"** ou **"Tester"**

### Étape 3 : Vérifier les Logs

#### Si l'app est en FOREGROUND (ouverte) :
Vous devriez voir dans les logs Flutter :
```
═══════════════════════════════════════════════════════
📨 === FOREGROUND MESSAGE RECEIVED ===
📨 Message ID: ...
📨 Title: Test Notification
📨 Body: This is a test message
═══════════════════════════════════════════════════════
```

#### Si l'app est en BACKGROUND (minimisée) :
Vous devriez voir dans les logs Xcode :
```
═══════════════════════════════════════════════════════
📨 BACKGROUND MESSAGE RECEIVED
═══════════════════════════════════════════════════════
📨 Title: Test Notification
📨 Body: This is a test message
═══════════════════════════════════════════════════════
```

#### Si l'app est TERMINATED (fermée) :
L'app s'ouvrira et vous verrez dans les logs :
```
📨 === APP OPENED FROM TERMINATED STATE ===
```

## 🔍 Diagnostic

### Si vous ne recevez PAS la notification :

1. **Vérifiez le token FCM** :
   - Le token peut changer si vous réinstallez l'app
   - Vérifiez les logs pour obtenir le nouveau token

2. **Vérifiez les permissions iOS** :
   - Allez dans **Réglages → Konected → Notifications**
   - Assurez-vous que les notifications sont activées

3. **Vérifiez le certificat APNS dans Firebase** :
   - Firebase Console → Project Settings → Cloud Messaging
   - Vérifiez que le certificat APNS est **"Active"** (vert)
   - Si ce n'est pas le cas, téléchargez-le depuis Xcode et uploadez-le

4. **Vérifiez les logs** :
   - Si vous voyez `📨 === FOREGROUND MESSAGE RECEIVED ===`, la notification est reçue mais peut-être pas affichée
   - Si vous ne voyez aucun log, la notification n'arrive pas à l'appareil

## 📝 Notes Importantes

1. **Mode Release** : Vous êtes en mode release, ce qui est correct pour tester les notifications
2. **Appareil Physique** : Vous utilisez un appareil physique, ce qui est nécessaire
3. **Token FCM** : Le token sera automatiquement enregistré dans le backend après la connexion

## 🚀 Prochaines Étapes

1. Testez avec une notification depuis Firebase Console
2. Vérifiez les logs selon l'état de l'app (foreground/background/terminated)
3. Si ça ne fonctionne pas, partagez les logs complets

