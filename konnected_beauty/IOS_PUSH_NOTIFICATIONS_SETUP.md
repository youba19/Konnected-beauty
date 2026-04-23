# Configuration des Notifications Push iOS

## Problème : "APNS Token not available yet"

Si vous voyez ce message et que les notifications ne fonctionnent pas sur iOS, suivez ces étapes :

## ✅ Checklist de Configuration

### 1. **Utiliser un VRAI appareil iOS**
   - ❌ **iOS Simulator ne supporte PAS les notifications push**
   - ✅ **Vous DEVEZ tester sur un iPhone/iPad réel**
   - Les notifications push ne fonctionnent que sur de vrais appareils

### 2. **Activer Push Notifications dans Xcode**

1. Ouvrez `ios/Runner.xcworkspace` dans Xcode (pas .xcodeproj)
2. Sélectionnez le target "Runner"
3. Allez dans l'onglet "Signing & Capabilities"
4. Cliquez sur "+ Capability"
5. Ajoutez "Push Notifications"
6. Vérifiez que "Push Notifications" apparaît dans la liste

### 3. **Vérifier les Entitlements**

Les fichiers `RunnerDebug.entitlements` et `RunnerRelease.entitlements` doivent contenir :
```xml
<key>aps-environment</key>
<string>development</string>  <!-- ou "production" pour Release -->
```

### 4. **Configurer APNS dans Firebase Console**

#### Option A : Utiliser une Clé APNS (Recommandé - Plus Simple)

1. Créez une clé APNS sur [Apple Developer](https://developer.apple.com/account/resources/authkeys/list) :
   - Cliquez sur **+** pour créer une nouvelle clé
   - Nommez-la (ex: "APNS Key")
   - Cochez **Apple Push Notifications service (APNs)**
   - Téléchargez la clé (.p8) - **IMPORTANT : Une seule fois !**
   - Notez le **Key ID** et votre **Team ID**

2. Dans Firebase Console :
   - Allez sur [Firebase Console](https://console.firebase.google.com)
   - Sélectionnez votre projet
   - **Project Settings** → **Cloud Messaging**
   - Section **Apple app configuration**
   - Choisissez **APNs Authentication Key**
   - Uploader le fichier `.p8`
   - Entrer le **Key ID** et le **Team ID**

#### Option B : Utiliser un Certificat APNS

1. Créez un certificat APNS sur Apple Developer :
   - Choisissez **Apple Push Notification service SSL (Sandbox & Production)**
   - Sélectionnez votre App ID
   - Téléchargez le certificat (.cer)

2. Installez et exportez depuis Keychain Access :
   - Double-cliquez sur le .cer pour l'installer
   - Ouvrez Keychain Access
   - Exportez le certificat + clé en .p12

3. Convertir en .pem (si nécessaire) :
   ```bash
   openssl pkcs12 -in apns_certificate.p12 -out apns_certificate.pem -nodes
   ```

4. Dans Firebase Console :
   - **Project Settings** → **Cloud Messaging**
   - Section **Apple app configuration**
   - Uploader le fichier `.p12` ou `.pem`
   - Entrer le mot de passe si nécessaire

### 5. **Vérifier GoogleService-Info.plist**

Assurez-vous que `ios/Runner/GoogleService-Info.plist` est présent et correct.

### 6. **Vérifier les permissions**

L'app doit demander les permissions de notification. Vérifiez dans :
- Settings → [Votre App] → Notifications
- Les notifications doivent être activées

### 7. **Rebuild l'app**

Après avoir fait les modifications dans Xcode :
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

## 🔍 Diagnostic

### Vérifier les logs

Cherchez dans les logs :
- ✅ `APNS Token received` = Le token APNS est disponible
- ✅ `FCM TOKEN SUCCESSFULLY RETRIEVED` = Le token FCM est disponible
- ❌ `APNS Token not available yet` = Problème de configuration

### Problèmes courants

1. **"APNS Token not available yet"**
   - Cause : Simulateur iOS ou Push Notifications non activé dans Xcode
   - Solution : Utiliser un vrai appareil et activer Push Notifications dans Xcode

2. **Notifications reçues mais pas affichées**
   - Cause : Permissions non accordées
   - Solution : Aller dans Settings → [App] → Notifications et activer

3. **Token FCM obtenu mais notifications ne fonctionnent pas**
   - Cause : Certificat APNS non configuré dans Firebase
   - Solution : Configurer le certificat APNS dans Firebase Console

## 📱 Test sur un appareil réel

1. Connectez votre iPhone/iPad à votre Mac
2. Dans Xcode, sélectionnez votre appareil comme destination
3. Lancez l'app depuis Xcode (pas depuis Flutter directement)
4. Accordez les permissions de notification quand demandé
5. Vérifiez les logs pour voir si le token APNS est reçu

## 🔗 Ressources

- [Firebase Cloud Messaging iOS Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)

