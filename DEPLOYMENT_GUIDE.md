# 🚀 Guide de Déploiement - TP-6 N8N sur AKS

## 📋 Prérequis

### Outils nécessaires
- Azure CLI (`az`) version 2.50+
- Terraform version 1.9.0+
- kubectl version 1.28+
- Docker (pour build d'images)

### Ressources Azure existantes requises
- ✅ Resource Group: `RG-N8N-AKS`
- ✅ Storage Account pour le backend Terraform: `stoynovgroup`
- ✅ Container dans le Storage Account: `tfstate`

## 🏗️ Architecture Déployée

```
┌─────────────────────────────────────────────────────────┐
│                    Azure Subscription                    │
│  ┌───────────────────────────────────────────────────┐  │
│  │         Resource Group: RG-N8N-AKS                │  │
│  │                                                    │  │
│  │  ┌──────────────────────────────────────────┐    │  │
│  │  │   Virtual Network (10.0.0.0/16)          │    │  │
│  │  │                                           │    │  │
│  │  │  ┌──────────────┐  ┌──────────────┐     │    │  │
│  │  │  │ Snet-AKS     │  │ Snet-DB      │     │    │  │
│  │  │  │ 10.0.1.0/24  │  │ 10.0.2.0/24  │     │    │  │
│  │  │  │              │  │              │     │    │  │
│  │  │  │  AKS Cluster │  │  PostgreSQL  │     │    │  │
│  │  │  │  - n8n-main  │  │  Flexible    │     │    │  │
│  │  │  │  - workers   │  │  Server      │     │    │  │
│  │  │  └──────────────┘  └──────────────┘     │    │  │
│  │  │                                           │    │  │
│  │  │  ┌──────────────┐  ┌──────────────┐     │    │  │
│  │  │  │ Snet-ALB     │  │ Redis Cache  │     │    │  │
│  │  │  │ 10.0.4.0/24  │  │              │     │    │  │
│  │  │  │              │  └──────────────┘     │    │  │
│  │  │  │ App Gateway  │                        │    │  │
│  │  │  │ Containers   │                        │    │  │
│  │  │  └──────────────┘                        │    │  │
│  │  └──────────────────────────────────────────┘    │  │
│  │                                                    │  │
│  │  ┌────────────┐  ┌────────────┐                  │  │
│  │  │ ACR        │  │ Key Vault  │                  │  │
│  │  │ (Registry) │  │ (Secrets)  │                  │  │
│  │  └────────────┘  └────────────┘                  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## 🔧 Déploiement Étape par Étape

### 1️⃣ Préparation

```bash
# Cloner le dépôt
git clone <votre-repo>
cd TP-6

# Se connecter à Azure
az login
az account set --subscription "<VOTRE_SUBSCRIPTION_ID>"

# Vérifier que le Resource Group existe
az group show --name RG-N8N-AKS
```

### 2️⃣ Configuration Terraform

```bash
cd terraform

# Copier et configurer les variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Éditer avec vos valeurs

# Initialiser Terraform
terraform init

# Vérifier la configuration
terraform fmt
terraform validate

# Voir le plan d'exécution
terraform plan
```

### 3️⃣ Déploiement de l'Infrastructure

```bash
# Déployer l'infrastructure
terraform apply

# Sauvegarder les outputs
terraform output -json > ../outputs.json

# Récupérer les credentials AKS
az aks get-credentials \
  --resource-group RG-N8N-AKS \
  --name aks-n8n-cluster \
  --overwrite-existing

# Vérifier la connexion
kubectl get nodes
kubectl get namespaces
```

### 4️⃣ Build et Push de l'Image N8N

```bash
cd ..

# Récupérer l'URL de l'ACR
ACR_LOGIN=$(terraform output -raw acr_login_server)
echo "ACR: $ACR_LOGIN"

# Se connecter à l'ACR
az acr login --name $(echo $ACR_LOGIN | cut -d'.' -f1)

# Builder l'image N8N (si vous avez un Dockerfile custom)
# Sinon, utiliser l'image officielle
docker pull n8nio/n8n:latest
docker tag n8nio/n8n:latest $ACR_LOGIN/n8n:1.0.0

# Pusher l'image
docker push $ACR_LOGIN/n8n:1.0.0
```

### 5️⃣ Mise à Jour des Manifestes Kubernetes

```bash
cd k8s

# Remplacer le placeholder de l'image
ACR_LOGIN=$(cd ../terraform && terraform output -raw acr_login_server)
sed -i "s|REPLACE_IMAGE_WITH_ACR_PATH:TAG|$ACR_LOGIN/n8n:1.0.0|g" n8n-deployments.yaml

# Vérifier la modification
grep "image:" n8n-deployments.yaml
```

### 6️⃣ Déploiement sur Kubernetes

```bash
# Appliquer les manifestes dans l'ordre
kubectl apply -f n8n-configmap.yaml
kubectl apply -f n8n-secret.yaml
kubectl apply -f n8n-services.yaml
kubectl apply -f n8n-deployments.yaml

# Vérifier le déploiement
kubectl get all -n n8n

# Attendre que les pods soient prêts
kubectl wait --for=condition=ready pod -l app=n8n-main -n n8n --timeout=300s
```

### 7️⃣ Obtenir l'URL d'Accès

```bash
# Récupérer l'IP publique du LoadBalancer
kubectl get svc n8n-service -n n8n --watch

# Une fois l'EXTERNAL-IP disponible
EXTERNAL_IP=$(kubectl get svc n8n-service -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "N8N accessible sur: http://$EXTERNAL_IP"
```

## 🧪 Tests et Validation

### Vérifier les Pods
```bash
# Status des pods
kubectl get pods -n n8n
kubectl describe pod -n n8n <nom-du-pod>

# Logs des pods
kubectl logs -n n8n -l app=n8n-main --tail=50
kubectl logs -n n8n -l app=n8n-workers --tail=50
```

### Tester la Base de Données
```bash
# Récupérer les infos PostgreSQL
PG_HOST=$(cd terraform && terraform output -raw postgresql_fqdn)
PG_DB=$(cd terraform && terraform output -raw postgresql_database_name)
PG_USER=$(cd terraform && terraform output -json postgresql_admin_username | jq -r)

# Tester la connexion (depuis un pod ou une VM dans le VNet)
kubectl run -n n8n psql-test --rm -it --image=postgres:14 -- \
  psql "host=$PG_HOST port=5432 dbname=$PG_DB user=$PG_USER sslmode=require"
```

### Tester Redis
```bash
# Récupérer les infos Redis
REDIS_HOST=$(cd terraform && terraform output -raw redis_hostname)
REDIS_PORT=$(cd terraform && terraform output -raw redis_port)

# Tester depuis un pod
kubectl run -n n8n redis-test --rm -it --image=redis:alpine -- \
  redis-cli -h $REDIS_HOST -p $REDIS_PORT --tls
```

### Accéder à N8N
```bash
# Via l'IP publique
curl http://$EXTERNAL_IP

# Ou ouvrir dans le navigateur
xdg-open http://$EXTERNAL_IP  # Linux
open http://$EXTERNAL_IP      # macOS
```

## 🔒 Sécurité

### Secrets
- ✅ Mot de passe PostgreSQL stocké dans Key Vault
- ✅ Credentials ACR via imagePullSecrets
- ⚠️ Penser à activer le chiffrement des secrets K8s au repos

### Network
- ✅ PostgreSQL accessible uniquement depuis le VNet (private endpoint)
- ✅ Sous-réseaux segmentés par fonction
- ⚠️ Configurer des Network Policies K8s pour isolation des pods

### Recommandations
```bash
# Scanner les vulnérabilités avec Checkov
cd terraform
checkov -d . --framework terraform

cd ../k8s
checkov -d . --framework kubernetes

# Scanner l'image Docker
docker scan $ACR_LOGIN/n8n:1.0.0
```

## 🐛 Troubleshooting

### Les pods ne démarrent pas
```bash
# Vérifier les events
kubectl get events -n n8n --sort-by='.lastTimestamp'

# Vérifier les logs
kubectl logs -n n8n <nom-du-pod> --previous

# Vérifier l'imagePullSecret
kubectl get secret acr-secret -n n8n -o yaml
```

### Problème de connexion PostgreSQL
```bash
# Vérifier la résolution DNS
kubectl run -n n8n dns-test --rm -it --image=busybox -- nslookup <PG_HOST>

# Vérifier les NSG
az network nsg rule list --resource-group RG-N8N-AKS --nsg-name <NSG_NAME>
```

### Problème de Load Balancer
```bash
# Vérifier le service
kubectl describe svc n8n-service -n n8n

# Vérifier l'ALB
az network application-gateway for-containers show \
  --name AGC-N8N-AKS \
  --resource-group RG-N8N-AKS
```

## 🗑️ Nettoyage

```bash
# Supprimer les ressources Kubernetes
kubectl delete -f k8s/ -n n8n

# Supprimer l'infrastructure Terraform
cd terraform
terraform destroy

# Confirmer en tapant 'yes'
```

## 📊 Monitoring

### Metrics Kubernetes
```bash
# CPU et mémoire
kubectl top nodes
kubectl top pods -n n8n
```

### Azure Monitor
```bash
# Activer Container Insights (optionnel)
az aks enable-addons \
  --resource-group RG-N8N-AKS \
  --name aks-n8n-cluster \
  --addons monitoring
```

## 📚 Ressources Utiles

- [Documentation N8N](https://docs.n8n.io/)
- [Azure AKS Best Practices](https://learn.microsoft.com/azure/aks/)
- [Application Gateway for Containers](https://learn.microsoft.com/azure/application-gateway/for-containers/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

**Auteur:** YnovOps InfraGroup  
**Dernière mise à jour:** Décembre 2025
