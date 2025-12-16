# 🎯 GUIDE DE DÉMARRAGE - À FAIRE MAINTENANT

## ✅ PRÉREQUIS À VÉRIFIER

### 1. Ressources Azure Déjà Créées (OBLIGATOIRE)

Ces ressources **DOIVENT EXISTER** avant de démarrer :

```bash
# Vérifier que le Resource Group existe
az group show --name RG-N8N-AKS

# Vérifier que le Storage Account backend existe
az storage account show --name stoynovgroup --resource-group RG-N8N-AKS
```

**Si elles n'existent PAS**, crée-les d'abord :

```bash
# Créer le Resource Group
az group create --name RG-N8N-AKS --location francecentral

# Créer le Storage Account pour le backend Terraform
az storage account create \
  --name stoynovgroup \
  --resource-group RG-N8N-AKS \
  --location francecentral \
  --sku Standard_LRS

# Créer le container pour le state
az storage container create \
  --name tfstate \
  --account-name stoynovgroup
```

### 2. Outils Installés

```bash
# Vérifier Azure CLI
az --version

# Vérifier Terraform
terraform version

# Vérifier kubectl
kubectl version --client

# Se connecter à Azure
az login
az account set --subscription "cd3fa1ba-5253-4f92-8571-9b1fde759c19"
```

---

## 🚀 PLAN D'ACTION - ÉTAPE PAR ÉTAPE

### OPTION A : Déploiement LOCAL (Test Rapide)

C'est pour tester rapidement sans GitHub Actions.

#### Étape 1 : Configurer Terraform

```bash
cd /home/gyme/INFRA-CLOUD-TP/TP-6/terraform

# Créer le fichier de variables depuis l'exemple
cp terraform.tfvars.example terraform.tfvars

# Éditer avec tes valeurs
nano terraform.tfvars
```

**Contenu de `terraform.tfvars` :**
```hcl
location            = "francecentral"
resource_group_name = "RG-N8N-AKS"
acr_name_prefix     = "acrn8ntf"
pg_admin_password   = "VOTRE_MOT_DE_PASSE_PG"
```

#### Étape 2 : Initialiser et Valider Terraform

```bash
# Initialiser Terraform (télécharge les providers)
terraform init

# Formater le code
terraform fmt

# Valider la syntaxe
terraform validate

# Voir le plan d'exécution
terraform plan
```

**✅ Vérifier que `terraform plan` affiche bien :**
- Toutes les ressources à créer
- ConfigMap et Secret Kubernetes inclus
- Aucune erreur

#### Étape 3 : Déployer l'Infrastructure

```bash
# Déployer (prend 15-20 minutes)
terraform apply

# Taper 'yes' quand demandé
```

**✅ Attendu :**
- PostgreSQL créé
- Redis créé
- AKS créé
- ACR créé
- Key Vault créé avec le password
- **ConfigMap K8s créé avec hosts dynamiques**
- **Secret K8s créé avec passwords**

#### Étape 4 : Configurer kubectl

```bash
# Récupérer les credentials AKS
az aks get-credentials \
  --resource-group RG-N8N-AKS \
  --name aks-n8n-cluster \
  --overwrite-existing

# Vérifier la connexion
kubectl get nodes
```

#### Étape 5 : Vérifier les Ressources K8s Créées par Terraform

```bash
# Vérifier le namespace
kubectl get namespace n8n

# Vérifier le ConfigMap (IMPORTANT - créé par Terraform)
kubectl get configmap n8n-config-vars -n n8n

# Voir le contenu du ConfigMap
kubectl get configmap n8n-config-vars -n n8n -o yaml

# Vérifier le Secret (IMPORTANT - créé par Terraform)
kubectl get secret n8n-sensitive-secrets -n n8n

# Vérifier l'imagePullSecret pour ACR
kubectl get secret acr-secret -n n8n
```

**✅ CRITIQUE : Si ces 3 ressources n'existent PAS, il y a un problème !**

#### Étape 6 : Préparer l'Image N8N

```bash
# Récupérer l'URL de l'ACR
ACR_LOGIN=$(cd terraform && terraform output -raw acr_login_server)
echo "ACR: $ACR_LOGIN"

# Login à l'ACR
az acr login --name $(echo $ACR_LOGIN | cut -d'.' -f1)

# Pull l'image officielle N8N
docker pull n8nio/n8n:latest

# Tag pour l'ACR
docker tag n8nio/n8n:latest $ACR_LOGIN/n8n:1.0.0

# Push vers l'ACR
docker push $ACR_LOGIN/n8n:1.0.0
```

#### Étape 7 : Mettre à Jour les Manifestes K8s

```bash
cd /home/gyme/INFRA-CLOUD-TP/TP-6/k8s

# Remplacer le placeholder de l'image
ACR_LOGIN=$(cd ../terraform && terraform output -raw acr_login_server)
sed -i "s|REPLACE_IMAGE_WITH_ACR_PATH:TAG|$ACR_LOGIN/n8n:1.0.0|g" n8n-deployments.yaml

# Vérifier
grep "image:" n8n-deployments.yaml
```

#### Étape 8 : Déployer les Pods N8N

```bash
# ⚠️ NE PAS appliquer n8n-configmap.yaml et n8n-secret.yaml
# Ils sont DEPRECATED et gérés par Terraform maintenant !

# Appliquer uniquement Services et Deployments
kubectl apply -f n8n-services.yaml
kubectl apply -f n8n-deployments.yaml

# Attendre que les pods soient prêts
kubectl wait --for=condition=ready pod -l app=n8n-main -n n8n --timeout=300s
```

#### Étape 9 : Vérifier le Déploiement

```bash
# Voir tous les pods
kubectl get pods -n n8n

# Voir les services
kubectl get svc -n n8n

# Voir les logs
kubectl logs -n n8n -l app=n8n-main --tail=50
```

**✅ Attendu :**
- Pods `n8n-main-0` et `n8n-main-1` en état `Running`
- Pods `n8n-workers-*` en état `Running`
- Service `n8n-service` avec une EXTERNAL-IP (peut prendre 5-10 min)

#### Étape 10 : Obtenir l'URL d'Accès

```bash
# Attendre que l'IP externe soit assignée
kubectl get svc n8n-service -n n8n --watch

# Récupérer l'IP
EXTERNAL_IP=$(kubectl get svc n8n-service -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "N8N accessible sur: http://$EXTERNAL_IP"

# Ouvrir dans le navigateur
xdg-open http://$EXTERNAL_IP  # Linux
```

---

### OPTION B : Déploiement via GITHUB ACTIONS (CI/CD)

#### Étape 1 : Configurer les Secrets GitHub

```bash
cd /home/gyme/INFRA-CLOUD-TP/TP-6

# Exécuter le script de configuration
./.github/setup-github-actions.sh
```

**Ce script va :**
1. Créer le Service Principal Azure
2. Générer le JSON `azure-credentials.json`
3. Configurer les permissions Key Vault

#### Étape 2 : Ajouter les Secrets dans GitHub

```
1. Aller sur ton repo GitHub : https://github.com/YnovOps-InfraGroup/INFRACLOUD-TP6
2. Settings → Secrets and variables → Actions
3. New repository secret
```

**Créer ces 2 secrets :**

| Nom | Valeur |
|-----|--------|
| `AZURE_CREDENTIALS` | Copier le contenu de `azure-credentials.json` |
| `PG_ADMIN_PASSWORD` | `VOTRE_MOT_DE_PASSE_PG` |

#### Étape 3 : Commit et Push

```bash
cd /home/gyme/INFRA-CLOUD-TP/TP-6

# Ajouter tous les nouveaux fichiers
git add .

# Commit
git commit -m "feat: add dynamic configuration and GitHub Actions pipeline"

# Push vers GitHub
git push origin main
```

#### Étape 4 : Surveiller le Pipeline

```
1. Aller sur GitHub → Actions
2. Voir le workflow "Deploy Infrastructure"
3. Suivre l'exécution en temps réel
```

**✅ Le pipeline va automatiquement :**
- Déployer l'infrastructure Terraform
- Créer ConfigMap et Secret K8s
- Déployer les pods N8N

---

## 🎯 COMMANDE RAPIDE TOUT-EN-UN (Local)

Si tu veux tout faire d'un coup localement :

```bash
cd /home/gyme/INFRA-CLOUD-TP/TP-6

# Utiliser le script helper
chmod +x deploy-helper.sh
./deploy-helper.sh full-deploy
```

Ce script fait TOUT automatiquement !

---

## 🔍 CHECKLIST DE VÉRIFICATION

### Après Terraform Apply

- [ ] `terraform apply` terminé sans erreur
- [ ] Output `postgresql_fqdn` disponible
- [ ] Output `redis_hostname` disponible
- [ ] Output `acr_login_server` disponible
- [ ] ConfigMap `n8n-config-vars` existe dans namespace `n8n`
- [ ] Secret `n8n-sensitive-secrets` existe dans namespace `n8n`

### Après Déploiement K8s

- [ ] Namespace `n8n` existe
- [ ] Pods `n8n-main-*` en état `Running`
- [ ] Pods `n8n-workers-*` en état `Running`
- [ ] Service `n8n-service` a une EXTERNAL-IP
- [ ] `curl http://<EXTERNAL-IP>` retourne une réponse

### Validation Finale

```bash
# Tester la connexion PostgreSQL
kubectl exec -n n8n deployment/n8n-main -- env | grep DB_HOST

# Tester la connexion Redis
kubectl exec -n n8n deployment/n8n-main -- env | grep REDIS

# Voir les logs N8N
kubectl logs -n n8n -l app=n8n-main --tail=50

# Accéder à l'interface
# Ouvrir http://<EXTERNAL-IP> dans le navigateur
```

---

## ⚠️ PROBLÈMES COURANTS

### Problème 1 : Backend Terraform ne fonctionne pas

**Erreur :**
```
Error: Failed to get existing workspaces: storage account does not exist
```

**Solution :**
```bash
# Créer le Storage Account et le container
az storage account create \
  --name stoynovgroup \
  --resource-group RG-N8N-AKS \
  --location francecentral \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name stoynovgroup
```

### Problème 2 : ConfigMap et Secret K8s pas créés

**Vérifier :**
```bash
cd terraform
terraform state list | grep kubernetes
```

**Si absent :**
```bash
# Vérifier que le provider Kubernetes est bien configuré
terraform providers

# Re-créer
terraform apply -target=kubernetes_config_map.n8n_config
terraform apply -target=kubernetes_secret.n8n_secrets
```

### Problème 3 : Pods en CrashLoopBackOff

**Vérifier les logs :**
```bash
kubectl logs -n n8n -l app=n8n-main --previous

# Causes communes :
# - Image non trouvée → Vérifier ACR et imagePullSecret
# - Connexion DB échoue → Vérifier ConfigMap DB_HOST
# - Connexion Redis échoue → Vérifier ConfigMap REDIS_HOST
```

---

## 📞 SI TU ES BLOQUÉ

### Commandes de Debug Rapides

```bash
# Voir l'état Terraform
cd terraform
terraform state list

# Voir les outputs
terraform output

# Voir les ressources K8s
kubectl get all -n n8n

# Voir les events K8s
kubectl get events -n n8n --sort-by='.lastTimestamp'

# Utiliser le script helper
cd ..
./deploy-helper.sh status
./deploy-helper.sh logs
```

---

## 🎯 RÉCAPITULATIF : QUOI FAIRE MAINTENANT

### CHOIX 1 : Test Local (Recommandé pour débuter)

```bash
# 1. Vérifier les prérequis Azure
az group show --name RG-N8N-AKS

# 2. Configurer Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Ajouter le password

# 3. Déployer
terraform init
terraform apply

# 4. Configurer kubectl
az aks get-credentials --resource-group RG-N8N-AKS --name aks-n8n-cluster

# 5. Vérifier ConfigMap/Secret créés par Terraform
kubectl get configmap n8n-config-vars -n n8n
kubectl get secret n8n-sensitive-secrets -n n8n

# 6. Déployer les pods
cd ../k8s
kubectl apply -f n8n-services.yaml
kubectl apply -f n8n-deployments.yaml

# 7. Obtenir l'URL
kubectl get svc n8n-service -n n8n
```

### CHOIX 2 : Via GitHub Actions (Production)

```bash
# 1. Configurer GitHub
./.github/setup-github-actions.sh

# 2. Ajouter secrets dans GitHub UI

# 3. Push
git push origin main

# 4. Surveiller Actions → Deploy Infrastructure
```

---

**Commence par CHOIX 1 (Local) pour tester que tout fonctionne !**
