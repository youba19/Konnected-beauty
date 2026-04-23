# Fix : Certificat APNs Non Approuvé

## 🔴 Problème Identifié

Le certificat **"Apple Push Services: com.konectedbeauty.konectedbeauty"** n'est **pas approuvé** dans le Keychain.

Message d'erreur : **"certificate is not trusted"**

C'est probablement la cause principale du problème !

## ✅ Solution : Approuver le Certificat

### Étape 1 : Ouvrir Keychain Access

1. **Ouvrez Keychain Access** (Applications → Utilitaires → Keychain Access)
2. **Sélectionnez "Certificates"** dans la barre latérale gauche
3. **Cherchez** : `Apple Push Services: com.konectedbeauty.konectedbeauty`

### Étape 2 : Approuver le Certificat

1. **Double-cliquez** sur le certificat `Apple Push Services: com.konectedbeauty.konectedbeauty`
2. **Développez** la section "Trust"
3. **Changez** "When using this certificate" de "Use System Defaults" à **"Always Trust"**
4. **Fermez** la fenêtre
5. **Entrez votre mot de passe** Mac si demandé

### Étape 3 : Vérifier le Certificat Intermédiaire

1. **Cherchez aussi** : `Apple Worldwide Developer Relations Certification Authority`
2. **Vérifiez** qu'il est approuvé
3. Si ce n'est pas le cas, **approuvez-le aussi** (Always Trust)

### Étape 4 : Vérifier le Certificat Racine

1. **Cherchez** : `Apple Root CA`
2. **Vérifiez** qu'il est approuvé
3. Si ce n'est pas le cas, **approuvez-le aussi** (Always Trust)

## 🔍 Vérification

Après avoir approuvé les certificats :

1. **Fermez Keychain Access**
2. **Relancez l'app** :
   ```bash
   flutter run --release --device-id=00008110-000465680A89A01E
   ```
3. **Testez une notification** depuis Firebase Console
4. **Vérifiez les logs** pour voir si les notifications arrivent maintenant

## 📝 Note Importante

Le certificat APNs doit être :
- ✅ **Approuvé** dans le Keychain (Always Trust)
- ✅ **Valide** (non expiré - votre certificat expire le 7 janvier 2027, donc c'est bon)
- ✅ **Correspond au Bundle ID** (com.konectedbeauty.konectedbeauty)

## 🚨 Si le Problème Persiste

Si après avoir approuvé le certificat, les notifications ne fonctionnent toujours pas :

1. **Vérifiez dans Firebase Console** :
   - La clé APNs est "Active"
   - Le Bundle ID correspond

2. **Vérifiez le format de notification** :
   - Notification title et text (pas seulement dans data)

3. **Vérifiez les logs** :
   - Cherchez `📨 === REMOTE NOTIFICATION RECEIVED (AppDelegate) ===`
   - Cherchez `📨 === FOREGROUND MESSAGE RECEIVED ===`

## 💡 Pourquoi C'est Important

Sur iOS, les certificats APNs doivent être approuvés dans le Keychain pour que le système puisse les utiliser. Si le certificat n'est pas approuvé, iOS peut refuser d'envoyer les notifications, même si tout le reste est correctement configuré.

