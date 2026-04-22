#!/bin/bash

# Script pour mettre à jour Flutter et reconstruire le bundle avec support 16KB

echo "🔄 Mise à jour de Flutter..."
flutter upgrade

echo ""
echo "✅ Vérification de la version Flutter..."
flutter --version

echo ""
echo "🧹 Nettoyage du projet..."
flutter clean

echo ""
echo "📦 Mise à jour des dépendances..."
flutter pub get
flutter pub upgrade

echo ""
echo "🔨 Construction du bundle avec support 16KB..."
flutter build appbundle --release --split-debug-info=build/app/debug-info --obfuscate

echo ""
echo "✅ Bundle créé avec succès !"
echo "📁 Emplacement: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "📋 Fichiers à téléverser:"
echo "   1. app-release.aab"
echo "   2. build/app/outputs/mapping/release/mapping.txt (fichier de désobscurcissement)"
echo ""
echo "⚠️  IMPORTANT: Vérifiez que la nouvelle version de Flutter supporte 16KB page size"
echo "   Les versions Flutter 3.24+ incluent le support 16KB"



