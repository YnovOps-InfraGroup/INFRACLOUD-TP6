#!/bin/bash
# Script de configuration GitHub Actions pour TP-6

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Variables
SUBSCRIPTION_ID="cd3fa1ba-5253-4f92-8571-9b1fde759c19"
RG_NAME="RG-N8N-AKS"
SP_NAME="github-actions-tp6"
KV_NAME="akv-n8n-tf-secrets"
PG_PASSWORD="#DFCEfO3L^4N8jAA"

print_header "Configuration GitHub Actions - TP-6"

# Vérifier Azure CLI
if ! command -v az &> /dev/null; then
    print_error "Azure CLI n'est pas installé"
    exit 1
fi

# Login Azure
print_info "Vérification de la connexion Azure..."
if ! az account show &> /dev/null; then
    print_info "Connexion à Azure..."
    az login
fi

az account set --subscription "$SUBSCRIPTION_ID"
print_success "Connecté à la subscription $SUBSCRIPTION_ID"

# Créer le Service Principal
print_header "Création du Service Principal"

print_info "Création du Service Principal '$SP_NAME'..."

SP_JSON=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role contributor \
    --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME" \
    --sdk-auth 2>/dev/null)

if [ $? -eq 0 ]; then
    print_success "Service Principal créé"
    
    # Sauvegarder dans un fichier
    echo "$SP_JSON" > azure-credentials.json
    print_success "Credentials sauvegardées dans: azure-credentials.json"
    
    # Afficher pour copier
    echo ""
    print_info "===== AZURE_CREDENTIALS (copier dans GitHub Secret) ====="
    echo "$SP_JSON"
    echo "=========================================================="
    echo ""
else
    print_error "Erreur lors de la création du Service Principal"
    exit 1
fi

# Récupérer l'Object ID du SP
print_info "Récupération de l'Object ID du Service Principal..."
SP_OBJECT_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].id" -o tsv)

if [ -z "$SP_OBJECT_ID" ]; then
    print_error "Impossible de récupérer l'Object ID"
    exit 1
fi

print_success "Object ID: $SP_OBJECT_ID"

# Donner les permissions sur le Key Vault
print_header "Configuration des Permissions Key Vault"

print_info "Attribution des permissions sur $KV_NAME..."

az keyvault set-policy \
    --name "$KV_NAME" \
    --object-id "$SP_OBJECT_ID" \
    --secret-permissions get list set delete \
    > /dev/null 2>&1

if [ $? -eq 0 ]; then
    print_success "Permissions Key Vault configurées"
else
    print_error "Erreur lors de la configuration des permissions Key Vault"
    print_info "Le Key Vault existe-t-il ? Vérifiez avec: az keyvault show --name $KV_NAME"
fi

# Résumé des secrets GitHub
print_header "Secrets à Configurer dans GitHub"

echo "Allez dans votre repo GitHub :"
echo "Settings → Secrets and variables → Actions → New repository secret"
echo ""
echo "Créez ces 2 secrets :"
echo ""
echo "1. Nom: AZURE_CREDENTIALS"
echo "   Valeur: (Copiez le JSON affiché ci-dessus ou depuis azure-credentials.json)"
echo ""
echo "2. Nom: PG_ADMIN_PASSWORD"
echo "   Valeur: $PG_PASSWORD"
echo ""

# Vérification
print_header "Vérification"

print_info "Vérification du Service Principal..."
az ad sp show --id "$SP_OBJECT_ID" > /dev/null 2>&1 && print_success "Service Principal OK" || print_error "Service Principal non trouvé"

print_info "Vérification du Resource Group..."
az group show --name "$RG_NAME" > /dev/null 2>&1 && print_success "Resource Group OK" || print_error "Resource Group non trouvé"

print_info "Vérification du Key Vault..."
az keyvault show --name "$KV_NAME" > /dev/null 2>&1 && print_success "Key Vault OK" || print_error "Key Vault non trouvé"

# Instructions finales
print_header "Prochaines Étapes"

echo "1. ✅ Copiez le contenu de azure-credentials.json dans le secret AZURE_CREDENTIALS"
echo "2. ✅ Créez le secret PG_ADMIN_PASSWORD avec la valeur: $PG_PASSWORD"
echo "3. ✅ Committez et pushez le workflow: .github/workflows/deploy.yml"
echo "4. ✅ Le pipeline se déclenchera automatiquement sur push"
echo ""
print_info "Pour tester manuellement: Actions → Deploy Infrastructure → Run workflow"
echo ""

# Nettoyer
print_info "Le fichier azure-credentials.json contient des informations sensibles."
print_info "Supprimez-le après avoir configuré GitHub : rm azure-credentials.json"

print_success "Configuration terminée !"
