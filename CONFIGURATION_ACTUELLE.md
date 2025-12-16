# Configuration Actuelle - TP-6

## ✅ Configuration Validée

### GitHub Secrets (déjà en place)
- ✅ `AZURE_CREDENTIALS` - Service Principal JSON complet
- ✅ `TF_POSTGRES_PASSWORD` - Mot de passe PostgreSQL : `VOTRE_MOT_DE_PASSE_PG`
- ✅ `N8N_ENCRYPTION_KEY` - Clé de chiffrement N8N

### Infrastructure Azure (déjà déployée)
- ✅ Resource Group : `RG-N8N-AKS`
- ✅ AKS Cluster : `aks-n8n-cluster`
- ✅ Key Vault : `akv-n8n-tf-secrets`
- ✅ PostgreSQL : `pg-n8n-tf-server` (admin: `n8nadmin`)
- ✅ Redis : `redis-n8n-tf-cache`
- ✅ ACR : `acrn8ntf*****`
- ✅ Application Load Balancer
- ✅ Virtual Network + Subnets

### Terraform State
- ✅ Backend Azure Storage : `stoynovgroup/tfstate`
- ✅ 22 ressources déjà déployées

## 🔄 Modifications Apportées

### 1. Providers Terraform
**Fichier :** [terraform/providers.tf](terraform/providers.tf)
- ✅ Ajout du provider `kubernetes` pour gérer ConfigMap/Secret
- ✅ Ajout du provider `random` pour génération de clés
- ✅ Connection automatique à l'AKS via kube_config

### 2. Variables
**Fichier :** [terraform/variables.tf](terraform/variables.tf)
- ✅ Ajout de `pg_admin_user` (défaut: `n8nadmin`)
- ✅ Ajout de `n8n_encryption_key` (depuis GitHub Secret)
- ✅ Correction `location` : `francecentral` (au lieu de `france-central`)

### 3. Ressources Kubernetes
**Fichier :** [terraform/kubernetes-resources.tf](terraform/kubernetes-resources.tf)
- ✅ **ConfigMap** `n8n-config-vars` créé par Terraform avec :
  - `DB_HOST` : FQDN PostgreSQL automatique
  - `QUEUE_BULL_REDIS_HOST` : Hostname Redis automatique
  - Toutes les variables d'environnement N8N
- ✅ **Secret** `n8n-sensitive-secrets` créé par Terraform avec :
  - `DB_USER` / `DB_PASSWORD` depuis PostgreSQL
  - `QUEUE_BULL_REDIS_PASSWORD` depuis Redis
  - `N8N_ENCRYPTION_KEY` depuis GitHub Secret

### 4. Pipeline GitHub Actions
**Fichier :** [.github/workflows/terraform-ci-cd.yml](.github/workflows/terraform-ci-cd.yml)
- ✅ Variables Terraform ajustées pour inclure `n8n_encryption_key`
- ✅ Déploiement K8s simplifié (plus de sed/base64)
- ✅ ConfigMap et Secret maintenant gérés par Terraform
- ✅ Déploiement uniquement des Deployments et Services

### 5. Base de données
**Fichier :** [terraform/databases.tf](terraform/databases.tf)
- ✅ `administrator_login` maintenant variable (`var.pg_admin_user`)

## 🎯 Prochaines Étapes

### 1. Vérifier les permissions Key Vault
Le Service Principal doit avoir accès au Key Vault :
```bash
az keyvault set-policy \
  --name akv-n8n-tf-secrets \
  --spn df5bd568-b12d-4f9a-bb6d-79901ca7d3c7 \
  --secret-permissions get list set delete
```

### 2. Initialiser Terraform localement (optionnel)
```bash
cd terraform
terraform init -backend-config="storage_account_name=stoynovgroup"
terraform plan -var="pg_admin_password=VOTRE_MOT_DE_PASSE_PG" -var="n8n_encryption_key=VOTRE_CLE"
```

### 3. Push vers GitHub
Le pipeline `terraform-ci-cd.yml` se déclenchera automatiquement :
```bash
git add .
git commit -m "feat: configuration dynamique K8s via Terraform"
git push origin main
```

### 4. Monitoring du déploiement
Le pipeline va :
1. ✅ Valider Terraform (`terraform fmt`, `validate`)
2. ✅ Planifier les changements (`terraform plan`)
3. ✅ Appliquer l'infrastructure (`terraform apply`)
4. ✅ Créer ConfigMap et Secret Kubernetes via Terraform
5. ✅ Build et push l'image Docker vers ACR
6. ✅ Déployer les Deployments et Services K8s

## 📊 Architecture de Configuration

```
GitHub Secrets
    ├─ AZURE_CREDENTIALS ──────────────┐
    ├─ TF_POSTGRES_PASSWORD ───────────┼──> Terraform Variables
    └─ N8N_ENCRYPTION_KEY ─────────────┘
                                        │
                                        ▼
                           Terraform Apply (CI/CD)
                                        │
                    ┌───────────────────┴───────────────────┐
                    ▼                                       ▼
            Azure Resources                    Kubernetes Resources
            ├─ PostgreSQL (FQDN)               ├─ ConfigMap (valeurs dynamiques)
            ├─ Redis (hostname)        ───────>│   └─ DB_HOST = pg.fqdn
            └─ Key Vault (password)            └─ Secret (credentials)
                                                    └─ DB_PASSWORD depuis KV
```

## 🔐 Sécurité

### Avant (manuel)
- ❌ Valeurs hardcodées dans YAML
- ❌ Encodage base64 manuel avec sed
- ❌ Risque de désynchronisation

### Maintenant (automatique)
- ✅ Valeurs dynamiques depuis Terraform
- ✅ Encodage automatique
- ✅ Single source of truth
- ✅ Mots de passe dans Key Vault
- ✅ GitHub Secrets pour CI/CD

## 📝 Fichiers Obsolètes

Ces fichiers ne sont plus utilisés (ConfigMap/Secret gérés par Terraform) :
- ~~`k8s/n8n-configmap.yaml`~~ → Remplacé par `kubernetes_config_map.n8n_config`
- ~~`k8s/n8n-secret.yaml`~~ → Remplacé par `kubernetes_secret.n8n_secrets`

**Note :** Ces fichiers ont été marqués comme DEPRECATED avec des avertissements.

## 🆘 Dépannage

### Si le pipeline échoue sur Terraform Apply
```bash
# Vérifier l'état actuel
cd terraform
terraform init -backend-config="storage_account_name=stoynovgroup"
terraform state list

# Importer les nouvelles ressources si nécessaire
terraform import kubernetes_config_map.n8n_config n8n/n8n-config-vars
terraform import kubernetes_secret.n8n_secrets n8n/n8n-sensitive-secrets
```

### Vérifier la configuration Kubernetes
```bash
# Récupérer kubeconfig
az aks get-credentials --resource-group RG-N8N-AKS --name aks-n8n-cluster

# Vérifier ConfigMap
kubectl get configmap n8n-config-vars -n n8n -o yaml

# Vérifier Secret
kubectl get secret n8n-sensitive-secrets -n n8n -o jsonpath='{.data}' | jq
```

### Obtenir l'URL d'accès N8N
```bash
kubectl get svc n8n-service -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## ✨ Avantages de la Nouvelle Configuration

1. **DRY (Don't Repeat Yourself)** : Une seule source pour les valeurs
2. **Sécurité renforcée** : Mots de passe jamais en clair dans le code
3. **Maintenance simplifiée** : Changement de host → 1 seul endroit
4. **Traçabilité** : Terraform State track toutes les ressources
5. **CI/CD simplifié** : Plus de sed/base64 manuel
6. **Idempotence** : Terraform gère les mises à jour intelligemment

---

**Auteur :** GitHub Copilot  
**Date :** 16 décembre 2025  
**Version :** 2.0 (Configuration dynamique)
