#!/bin/bash
# Script d'aide au déploiement et debug - TP-6 N8N sur AKS

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions utilitaires
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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Vérifier les prérequis
check_prerequisites() {
    print_header "Vérification des prérequis"
    
    local all_ok=true
    
    # Vérifier Azure CLI
    if command -v az &> /dev/null; then
        print_success "Azure CLI installé: $(az version --query '"azure-cli"' -o tsv)"
    else
        print_error "Azure CLI non installé"
        all_ok=false
    fi
    
    # Vérifier Terraform
    if command -v terraform &> /dev/null; then
        print_success "Terraform installé: $(terraform version -json | jq -r '.terraform_version')"
    else
        print_error "Terraform non installé"
        all_ok=false
    fi
    
    # Vérifier kubectl
    if command -v kubectl &> /dev/null; then
        print_success "kubectl installé: $(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')"
    else
        print_error "kubectl non installé"
        all_ok=false
    fi
    
    # Vérifier Docker
    if command -v docker &> /dev/null; then
        print_success "Docker installé: $(docker version --format '{{.Client.Version}}')"
    else
        print_warning "Docker non installé (optionnel pour build d'images)"
    fi
    
    # Vérifier jq
    if command -v jq &> /dev/null; then
        print_success "jq installé"
    else
        print_warning "jq non installé (recommandé)"
    fi
    
    if [ "$all_ok" = false ]; then
        print_error "Certains outils requis sont manquants. Installation nécessaire."
        exit 1
    fi
    
    print_success "Tous les prérequis sont satisfaits"
}

# Vérifier la connexion Azure
check_azure_connection() {
    print_header "Vérification de la connexion Azure"
    
    if az account show &> /dev/null; then
        local subscription=$(az account show --query name -o tsv)
        local account=$(az account show --query user.name -o tsv)
        print_success "Connecté à Azure"
        print_info "Compte: $account"
        print_info "Subscription: $subscription"
    else
        print_error "Non connecté à Azure. Exécutez 'az login'"
        exit 1
    fi
}

# Initialiser Terraform
init_terraform() {
    print_header "Initialisation de Terraform"
    
    cd terraform
    
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars n'existe pas"
        print_info "Copie de terraform.tfvars.example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Veuillez éditer terraform.tfvars avec vos valeurs avant de continuer"
        exit 1
    fi
    
    terraform init
    terraform fmt
    terraform validate
    
    print_success "Terraform initialisé et validé"
    cd ..
}

# Afficher le plan Terraform
show_plan() {
    print_header "Plan d'exécution Terraform"
    
    cd terraform
    terraform plan -out=tfplan
    print_success "Plan généré: terraform/tfplan"
    cd ..
}

# Déployer l'infrastructure
deploy_infrastructure() {
    print_header "Déploiement de l'infrastructure"
    
    cd terraform
    
    if [ -f "tfplan" ]; then
        terraform apply tfplan
    else
        terraform apply
    fi
    
    print_success "Infrastructure déployée"
    
    # Sauvegarder les outputs
    terraform output -json > ../outputs.json
    print_success "Outputs sauvegardés dans outputs.json"
    
    cd ..
}

# Configurer kubectl
configure_kubectl() {
    print_header "Configuration de kubectl pour AKS"
    
    local rg_name=$(jq -r '.resource_group_name.value' outputs.json)
    local aks_name=$(jq -r '.aks_cluster_name.value' outputs.json)
    
    az aks get-credentials \
        --resource-group "$rg_name" \
        --name "$aks_name" \
        --overwrite-existing
    
    print_success "kubectl configuré pour $aks_name"
    
    kubectl get nodes
}

# Préparer l'image N8N
prepare_image() {
    print_header "Préparation de l'image N8N"
    
    local acr_login=$(jq -r '.acr_login_server.value' outputs.json)
    
    print_info "ACR: $acr_login"
    
    # Login à l'ACR
    az acr login --name $(echo $acr_login | cut -d'.' -f1)
    
    print_info "Pull de l'image officielle N8N..."
    docker pull n8nio/n8n:latest
    
    print_info "Tag de l'image..."
    docker tag n8nio/n8n:latest $acr_login/n8n:1.0.0
    
    print_info "Push vers l'ACR..."
    docker push $acr_login/n8n:1.0.0
    
    print_success "Image N8N disponible dans l'ACR"
    
    # Mettre à jour les manifestes
    print_info "Mise à jour des manifestes K8s..."
    sed -i "s|REPLACE_IMAGE_WITH_ACR_PATH:TAG|$acr_login/n8n:1.0.0|g" k8s/n8n-deployments.yaml
    
    print_success "Manifestes mis à jour"
}

# Déployer sur Kubernetes
deploy_kubernetes() {
    print_header "Déploiement sur Kubernetes"
    
    print_info "⚠️  Les ConfigMaps et Secrets sont maintenant gérés par Terraform"
    print_info "   Seuls les Deployments et Services seront appliqués"
    
    # Vérifier que le namespace existe (normalement créé par Terraform)
    if kubectl get namespace n8n &> /dev/null; then
        print_success "Namespace n8n existe"
    else
        print_warning "Namespace n8n n'existe pas - il devrait être créé par Terraform"
        print_info "Exécutez 'terraform apply' d'abord"
        return 1
    fi
    
    # Vérifier que le ConfigMap existe (créé par Terraform)
    if kubectl get configmap n8n-config-vars -n n8n &> /dev/null; then
        print_success "ConfigMap n8n-config-vars existe (créé par Terraform)"
    else
        print_error "ConfigMap n8n-config-vars n'existe pas"
        print_info "Exécutez 'terraform apply' pour créer les ressources K8s"
        return 1
    fi
    
    # Vérifier que le Secret existe (créé par Terraform)
    if kubectl get secret n8n-sensitive-secrets -n n8n &> /dev/null; then
        print_success "Secret n8n-sensitive-secrets existe (créé par Terraform)"
    else
        print_error "Secret n8n-sensitive-secrets n'existe pas"
        print_info "Exécutez 'terraform apply' pour créer les ressources K8s"
        return 1
    fi
    
    # Appliquer uniquement les Services et Deployments
    print_info "Application des Services..."
    kubectl apply -f k8s/n8n-services.yaml
    
    print_info "Application des Deployments..."
    kubectl apply -f k8s/n8n-deployments.yaml
    
    print_success "Ressources Kubernetes déployées"
    
    print_info "Attente que les pods soient prêts..."
    kubectl wait --for=condition=ready pod -l app=n8n-main -n n8n --timeout=300s || true
    
    # Afficher le status
    kubectl get all -n n8n
}

# Obtenir l'URL d'accès
get_access_url() {
    print_header "URL d'accès à N8N"
    
    print_info "Récupération de l'IP externe..."
    
    # Attendre que le LoadBalancer soit prêt
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local external_ip=$(kubectl get svc n8n-service -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        
        if [ -n "$external_ip" ] && [ "$external_ip" != "null" ]; then
            print_success "N8N accessible sur: http://$external_ip"
            echo ""
            print_info "Ouvrez votre navigateur et accédez à: http://$external_ip"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 10
    done
    
    echo ""
    print_warning "L'IP externe n'est pas encore disponible"
    print_info "Vérifiez avec: kubectl get svc n8n-service -n n8n --watch"
}

# Afficher les logs
show_logs() {
    print_header "Logs des applications"
    
    echo "=== Logs N8N Main ==="
    kubectl logs -n n8n -l app=n8n-main --tail=50 --prefix=true
    
    echo ""
    echo "=== Logs N8N Workers ==="
    kubectl logs -n n8n -l app=n8n-workers --tail=50 --prefix=true
}

# Afficher le status complet
show_status() {
    print_header "Status de l'infrastructure"
    
    echo "=== Nodes ==="
    kubectl get nodes
    
    echo ""
    echo "=== Pods ==="
    kubectl get pods -n n8n -o wide
    
    echo ""
    echo "=== Services ==="
    kubectl get svc -n n8n
    
    echo ""
    echo "=== ConfigMaps ==="
    kubectl get configmap -n n8n
    
    echo ""
    echo "=== Secrets ==="
    kubectl get secrets -n n8n
    
    echo ""
    echo "=== Events récents ==="
    kubectl get events -n n8n --sort-by='.lastTimestamp' | tail -20
}

# Tester les connexions
test_connections() {
    print_header "Test des connexions"
    
    if [ ! -f "outputs.json" ]; then
        print_error "outputs.json non trouvé. Déployez l'infrastructure d'abord."
        return 1
    fi
    
    local pg_host=$(jq -r '.postgresql_fqdn.value' outputs.json)
    local redis_host=$(jq -r '.redis_hostname.value' outputs.json)
    
    print_info "Test PostgreSQL: $pg_host"
    kubectl run -n n8n psql-test --rm -it --image=postgres:14 --restart=Never -- \
        psql "host=$pg_host port=5432 sslmode=require" -c "SELECT version();" || true
    
    print_info "Test Redis: $redis_host"
    kubectl run -n n8n redis-test --rm -it --image=redis:alpine --restart=Never -- \
        redis-cli -h $redis_host --tls PING || true
}

# Nettoyer les ressources
cleanup() {
    print_header "Nettoyage des ressources"
    
    read -p "Voulez-vous vraiment supprimer toutes les ressources ? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Nettoyage annulé"
        return 0
    fi
    
    print_info "Suppression des ressources Kubernetes..."
    kubectl delete -f k8s/ -n n8n --ignore-not-found=true
    
    print_info "Suppression de l'infrastructure Terraform..."
    cd terraform
    terraform destroy -auto-approve
    cd ..
    
    print_success "Nettoyage terminé"
}

# Menu principal
show_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║   TP-6 N8N sur AKS - Script de Déploiement     ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    echo "1)  Vérifier les prérequis"
    echo "2)  Initialiser Terraform"
    echo "3)  Voir le plan Terraform"
    echo "4)  Déployer l'infrastructure complète"
    echo "5)  Configurer kubectl"
    echo "6)  Préparer l'image N8N"
    echo "7)  Déployer sur Kubernetes"
    echo "8)  Obtenir l'URL d'accès"
    echo "9)  Afficher les logs"
    echo "10) Afficher le status"
    echo "11) Tester les connexions"
    echo "12) Nettoyer les ressources"
    echo "0)  Quitter"
    echo ""
    read -p "Choisissez une option: " choice
    
    case $choice in
        1) check_prerequisites ;;
        2) init_terraform ;;
        3) show_plan ;;
        4) 
            check_prerequisites
            check_azure_connection
            init_terraform
            deploy_infrastructure
            configure_kubectl
            ;;
        5) configure_kubectl ;;
        6) prepare_image ;;
        7) deploy_kubernetes ;;
        8) get_access_url ;;
        9) show_logs ;;
        10) show_status ;;
        11) test_connections ;;
        12) cleanup ;;
        0) exit 0 ;;
        *) print_error "Option invalide" ;;
    esac
}

# Point d'entrée
main() {
    # Si un argument est passé, exécuter directement la fonction
    if [ $# -gt 0 ]; then
        case $1 in
            check) check_prerequisites ;;
            init) init_terraform ;;
            plan) show_plan ;;
            deploy) deploy_infrastructure ;;
            full-deploy)
                check_prerequisites
                check_azure_connection
                init_terraform
                deploy_infrastructure
                configure_kubectl
                prepare_image
                deploy_kubernetes
                get_access_url
                ;;
            kubectl) configure_kubectl ;;
            image) prepare_image ;;
            k8s) deploy_kubernetes ;;
            url) get_access_url ;;
            logs) show_logs ;;
            status) show_status ;;
            test) test_connections ;;
            clean) cleanup ;;
            *) 
                echo "Usage: $0 {check|init|plan|deploy|full-deploy|kubectl|image|k8s|url|logs|status|test|clean}"
                exit 1
                ;;
        esac
    else
        # Mode interactif
        while true; do
            show_menu
        done
    fi
}

# Exécution
main "$@"
