# Vérification de la Clé APNs dans Firebase

## ✅ Message Firebase : Normal

Le message que vous voyez :
> "Votre certificat APNs de développement n'est pas utilisé pour l'authentification lorsque la clé d'authentification APNs et le certificat APNs sont configurés"

**C'est NORMAL et CORRECT.** Firebase utilise la clé d'authentification APNs (.p8) qui est **préférée** au certificat.

## 🔍 Vérifications à Faire

### 1. Statut de la Clé APNs dans Firebase

1. **Firebase Console** → **Project Settings** → **Cloud Messaging**
2. **Section "iOS app configuration"**
3. **Vérifiez le statut de la clé APNs** :
   - ✅ **"Active"** (vert) = Correct
   - ❌ **"Inactive"** ou erreur = Problème

### 2. Vérifiez les Détails de la Clé

Dans Firebase Console, vérifiez que :
- ✅ La clé APNs est **"Active"**
- ✅ Le **Key ID** est correct
- ✅ Le **Team ID** est correct
- ✅ Le **Bundle ID** correspond à votre app

### 3. Vérifiez le Bundle ID

**IMPORTANT** : Le Bundle ID dans Firebase doit correspondre exactement à celui de votre app.

1. **Dans Xcode** :
   - Ouvrez `Runner.xcworkspace`
   - Sélectionnez le projet **Runner**
   - Onglet **General**
   - Vérifiez **Bundle Identifier**

2. **Dans Firebase Console** :
   - Project Settings → Your apps → iOS app
   - Vérifiez que le **Bundle ID** correspond exactement

### 4. Vérifiez que la Clé APNs est Valide

1. **Allez dans Apple Developer** : https://developer.apple.com/account/resources/authkeys/list
2. **Vérifiez que la clé** :
   - ✅ Existe toujours
   - ✅ A "Apple Push Notifications service (APNs)" activé
   - ✅ N'est pas révoquée

### 5. Test de la Notification

**Format CORRECT** dans Firebase Console → Send test message :

```
Notification title: Test Notification
Notification text: This is a test message
FCM registration token: [votre token FCM]
```

⚠️ **NE PAS** mettre seulement dans "Additional options → Custom data"

## 🚨 Si la Clé APNs n'est PAS Active

### Option 1 : Réuploader la Clé APNs

1. **Téléchargez la clé depuis Apple Developer** (si vous l'avez sauvegardée)
2. **Dans Firebase Console** :
   - Supprimez l'ancienne clé
   - Uploadez la nouvelle clé (.p8)
   - Entrez le Key ID
   - Entrez le Team ID

### Option 2 : Créer une Nouvelle Clé APNs

1. **Apple Developer** → https://developer.apple.com/account/resources/authkeys/list
2. **Créez une nouvelle clé** :
   - Key Name : `Konnected Beauty Push Notifications v2`
   - ✅ Enable "Apple Push Notifications service (APNs)"
   - Continue → Register
3. **Téléchargez la clé** (.p8) - **UNE SEULE FOIS**
4. **Notez le Key ID**
5. **Dans Firebase Console** :
   - Supprimez l'ancienne clé
   - Uploadez la nouvelle clé
   - Entrez le Key ID et Team ID

## 📝 Checklist Complète

- [ ] Clé APNs est "Active" dans Firebase Console
- [ ] Key ID est correct
- [ ] Team ID est correct
- [ ] Bundle ID correspond entre Xcode et Firebase
- [ ] La clé existe toujours dans Apple Developer
- [ ] La clé a "Apple Push Notifications service (APNs)" activé
- [ ] Format de notification correct (notification.title et notification.body)
- [ ] Token FCM utilisé est le bon (depuis les logs)
- [ ] Permissions iOS activées (Réglages → Konected → Notifications)

## 🧪 Test Final

1. **Vérifiez que la clé APNs est "Active"** dans Firebase Console
2. **Attendez 2-3 minutes** après toute modification
3. **Envoyez une notification de test** depuis Firebase Console
4. **Testez dans 3 états** :
   - Foreground (app ouverte)
   - Background (app minimisée)
   - Terminated (app fermée)

## 💡 Note Importante

Le message que vous voyez est **normal**. Firebase préfère utiliser la clé d'authentification APNs (.p8) plutôt que le certificat. C'est la méthode recommandée par Apple.

Le problème vient probablement d'autre chose :
- Clé APNs inactive ou mal configurée
- Bundle ID ne correspond pas
- Format de notification incorrect
- Token FCM incorrect

