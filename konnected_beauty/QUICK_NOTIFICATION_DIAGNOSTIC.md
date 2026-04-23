# ⚡ Diagnostic Rapide - Notification Non Reçue

## 🔍 Questions Rapides

### 1. Voyez-vous des logs de notification reçue ?

**Cherchez dans les logs Flutter ou Xcode :**
- `📨 === FOREGROUND MESSAGE RECEIVED ===`
- `📨 === NOTIFICATION RECEIVED IN FOREGROUND (iOS) ===`
- `📨 === REMOTE NOTIFICATION RECEIVED (AppDelegate) ===`
- `📨 BACKGROUND MESSAGE RECEIVED`

#### ✅ Si OUI → La notification arrive
- **Problème** : Elle n'est pas affichée
- **Solution** : Vérifiez les permissions iOS (Réglages → Konected → Notifications)

#### ❌ Si NON → La notification n'arrive pas
- **Problème** : Firebase ne peut pas envoyer la notification
- **Cause probable** : Clé APNs non configurée ou inactive dans Firebase Console
- **Solution** : Voir ci-dessous

---

## 🚨 Solution Rapide (Si Aucun Log)

### Étape 1 : Vérifier la Clé APNs dans Firebase Console

1. **Firebase Console** : https://console.firebase.google.com
2. **Projet** : `konected-beauty`
3. **Project Settings** (⚙️) → **Cloud Messaging**
4. **Section "Apple app configuration"**
5. **Vérifiez le statut** :
   - ✅ **"Active"** (vert) = OK
   - ❌ **"Inactive"** ou **"Missing"** = PROBLÈME

### Étape 2 : Si la Clé n'est PAS Active

**Configurez une clé APNs :**

1. **Apple Developer** : https://developer.apple.com/account/resources/authkeys/list
2. **Créez une clé** :
   - Key Name : `Konnected Beauty Push Notifications`
   - ✅ Enable "Apple Push Notifications service (APNs)"
   - Continue → Register
3. **Téléchargez** le fichier `.p8` (UNE SEULE FOIS !)
4. **Notez** le Key ID et Team ID
5. **Firebase Console** → Cloud Messaging → Apple app configuration
6. **Upload** le fichier `.p8`
7. **Entrez** Key ID et Team ID
8. **Attendez 2-3 minutes**
9. **Testez à nouveau**

---

## 📋 Format de Notification Correct

Dans Firebase Console → Send test message :

```
✅ CORRECT:
Notification title: Test Notification
Notification text: This is a test message
FCM registration token: [votre token]

❌ INCORRECT:
(Ne mettez PAS seulement dans "Custom data")
```

---

## 🎯 Cause Probable (90% des cas)

**La clé APNs n'est pas configurée ou inactive dans Firebase Console.**

C'est la cause la plus fréquente quand les notifications n'arrivent pas du tout.

---

## 📞 Si le Problème Persiste

1. Vérifiez que le Bundle ID correspond entre Xcode et Firebase
2. Vérifiez que vous utilisez le bon FCM token (depuis les logs)
3. Testez sur un vrai iPhone (pas simulateur)
4. Vérifiez les permissions iOS (Réglages → Konected → Notifications)

