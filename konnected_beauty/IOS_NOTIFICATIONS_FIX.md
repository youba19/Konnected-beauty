# Fix pour les Notifications iOS

## ✅ Modifications Apportées

### 1. AppDelegate.swift
- ✅ Ajout de `userNotificationCenter(_:willPresent:withCompletionHandler:)` pour gérer les notifications en foreground
- ✅ Ajout de `userNotificationCenter(_:didReceive:withCompletionHandler:)` pour gérer les clics sur les notifications
- ✅ Configuration pour afficher les notifications même quand l'app est en foreground

### 2. firebase_notification_service.dart
- ✅ Amélioration des logs pour mieux diagnostiquer les notifications en background

## 🔍 Diagnostic

### Vérifiez les Logs

Quand vous recevez une notification, vous devriez voir :

#### En FOREGROUND (app ouverte) :
```
📨 === FOREGROUND MESSAGE RECEIVED ===
📨 === NOTIFICATION RECEIVED IN FOREGROUND (iOS) ===
```

#### En BACKGROUND (app minimisée) :
```
📨 BACKGROUND MESSAGE RECEIVED
📨 Notification payload present
📨 iOS: System will show notification automatically
```

#### Quand vous tapez sur la notification :
```
📨 === NOTIFICATION TAPPED (iOS) ===
📨 === BACKGROUND MESSAGE OPENED ===
```

## 🚨 Problèmes Potentiels

### 1. Format de la Notification depuis Firebase Console

Assurez-vous que la notification envoyée depuis Firebase Console contient :
- **Notification title** (pas seulement dans data)
- **Notification text** (pas seulement dans data)

**Format CORRECT :**
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

**Format INCORRECT (ne fonctionnera pas sur iOS en background) :**
```json
{
  "data": {
    "title": "Test Notification",
    "body": "This is a test message"
  }
}
```

### 2. Permissions iOS

Vérifiez dans **Réglages → Konected → Notifications** :
- ✅ Autoriser les notifications
- ✅ Alertes
- ✅ Sons
- ✅ Badges

### 3. Certificat APNS dans Firebase

1. Allez dans **Firebase Console → Project Settings → Cloud Messaging**
2. Vérifiez que le certificat APNS est **"Active"** (vert)
3. Si ce n'est pas le cas, téléchargez le certificat depuis Xcode et uploadez-le

### 4. Mode Release

Les notifications iOS fonctionnent mieux en mode **release** :
```bash
flutter run --release --device-id=<votre-device-id>
```

## 🧪 Test

1. **Envoyez une notification depuis Firebase Console** avec :
   - Notification title: `Test Notification`
   - Notification text: `This is a test message`
   - FCM registration token: (votre token)

2. **Testez dans 3 états** :
   - **Foreground** : App ouverte → Devrait afficher la notification
   - **Background** : App minimisée → Devrait afficher la notification
   - **Terminated** : App fermée → Devrait afficher la notification et ouvrir l'app quand tapée

3. **Vérifiez les logs** selon l'état de l'app

## 📝 Notes

- Sur iOS, les notifications avec `notification` payload sont affichées automatiquement par le système
- Les notifications avec seulement `data` payload nécessitent une notification locale
- Le delegate `UNUserNotificationCenter` doit être configuré (déjà fait dans AppDelegate)

