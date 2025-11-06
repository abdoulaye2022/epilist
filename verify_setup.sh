#!/bin/bash

# Script de vérification de l'installation EpiList
# Version 1.1.4
# Date: 4 janvier 2025

set -e  # Arrêter en cas d'erreur

echo "=========================================="
echo "   Vérification EpiList v1.1.4"
echo "=========================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs
SUCCESS=0
WARNINGS=0
ERRORS=0

# Fonction pour afficher un succès
success() {
    echo -e "${GREEN}✓${NC} $1"
    ((SUCCESS++))
}

# Fonction pour afficher un warning
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Fonction pour afficher une erreur
error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

echo "1. Vérification de Flutter..."
echo "-----------------------------"

if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    success "Flutter installé: $FLUTTER_VERSION"
else
    error "Flutter n'est pas installé"
fi

echo ""
echo "2. Vérification des dépendances..."
echo "-----------------------------------"

if [ -f "app/pubspec.yaml" ]; then
    success "pubspec.yaml trouvé"

    # Vérifier mobile_scanner
    if grep -q "mobile_scanner:" app/pubspec.yaml; then
        success "mobile_scanner présent dans pubspec.yaml"
    else
        error "mobile_scanner manquant dans pubspec.yaml"
    fi

    # Vérifier http
    if grep -q "http:" app/pubspec.yaml; then
        success "http présent dans pubspec.yaml"
    else
        error "http manquant dans pubspec.yaml"
    fi
else
    error "pubspec.yaml non trouvé"
fi

echo ""
echo "3. Vérification des fichiers créés..."
echo "--------------------------------------"

# Vérifier les nouveaux fichiers Flutter
FILES=(
    "app/lib/screens/barcode_scanner_screen.dart"
    "app/lib/services/product_api_service.dart"
    "app/lib/models/product_info.dart"
    "app/lib/widgets/list_detail/product_info_dialog.dart"
    "app/lib/config/app_theme.dart"
    "app/lib/widgets/animations/fade_in_animation.dart"
    "app/lib/widgets/cards/modern_list_card.dart"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        success "$file"
    else
        error "$file manquant"
    fi
done

# Vérifier la migration
if [ -f "api/migrations/add_barcode_to_list_items.sql" ]; then
    success "Migration SQL présente"
else
    error "Migration SQL manquante"
fi

# Vérifier la documentation
if [ -f "AMELIORATIONS.md" ]; then
    success "AMELIORATIONS.md présent"
else
    warning "AMELIORATIONS.md manquant"
fi

if [ -f "GUIDE_UTILISATION.md" ]; then
    success "GUIDE_UTILISATION.md présent"
else
    warning "GUIDE_UTILISATION.md manquant"
fi

echo ""
echo "4. Vérification de la base de données..."
echo "----------------------------------------"

# Vérifier si MySQL est accessible
if command -v mysql &> /dev/null; then
    success "MySQL est installé"

    # Vérifier la connexion à la base de données
    if mysql -u root -e "USE epilist;" 2>/dev/null; then
        success "Connexion à la base de données epilist réussie"

        # Vérifier si la colonne barcode existe
        if mysql -u root epilist -e "DESCRIBE list_items;" 2>/dev/null | grep -q "barcode"; then
            success "Colonne 'barcode' présente dans list_items"
        else
            warning "Colonne 'barcode' absente - Migration non exécutée"
        fi

        # Vérifier si la table scanned_products existe
        if mysql -u root epilist -e "SHOW TABLES LIKE 'scanned_products';" 2>/dev/null | grep -q "scanned_products"; then
            success "Table 'scanned_products' présente"
        else
            warning "Table 'scanned_products' absente - Migration non exécutée"
        fi
    else
        error "Impossible de se connecter à la base de données epilist"
    fi
else
    error "MySQL n'est pas installé"
fi

echo ""
echo "5. Vérification du code (emojis supprimés)..."
echo "---------------------------------------------"

# Vérifier qu'il n'y a plus d'emojis dans les fichiers de localisation
if [ -f "app/lib/l10n/app_fr.arb" ]; then
    EMOJI_COUNT=$(grep -P '[\x{1F300}-\x{1F9FF}]' app/lib/l10n/app_fr.arb | wc -l)
    if [ "$EMOJI_COUNT" -eq 0 ]; then
        success "Pas d'emojis dans app_fr.arb"
    else
        warning "$EMOJI_COUNT emojis trouvés dans app_fr.arb"
    fi
fi

if [ -f "app/lib/l10n/app_en.arb" ]; then
    EMOJI_COUNT=$(grep -P '[\x{1F300}-\x{1F9FF}]' app/lib/l10n/app_en.arb | wc -l)
    if [ "$EMOJI_COUNT" -eq 0 ]; then
        success "Pas d'emojis dans app_en.arb"
    else
        warning "$EMOJI_COUNT emojis trouvés dans app_en.arb"
    fi
fi

echo ""
echo "6. Vérification des permissions..."
echo "-----------------------------------"

# Android
if [ -f "app/android/app/src/main/AndroidManifest.xml" ]; then
    if grep -q "android.permission.CAMERA" app/android/app/src/main/AndroidManifest.xml; then
        success "Permission CAMERA présente dans AndroidManifest.xml"
    else
        warning "Permission CAMERA manquante dans AndroidManifest.xml"
    fi
else
    warning "AndroidManifest.xml non trouvé"
fi

# iOS
if [ -f "app/ios/Runner/Info.plist" ]; then
    if grep -q "NSCameraUsageDescription" app/ios/Runner/Info.plist; then
        success "NSCameraUsageDescription présente dans Info.plist"
    else
        warning "NSCameraUsageDescription manquante dans Info.plist"
    fi
else
    warning "Info.plist non trouvé (normal si pas sur Mac)"
fi

echo ""
echo "7. Test de compilation Flutter..."
echo "---------------------------------"

cd app
if flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1 | grep -q "No issues found"; then
    success "Analyse Flutter: Aucun problème"
else
    warning "Analyse Flutter: Des avertissements ont été trouvés"
fi
cd ..

echo ""
echo "=========================================="
echo "           RÉSUMÉ"
echo "=========================================="
echo -e "${GREEN}Succès:${NC} $SUCCESS"
echo -e "${YELLOW}Avertissements:${NC} $WARNINGS"
echo -e "${RED}Erreurs:${NC} $ERRORS"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ L'installation est prête!${NC}"
    echo ""
    echo "Prochaines étapes:"
    echo "1. Exécuter la migration si pas encore fait:"
    echo "   cd api/migrations && mysql -u root epilist < add_barcode_to_list_items.sql"
    echo ""
    echo "2. Tester l'application:"
    echo "   cd app && flutter run"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Des erreurs ont été détectées${NC}"
    echo "Veuillez corriger les erreurs avant de continuer."
    echo ""
    exit 1
fi
