# TP-6 : N8N sur Azure Kubernetes Service (AKS)

Infrastructure as Code pour déployer N8N en mode haute disponibilité sur Azure AKS avec Terraform.

## 📋 Table des Matières

- [Architecture](#-architecture)
- [Prérequis](#-prérequis)
- [Configuration](#-configuration)
- [Déploiement](#-déploiement)
- [Validation](#-validation)
- [Accès à N8N](#-accès-à-n8n)
- [Troubleshooting](#-troubleshooting)
- [Maintenance](#-maintenance)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Azure Subscription                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │      Resource Group: RG-N8N-AKS                   │  │
│  │                                                    │  │
│  │  Virtual Network (10.0.0.0/16)                    │  │
│  │  ├── Snet-AKS (10.0.1.0/24)                       │  │
│  │  │   └── AKS Cluster                              │  │
│  │  │       ├── n8n-main (StatefulSet x2)            │  │
│  │  │       └── n8n-workers (Deployment x3)          │  │
│  │  │                                                 │  │
│  │  ├── Snet-DB (10.0.2.0/24)                        │  │
│  │  │   └── PostgreSQL Flexible Server               │  │
│  │  │                                                 │  │
│  │  └── Snet-ALB (10.0.4.0/24)                       │  │
│  │      └── Application Load Balancer                │  │
│  │                                                    │  │
│  │  Azure Services:                                   │  │
│  │  ├── Redis Cache (Queue)                          │  │
│  │  ├── Container Registry (ACR)                     │  │
│  │  └── Key Vault (Secrets)                          │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Composants

- **AKS** : Cluster Kubernetes avec 3 nodes
- **PostgreSQL** : Base de données principale (Flexible Server, accès privé uniquement)
- **Redis** : Cache et file d'attente pour executions
- **ACR** : Registry Docker privé
- **Key Vault** : Gestion sécurisée des secrets
- **Load Balancer** : Exposition publique de N8N

---

## ⚙️ Prérequis

### Outils Requis

```bash
# Azure CLI
az version  # >= 2.50.0

# Terraform
terraform version  # >= 1.9.0

# kubectl
kubectl version --client  # >= 1.28.0

# Docker (pour build custom)
docker version  # >= 24.0.0
```

### Installation Rapide

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

---

## 🔧 Configuration

### 1. Connexion Azure

```bash
az login
az account set --subscription "<VOTRE_SUBSCRIPTION_ID>"
```

### 2. Créer le Resource Group (si nécessaire)

```bash
az group create --name RG-N8N-AKS --location francecentral
```

### 3. Créer le Storage Account pour Terraform State

```bash
# Nom unique pour votre storage account
STORAGE_ACCOUNT="stotfstate$(openssl rand -hex 4)"

az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group RG-N8N-AKS \
  --location francecentral \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name $STORAGE_ACCOUNT

echo "Votre Storage Account: $STORAGE_ACCOUNT"
```

### 4. Variables Terraform

Créer `terraform/terraform.tfvars` :

```hcl
# Variables obligatoires
pg_admin_password    = "VotreMotDePasseSecurise123!"
pg_admin_user        = "n8nadmin"
n8n_encryption_key   = "VotreCleChiffrement32Caracteres!"

# Variables optionnelles (valeurs par défaut)
# location           = "francecentral"
# rg_name            = "RG-N8N-AKS"
```

**⚠️ Important** : Ajouter `terraform.tfvars` au `.gitignore` (déjà configuré) !

### 5. Backend Terraform

Modifier `terraform/backend.tf` avec votre Storage Account :

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "RG-N8N-AKS"
    storage_account_name = "VOTRE_STORAGE_ACCOUNT"  # Remplacer par le nom ci-dessus
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

---

## 🚀 Déploiement

### Déploiement Complet

```bash
# 1. Initialiser Terraform
cd terraform
terraform init

# 2. Valider la configuration
terraform fmt
terraform validate

# 3. Voir le plan d'exécution
terraform plan

# 4. Déployer l'infrastructure (prend 10-15 minutes)
terraform apply

# 5. Récupérer les credentials AKS
az aks get-credentials \
  --resource-group RG-N8N-AKS \
  --name aks-n8n-cluster \
  --overwrite-existing

# 6. Vérifier la connexion
kubectl get nodes

# 7. Déployer les ressources Kubernetes
cd ../k8s
kubectl apply -f n8n-deployments.yaml
kubectl apply -f n8n-services.yaml

# 8. Attendre que les pods démarrent (2-3 minutes)
kubectl get pods -n n8n -w
```

### Déploiement avec Image Custom

Si vous avez un `Dockerfile` personnalisé :

```bash
# 1. Récupérer l'URL ACR
ACR_SERVER=$(cd terraform && terraform output -raw acr_login_server)

# 2. Se connecter à ACR
az acr login --name $(echo $ACR_SERVER | cut -d'.' -f1)

# 3. Builder et pusher l'image
docker build -t $ACR_SERVER/n8n-custom:latest .
docker push $ACR_SERVER/n8n-custom:latest

# 4. Mettre à jour le deployment
sed -i "s|acrn8ntf8332.azurecr.io/n8n-custom:.*|$ACR_SERVER/n8n-custom:latest|g" k8s/n8n-deployments.yaml

# 5. Redéployer
kubectl apply -f k8s/n8n-deployments.yaml
kubectl rollout restart statefulset/n8n-main -n n8n
kubectl rollout restart deployment/n8n-workers -n n8n
```

---

## ✅ Validation

### 1. Vérifier l'Infrastructure Terraform

```bash
cd terraform

# Voir toutes les ressources créées (environ 25 ressources)
terraform state list

# Récupérer les informations importantes
terraform output

# Commandes de debug prêtes à l'emploi
terraform output debug_commands
```

### 2. Vérifier Kubernetes

```bash
# Namespaces
kubectl get namespaces

# Pods N8N (doit montrer 5 pods Running)
kubectl get pods -n n8n -o wide

# Services et IP publique
kubectl get svc -n n8n

# ConfigMap (créé automatiquement par Terraform avec valeurs dynamiques)
kubectl get configmap n8n-config-vars -n n8n -o yaml | grep -E "DB_HOST|REDIS_HOST"

# Secret (créé automatiquement par Terraform)
kubectl get secret n8n-sensitive-secrets -n n8n

# Logs des pods
kubectl logs -n n8n -l app=n8n-main --tail=50
```

### 3. Test de Santé

```bash
# Récupérer l'IP publique du LoadBalancer
N8N_IP=$(kubectl get svc n8n-service -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "N8N accessible sur: http://$N8N_IP"

# Test HTTP
curl -I http://$N8N_IP

# Ouvrir dans le navigateur
xdg-open http://$N8N_IP 2>/dev/null || open http://$N8N_IP 2>/dev/null || echo "Ouvrez manuellement: http://$N8N_IP"
```

**Résultat attendu** : `HTTP/1.1 200 OK`

---

## 🌐 Accès à N8N

### Obtenir l'URL

```bash
kubectl get svc n8n-service -n n8n
```

Ouvrez votre navigateur sur l'`EXTERNAL-IP` affiché.

### Première Connexion

1. Accédez à `http://<EXTERNAL-IP>`
2. Créez votre compte administrateur
3. Configurez vos workflows N8N

**Note** : En dev/test, le cookie sécurisé est désactivé (`N8N_SECURE_COOKIE=false`). Pour la production, configurez HTTPS avec un certificat SSL.

---

## 🐛 Troubleshooting

### Pods en CrashLoopBackOff

```bash
# Voir les logs du pod qui crash
kubectl logs -n n8n <POD_NAME> --previous

# Voir les événements détaillés
kubectl describe pod -n n8n <POD_NAME>

# Causes communes et solutions :
```

**1. Erreur PostgreSQL "no encryption" ou "WRONGPASS"**

```bash
# Vérifier que require_secure_transport est désactivé
az postgres flexible-server parameter show \
  --resource-group RG-N8N-AKS \
  --server-name pg-n8n-tf-server \
  --name require_secure_transport

# Doit retourner : "off"
# Si "on", c'est déjà dans la config Terraform (databases.tf)
```

**2. Erreur Redis "WRONGPASS"**

Le Secret Kubernetes contient un password mal encodé.

```bash
# Forcer la recréation du Secret par Terraform
cd terraform
terraform apply -replace=kubernetes_secret.n8n_secrets

# Redémarrer les pods
kubectl delete pod -n n8n --all
```

**3. Variables d'environnement manquantes**

```bash
# Vérifier que le ConfigMap contient les bonnes valeurs
kubectl get configmap n8n-config-vars -n n8n -o yaml

# Si incorrect, recréer via Terraform
cd terraform
terraform apply -replace=kubernetes_config_map.n8n_config
kubectl delete pod -n n8n --all
```

### Service LoadBalancer en Pending

```bash
# Vérifier les événements du service
kubectl describe svc n8n-service -n n8n

# Vérifier les quotas Azure pour les IP publiques
az network public-ip list --resource-group MC_RG-N8N-AKS_aks-n8n-cluster_francecentral

# Attendre 2-3 minutes pour la création automatique de l'IP publique
```

### Erreur "n8n does not have permission to use port 80"

N8N essaie d'écouter sur le port 80 au lieu de 5678.

```bash
# Vérifier que N8N_PORT n'est PAS défini dans le ConfigMap
kubectl get configmap n8n-config-vars -n n8n -o yaml | grep N8N_PORT

# Si présent, le retirer du ConfigMap Terraform (kubernetes-resources.tf)
# N8N doit écouter sur 5678 (défini dans le Deployment)
```

### Image Docker non trouvée

```bash
# Vérifier que l'image existe dans l'ACR
ACR_NAME=$(terraform output -raw acr_login_server | cut -d'.' -f1)
az acr repository list --name $ACR_NAME

# Se connecter à l'ACR et pousser l'image
az acr login --name $ACR_NAME
docker pull n8nio/n8n:latest
docker tag n8nio/n8n:latest $ACR_NAME.azurecr.io/n8n-custom:latest
docker push $ACR_NAME.azurecr.io/n8n-custom:latest
```

### Terraform Apply Échoue

```bash
# Voir les erreurs détaillées
terraform apply 2>&1 | tee terraform-errors.log

# Erreurs fréquentes :
# 1. Backend non initialisé → terraform init
# 2. Variables manquantes → vérifier terraform.tfvars
# 3. Permissions insuffisantes → vérifier Service Principal
```

---

## 🔄 Maintenance

### Mise à Jour de N8N

```bash
# Option 1 : Mettre à jour l'image directement
kubectl set image statefulset/n8n-main n8n=n8nio/n8n:latest -n n8n
kubectl set image deployment/n8n-workers n8n=n8nio/n8n:latest -n n8n

# Vérifier le rollout
kubectl rollout status statefulset/n8n-main -n n8n
kubectl rollout status deployment/n8n-workers -n n8n

# Option 2 : Modifier le deployment YAML
sed -i 's|n8n-custom:.*|n8n-custom:v1.2.0|g' k8s/n8n-deployments.yaml
kubectl apply -f k8s/n8n-deployments.yaml
```

### Scaling Horizontal

```bash
# Augmenter les workers (pour plus de throughput)
kubectl scale deployment n8n-workers --replicas=5 -n n8n

# Augmenter les mains (pour haute disponibilité)
kubectl scale statefulset n8n-main --replicas=3 -n n8n

# Vérifier
kubectl get pods -n n8n
```

### Scaling Vertical (Ressources)

Modifier `k8s/n8n-deployments.yaml` :

```yaml
resources:
  requests:
    cpu: "500m"      # Augmenter de 250m
    memory: "1024Mi" # Augmenter de 512Mi
  limits:
    cpu: "2000m"     # Augmenter de 1000m
    memory: "2048Mi" # Augmenter de 1024Mi
```

Puis :

```bash
kubectl apply -f k8s/n8n-deployments.yaml
kubectl rollout restart statefulset/n8n-main -n n8n
```

### Backup PostgreSQL

```bash
# Export manuel
kubectl run -n n8n pg-backup --rm -it --restart=Never \
  --image=postgres:14 --env="PGPASSWORD=VotrePassword" -- \
  pg_dump -h pg-n8n-tf-server.postgres.database.azure.com \
  -U n8nadmin -d n8n_db > backup-$(date +%Y%m%d).sql

# Ou via Azure
az postgres flexible-server backup create \
  --resource-group RG-N8N-AKS \
  --name pg-n8n-tf-server \
  --backup-name manual-backup-$(date +%Y%m%d)
```

### Rotation des Secrets

```bash
# 1. Générer un nouveau password PostgreSQL
NEW_PG_PASSWORD=$(openssl rand -base64 32)

# 2. Mettre à jour dans Key Vault
az keyvault secret set \
  --vault-name akv-n8n-tf-secrets \
  --name pg-admin-password \
  --value "$NEW_PG_PASSWORD"

# 3. Mettre à jour PostgreSQL
az postgres flexible-server update \
  --resource-group RG-N8N-AKS \
  --name pg-n8n-tf-server \
  --admin-password "$NEW_PG_PASSWORD"

# 4. Recréer le Secret Kubernetes via Terraform
cd terraform
terraform apply -replace=kubernetes_secret.n8n_secrets

# 5. Redémarrer les pods
kubectl delete pod -n n8n --all
```

### Monitoring et Logs

```bash
# Logs en temps réel
kubectl logs -n n8n -l app=n8n-main -f --tail=100

# Logs workers
kubectl logs -n n8n -l app=n8n-workers -f --tail=100

# Événements récents
kubectl get events -n n8n --sort-by='.lastTimestamp' | tail -20

# Métriques des pods
kubectl top pods -n n8n
kubectl top nodes
```

### Nettoyage Complet

```bash
# 1. Supprimer le namespace Kubernetes
kubectl delete namespace n8n

# 2. Détruire l'infrastructure Terraform
cd terraform
terraform destroy

# 3. (Optionnel) Supprimer le Resource Group complet
az group delete --name RG-N8N-AKS --yes --no-wait
```

---

## 📊 Ressources Terraform Créées

### Infrastructure Azure (22 ressources)

- `azurerm_virtual_network` - VNet 10.0.0.0/16
- `azurerm_subnet` x 3 - Subnets AKS, DB, ALB
- `azurerm_kubernetes_cluster` - Cluster AKS
- `azurerm_container_registry` - Registry Docker privé
- `azurerm_key_vault` - Gestion des secrets
- `azurerm_postgresql_flexible_server` - Base de données
- `azurerm_postgresql_flexible_server_database` - Database n8n_db
- `azurerm_postgresql_flexible_server_configuration` - Config SSL
- `azurerm_redis_cache` - Cache Redis
- `azurerm_application_load_balancer` - ALB Azure
- `azurerm_application_load_balancer_frontend` - Frontend ALB
- `azurerm_private_dns_zone` - DNS privé PostgreSQL
- ... et autres ressources réseau/IAM

### Kubernetes (3 ressources)

- `kubernetes_namespace` - Namespace n8n
- `kubernetes_config_map` - Configuration dynamique (DB_HOST, REDIS_HOST auto)
- `kubernetes_secret` - Secrets (passwords depuis Key Vault)

**Total : ~25 ressources gérées par Terraform**

---

## 🔐 Sécurité

### Best Practices Appliquées

✅ **Secrets** : Gérés dans Azure Key Vault, jamais en clair  
✅ **Network** : Subnets isolés, Private Endpoints  
✅ **PostgreSQL** : Accès réseau privé uniquement, SSL optionnel via variable  
✅ **Redis** : SSL/TLS activé par défaut  
✅ **AKS** : RBAC activé, identité managée, pas de basic auth  
✅ **ACR** : Authentification via identité AKS (pas d'admin account)  
✅ **N8N** : Cookie sécurisé désactivé en dev (activer en prod avec HTTPS)  

### Variables Sensibles

Ne **jamais** commiter dans Git :
- `terraform/terraform.tfvars` - Contient les passwords
- `terraform/terraform.tfstate` - Contient l'état complet
- `terraform/.terraform/` - Providers et modules
- Tout fichier avec des credentials

Le `.gitignore` est configuré pour les exclure automatiquement.

### Audit de Sécurité

Un script Checkov est disponible pour scanner la sécurité :

```bash
./scan_checkov.sh
```

Les rapports sont générés dans `reports_checkov/`.

---

## 📚 Références

- [Documentation N8N](https://docs.n8n.io/)
- [Azure AKS Documentation](https://learn.microsoft.com/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [PostgreSQL Flexible Server](https://learn.microsoft.com/azure/postgresql/flexible-server/)
- [Azure Redis Cache](https://learn.microsoft.com/azure/azure-cache-for-redis/)

---

## 📄 Licence

Ce projet est à usage éducatif dans le cadre du TP-6 Ynov.

---

## 🤝 Support

Pour toute question ou problème :
1. Consultez la section [Troubleshooting](#-troubleshooting)
2. Vérifiez les logs : `kubectl logs -n n8n <pod-name>`
3. Créez une issue sur le dépôt GitHub
