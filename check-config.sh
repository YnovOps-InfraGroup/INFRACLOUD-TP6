#!/bin/bash
# check-config.sh - Vérifier la configuration avant déploiement

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     VÉRIFICATION CONFIGURATION TP-6 - N8N AKS            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Vérifier Azure CLI
echo -e "${YELLOW}[1/8]${NC} Vérification Azure CLI..."
if command -v az &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Azure CLI installé : $(az version --query '\"azure-cli\"' -o tsv)"
else
    echo -e "  ${RED}✗${NC} Azure CLI non trouvé"
    exit 1
fi

# 2. Vérifier connexion Azure
echo -e "${YELLOW}[2/8]${NC} Vérification connexion Azure..."
if az account show &> /dev/null; then
    SUBSCRIPTION=$(az account show --query name -o tsv)
    echo -e "  ${GREEN}✓${NC} Connecté à : $SUBSCRIPTION"
else
    echo -e "  ${RED}✗${NC} Non connecté à Azure. Exécutez : az login"
    exit 1
fi

# 3. Vérifier Resource Group
echo -e "${YELLOW}[3/8]${NC} Vérification Resource Group..."
if az group show --name RG-N8N-AKS &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Resource Group 'RG-N8N-AKS' existe"
else
    echo -e "  ${RED}✗${NC} Resource Group 'RG-N8N-AKS' non trouvé"
    exit 1
fi

# 4. Vérifier AKS
echo -e "${YELLOW}[4/8]${NC} Vérification AKS Cluster..."
if az aks show --resource-group RG-N8N-AKS --name aks-n8n-cluster &> /dev/null; then
    AKS_STATUS=$(az aks show --resource-group RG-N8N-AKS --name aks-n8n-cluster --query provisioningState -o tsv)
    echo -e "  ${GREEN}✓${NC} AKS 'aks-n8n-cluster' existe (Status: $AKS_STATUS)"
else
    echo -e "  ${RED}✗${NC} AKS 'aks-n8n-cluster' non trouvé"
    exit 1
fi

# 5. Vérifier Key Vault
echo -e "${YELLOW}[5/8]${NC} Vérification Key Vault..."
if az keyvault show --name akv-n8n-tf-secrets &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Key Vault 'akv-n8n-tf-secrets' existe"
    
    # Vérifier permissions Service Principal
    SP_ID="df5bd568-b12d-4f9a-bb6d-79901ca7d3c7"
    POLICIES=$(az keyvault show --name akv-n8n-tf-secrets --query "properties.accessPolicies[?objectId=='$SP_ID'].permissions.secrets" -o tsv)
    
    if [[ -n "$POLICIES" ]]; then
        echo -e "  ${GREEN}✓${NC} Service Principal a des permissions sur Key Vault"
    else
        echo -e "  ${YELLOW}⚠${NC}  Service Principal n'a pas de permissions. Exécutez :"
        echo -e "     ${BLUE}az keyvault set-policy --name akv-n8n-tf-secrets --spn $SP_ID --secret-permissions get list set delete${NC}"
    fi
else
    echo -e "  ${RED}✗${NC} Key Vault 'akv-n8n-tf-secrets' non trouvé"
    exit 1
fi

# 6. Vérifier PostgreSQL
echo -e "${YELLOW}[6/8]${NC} Vérification PostgreSQL..."
if az postgres flexible-server show --resource-group RG-N8N-AKS --name pg-n8n-tf-server &> /dev/null; then
    PG_FQDN=$(az postgres flexible-server show --resource-group RG-N8N-AKS --name pg-n8n-tf-server --query fullyQualifiedDomainName -o tsv)
    echo -e "  ${GREEN}✓${NC} PostgreSQL 'pg-n8n-tf-server' existe"
    echo -e "     FQDN: $PG_FQDN"
else
    echo -e "  ${RED}✗${NC} PostgreSQL 'pg-n8n-tf-server' non trouvé"
    exit 1
fi

# 7. Vérifier Redis
echo -e "${YELLOW}[7/8]${NC} Vérification Redis..."
if az redis show --resource-group RG-N8N-AKS --name redis-n8n-tf-cache &> /dev/null; then
    REDIS_HOST=$(az redis show --resource-group RG-N8N-AKS --name redis-n8n-tf-cache --query hostName -o tsv)
    echo -e "  ${GREEN}✓${NC} Redis 'redis-n8n-tf-cache' existe"
    echo -e "     Hostname: $REDIS_HOST"
else
    echo -e "  ${RED}✗${NC} Redis 'redis-n8n-tf-cache' non trouvé"
    exit 1
fi

# 8. Vérifier Terraform
echo -e "${YELLOW}[8/8]${NC} Vérification Terraform..."
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json | jq -r '.terraform_version')
    echo -e "  ${GREEN}✓${NC} Terraform installé : v$TF_VERSION"
    
    # Vérifier configuration Terraform
    cd terraform
    if terraform validate &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Configuration Terraform valide"
    else
        echo -e "  ${RED}✗${NC} Configuration Terraform invalide"
        terraform validate
        exit 1
    fi
    cd ..
else
    echo -e "  ${YELLOW}⚠${NC}  Terraform non installé (optionnel pour GitHub Actions)"
fi

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    RÉSUMÉ CONFIGURATION                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ Toutes les ressources Azure sont en place${NC}"
echo -e "${GREEN}✓ Configuration Terraform valide${NC}"
echo ""
echo -e "${YELLOW}Prochaines étapes :${NC}"
echo ""
echo -e "  1. ${BLUE}Vérifier permissions Key Vault${NC} (si non fait)"
echo -e "     az keyvault set-policy --name akv-n8n-tf-secrets \\"
echo -e "       --spn df5bd568-b12d-4f9a-bb6d-79901ca7d3c7 \\"
echo -e "       --secret-permissions get list set delete"
echo ""
echo -e "  2. ${BLUE}Commit et Push${NC}"
echo -e "     git add ."
echo -e "     git commit -m \"feat: configuration K8s dynamique via Terraform\""
echo -e "     git push origin main"
echo ""
echo -e "  3. ${BLUE}Surveiller le pipeline${NC}"
echo -e "     https://github.com/YnovOps-InfraGroup/INFRACLOUD-TP6/actions"
echo ""
echo -e "${GREEN}Tout est prêt pour le déploiement ! 🚀${NC}"
