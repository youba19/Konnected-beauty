# Guide de Conversion du Certificat APNS

## Méthode 1 : Conversion .p12 vers .pem (pour Firebase)

### Étape 1 : Exporter le certificat depuis Keychain Access

1. Ouvrez **Keychain Access** sur votre Mac
2. Dans la section "My Certificates", trouvez votre certificat APNS
3. Cliquez droit sur le certificat → **Export**
4. Choisissez le format **.p12** (Personal Information Exchange)
5. Entrez un mot de passe pour protéger le fichier
6. Sauvegardez le fichier (ex: `apns_certificate.p12`)

### Étape 2 : Convertir .p12 en .pem

Ouvrez le Terminal et exécutez :

```bash
# Convertir .p12 en .pem (certificat + clé privée)
openssl pkcs12 -in Certificates.p12 -out Certificates.pem -nodes

# Vous serez demandé d'entrer le mot de passe du fichier .p12
# Entrez le mot de passe que vous avez défini lors de l'export
```

**Explication des paramètres :**
- `-in apns_certificate.p12` : Fichier d'entrée (.p12)
- `-out apns_certificate.pem` : Fichier de sortie (.pem)
- `-nodes` : Ne pas chiffrer la clé privée dans le fichier de sortie

### Étape 3 : Séparer le certificat et la clé privée (optionnel)

Si Firebase nécessite des fichiers séparés :

```bash
# Extraire uniquement le certificat (sans clé privée)
openssl pkcs12 -in apns_certificate.p12 -clcerts -nokeys -out apns_cert.pem

# Extraire uniquement la clé privée
openssl pkcs12 -in apns_certificate.p12 -nocerts -nodes -out apns_key.pem
```

## Méthode 2 : Utiliser directement .p12 dans Firebase

Firebase accepte aussi les fichiers .p12 directement :

1. Allez dans Firebase Console → Project Settings → Cloud Messaging
2. Section "Apple app configuration"
3. Cliquez sur "Upload" pour le certificat
4. Sélectionnez votre fichier `.p12`
5. Entrez le mot de passe du fichier .p12

## Méthode 3 : Utiliser une Clé APNS (Recommandé - Plus Simple)

Au lieu d'un certificat, utilisez une clé APNS (plus moderne et plus simple) :

### Créer la clé APNS :

1. Allez sur [Apple Developer](https://developer.apple.com/account/resources/authkeys/list)
2. Cliquez sur **+** pour créer une nouvelle clé
3. Donnez un nom à la clé (ex: "APNS Key")
4. Cochez **Apple Push Notifications service (APNs)**
5. Cliquez sur **Continue** puis **Register**
6. **Téléchargez la clé** (.p8) - **IMPORTANT : Vous ne pourrez la télécharger qu'une seule fois !**
7. Notez le **Key ID** affiché
8. Notez votre **Team ID** (visible en haut à droite de la page)

### Configurer dans Firebase :

1. Firebase Console → Project Settings → Cloud Messaging
2. Section "Apple app configuration"
3. Choisissez **APNs Authentication Key** (au lieu de Certificate)
4. Uploader le fichier `.p8`
5. Entrer le **Key ID**
6. Entrer le **Team ID**

## Vérification

Après avoir configuré le certificat ou la clé dans Firebase :

1. Relancez l'app sur votre appareil iOS
2. Vérifiez les logs pour voir :
   ```
   ✅ APNS Token received: ...
   ✅ FCM TOKEN SUCCESSFULLY RETRIEVED (iOS)!
   ```

## Commandes utiles

### Vérifier le contenu d'un fichier .p12 :
```bash
openssl pkcs12 -info -in apns_certificate.p12 -noout
```

### Vérifier le contenu d'un fichier .pem :
```bash
openssl x509 -in apns_certificate.pem -text -noout
```

### Vérifier une clé privée :
```bash
openssl rsa -in apns_key.pem -check
```

## Notes importantes

- ⚠️ **Sécurité** : Les fichiers .p12 et .pem contiennent votre clé privée. Ne les partagez jamais publiquement !
- ✅ **Recommandation** : Utilisez une **Clé APNS (.p8)** plutôt qu'un certificat - c'est plus simple et plus moderne
- 🔒 **Mot de passe** : Si vous oubliez le mot de passe du .p12, vous devrez recréer le certificat

