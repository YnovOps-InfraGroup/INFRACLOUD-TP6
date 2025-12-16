# ✅ CHECKLIST DE VALIDATION - TP-6

## 📋 Vérifications Avant Déploiement

### 1. Prérequis Azure

- [ ] Compte Azure actif
- [ ] Subscription ID : `cd3fa1ba-5253-4f92-8571-9b1fde759c19`
- [ ] Resource Group créé : `RG-N8N-AKS`
- [ ] Storage Account backend : `stoynovgroup`
- [ ] Container blob : `tfstate`
- [ ] Droits suffisants (Contributor ou Owner)

### 2. Outils Installés

- [ ] Azure CLI (`az --version`)
- [ ] Terraform >= 1.9.0 (`terraform version`)
- [ ] kubectl >= 1.28 (`kubectl version --client`)
- [ ] Docker (optionnel pour build)
- [ ] jq (recommandé pour parsing JSON)
- [ ] git

### 3. Configuration Terraform

- [ ] Fichier `terraform.tfvars` créé depuis `.example`
- [ ] Variable `pg_admin_password` définie (12+ caractères)
- [ ] Backend configuré dans `backend.tf`
- [ ] Provider `azurerm`, `kubernetes`, `random` déclarés

### 4. Fichiers Terraform Créés/Modifiés

- [x] `terraform/kubernetes-resources.tf` ✨ NOUVEAU
- [x] `terraform/outputs.tf` 🔄 AMÉLIORÉ
- [x] `terraform/terraform.tfvars.example` ✨ NOUVEAU
- [x] `terraform/network.tf` (ALB frontend ajouté)
- [x] Tous les autres fichiers .tf existants

### 5. Fichiers Kubernetes

- [x] `k8s/n8n-services.yaml` 🔄 LoadBalancer
- [x] `k8s/n8n-deployments.yaml` (namespace: n8n)
- [x] `k8s/n8n-configmap.yaml` ⚠️ DEPRECATED
- [x] `k8s/n8n-secret.yaml` ⚠️ DEPRECATED

### 6. Documentation

- [x] `DEPLOYMENT_GUIDE.md` ✨ Guide complet
- [x] `k8s/CONFIGURATION_DYNAMIQUE.md` ✨ Config dynamique
- [x] `AMELIORATIONS.md` ✨ Résumé modifications
- [x] `deploy-helper.sh` ✨ Script automatique

## 🚀 Procédure de Déploiement

### Méthode 1 : Script Automatique (Recommandé)

```bash
# 1. Rendre le script exécutable
chmod +x deploy-helper.sh

# 2. Lancer le déploiement complet
./deploy-helper.sh full-deploy
```

### Méthode 2 : Manuel Étape par Étape

```bash
# 1. Se connecter à Azure
az login
az account set --subscription "cd3fa1ba-5253-4f92-8571-9b1fde759c19"

# 2. Configurer Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Éditer les valeurs

# 3. Initialiser et valider
terraform init
terraform fmt
terraform validate
terraform plan

# 4. Déployer l'infrastructure
terraform apply

# 5. Configurer kubectl
az aks get-credentials \
  --resource-group RG-N8N-AKS \
  --name aks-n8n-cluster \
  --overwrite-existing

# 6. Vérifier que les ressources K8s sont créées par Terraform
kubectl get configmap n8n-config-vars -n n8n
kubectl get secret n8n-sensitive-secrets -n n8n

# 7. Préparer l'image N8N
ACR_LOGIN=$(terraform output -raw acr_login_server)
az acr login --name $(echo $ACR_LOGIN | cut -d'.' -f1)
docker pull n8nio/n8n:latest
docker tag n8nio/n8n:latest $ACR_LOGIN/n8n:1.0.0
docker push $ACR_LOGIN/n8n:1.0.0

# 8. Mettre à jour le manifeste Deployment
cd ../k8s
sed -i "s|REPLACE_IMAGE_WITH_ACR_PATH:TAG|$ACR_LOGIN/n8n:1.0.0|g" n8n-deployments.yaml

# 9. Déployer sur Kubernetes (Services et Deployments uniquement)
kubectl apply -f n8n-services.yaml
kubectl apply -f n8n-deployments.yaml

# 10. Attendre les pods
kubectl wait --for=condition=ready pod -l app=n8n-main -n n8n --timeout=300s

# 11. Récupérer l'URL d'accès
kubectl get svc n8n-service -n n8n
```

## ✅ Tests de Validation

### 1. Infrastructure Terraform

```bash
cd terraform

# Vérifier les ressources créées
terraform state list

# Vérifier les outputs
terraform output

# Tester les valeurs critiques
terraform output postgresql_fqdn
terraform output redis_hostname
terraform output acr_login_server
```

### 2. Cluster AKS

```bash
# Vérifier les nodes
kubectl get nodes

# Vérifier le namespace
kubectl get namespace n8n

# Vérifier les ressources dans le namespace
kubectl get all -n n8n
```

### 3. ConfigMap et Secrets (gérés par Terraform)

```bash
# Vérifier le ConfigMap
kubectl get configmap n8n-config-vars -n n8n -o yaml

# Valider les valeurs
kubectl get configmap n8n-config-vars -n n8n -o jsonpath='{.data.DB_HOST}'
kubectl get configmap n8n-config-vars -n n8n -o jsonpath='{.data.QUEUE_BULL_REDIS_HOST}'

# Vérifier le Secret (pas les valeurs, elles sont chiffrées)
kubectl get secret n8n-sensitive-secrets -n n8n
```

### 4. Pods et Services

```bash
# Status des pods
kubectl get pods -n n8n -o wide

# Logs des pods
kubectl logs -n n8n -l app=n8n-main --tail=50
kubectl logs -n n8n -l app=n8n-workers --tail=50

# Services
kubectl get svc -n n8n

# Attendre l'IP externe du LoadBalancer
kubectl get svc n8n-service -n n8n --watch
```

### 5. Connectivité Base de Données

```bash
# Test PostgreSQL depuis un pod
PG_HOST=$(cd terraform && terraform output -raw postgresql_fqdn)
kubectl run -n n8n psql-test --rm -it --image=postgres:14 --restart=Never -- \
  psql "host=$PG_HOST port=5432 sslmode=require" -c "SELECT version();"
```

### 6. Connectivité Redis

```bash
# Test Redis depuis un pod
REDIS_HOST=$(cd terraform && terraform output -raw redis_hostname)
kubectl run -n n8n redis-test --rm -it --image=redis:alpine --restart=Never -- \
  redis-cli -h $REDIS_HOST -p 6380 --tls PING
```

### 7. Accès Application N8N

```bash
# Récupérer l'IP externe
EXTERNAL_IP=$(kubectl get svc n8n-service -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Tester l'accès HTTP
curl -I http://$EXTERNAL_IP

# Ouvrir dans le navigateur
echo "N8N accessible sur: http://$EXTERNAL_IP"
```

## 🔍 Points de Vérification Critiques

### ✅ Configuration Dynamique Fonctionnelle

Vérifier que les valeurs dans le ConfigMap correspondent aux ressources Terraform :

```bash
# Récupérer le FQDN PostgreSQL depuis Terraform
PG_FQDN_TF=$(cd terraform && terraform output -raw postgresql_fqdn)

# Récupérer le FQDN PostgreSQL depuis le ConfigMap K8s
PG_FQDN_K8S=$(kubectl get configmap n8n-config-vars -n n8n -o jsonpath='{.data.DB_HOST}')

# Comparer
echo "Terraform: $PG_FQDN_TF"
echo "K8s ConfigMap: $PG_FQDN_K8S"

# Doivent être identiques !
[ "$PG_FQDN_TF" = "$PG_FQDN_K8S" ] && echo "✅ MATCH" || echo "❌ MISMATCH"
```

### ✅ Secrets Correctement Injectés

```bash
# Vérifier qu'un pod peut lire les secrets
kubectl exec -n n8n deployment/n8n-main -- env | grep DB_
kubectl exec -n n8n deployment/n8n-main -- env | grep REDIS
```

### ✅ Networking Fonctionnel

```bash
# Test de connectivité interne
kubectl exec -n n8n deployment/n8n-main -- nslookup n8n-service
kubectl exec -n n8n deployment/n8n-main -- wget -O- http://n8n-service/healthz
```

## 🐛 Troubleshooting Commun

### Problème : ConfigMap non créé

**Symptôme:** `kubectl get configmap n8n-config-vars -n n8n` retourne "NotFound"

**Solution:**
```bash
# Vérifier que Terraform l'a créé
cd terraform
terraform state list | grep kubernetes_config_map

# Si absent, re-créer
terraform apply -target=kubernetes_config_map.n8n_config
```

### Problème : Pods en CrashLoopBackOff

**Symptôme:** Pods redémarrent continuellement

**Solution:**
```bash
# Vérifier les logs
kubectl logs -n n8n -l app=n8n-main --previous

# Causes communes:
# 1. Mauvaise connexion DB → Vérifier DB_HOST dans ConfigMap
# 2. Mauvais password → Vérifier Secret
# 3. Image non trouvée → Vérifier imagePullSecret
```

### Problème : LoadBalancer stuck en "Pending"

**Symptôme:** Service n8n-service n'obtient pas d'EXTERNAL-IP

**Solution:**
```bash
# Vérifier les events
kubectl describe svc n8n-service -n n8n

# Vérifier l'ALB
az network application-gateway for-containers show \
  --name AGC-N8N-AKS \
  --resource-group RG-N8N-AKS
```

### Problème : Variables d'environnement incorrectes dans les pods

**Symptôme:** Les pods n'ont pas les bonnes valeurs

**Solution:**
```bash
# 1. Vérifier le ConfigMap source
kubectl get configmap n8n-config-vars -n n8n -o yaml

# 2. Forcer la mise à jour
terraform apply -target=kubernetes_config_map.n8n_config

# 3. Redémarrer les pods
kubectl rollout restart statefulset/n8n-main -n n8n
kubectl rollout restart deployment/n8n-workers -n n8n
```

## 📊 Métriques de Succès

### Déploiement Réussi Si:

- [ ] `terraform apply` se termine sans erreur
- [ ] Tous les outputs Terraform sont disponibles
- [ ] ConfigMap `n8n-config-vars` existe dans namespace `n8n`
- [ ] Secret `n8n-sensitive-secrets` existe dans namespace `n8n`
- [ ] Pods `n8n-main-*` sont en état `Running` et `Ready 1/1`
- [ ] Pods `n8n-workers-*` sont en état `Running` et `Ready 1/1`
- [ ] Service `n8n-service` a une EXTERNAL-IP assignée
- [ ] `curl http://<EXTERNAL-IP>` retourne une réponse HTTP
- [ ] L'interface N8N est accessible dans le navigateur
- [ ] Les workers peuvent se connecter à Redis
- [ ] L'application peut se connecter à PostgreSQL

## 🎯 Checklist Finale

### Avant de Considérer le Projet Terminé

- [ ] Tous les tests de validation passent
- [ ] Documentation complète et à jour
- [ ] Rapport de sécurité Checkov généré et analysé
- [ ] Outputs Terraform sauvegardés
- [ ] Kubeconfig sauvegardé
- [ ] Credentials ACR documentés
- [ ] URL d'accès N8N documentée
- [ ] Procédure de backup en place (optionnel)
- [ ] Monitoring configuré (optionnel)
- [ ] CI/CD pipeline configuré (optionnel)

## 📚 Ressources de Référence

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Guide de déploiement complet
- [CONFIGURATION_DYNAMIQUE.md](k8s/CONFIGURATION_DYNAMIQUE.md) - Configuration dynamique
- [AMELIORATIONS.md](AMELIORATIONS.md) - Résumé des améliorations
- [terraform/outputs.tf](terraform/outputs.tf) - Liste complète des outputs
- [deploy-helper.sh](deploy-helper.sh) - Script d'aide au déploiement

## 💡 Commandes Rapides

```bash
# Status complet
./deploy-helper.sh status

# Voir les logs
./deploy-helper.sh logs

# Tester les connexions
./deploy-helper.sh test

# Obtenir l'URL
./deploy-helper.sh url

# Tout nettoyer
./deploy-helper.sh clean
```

---

**Date:** Décembre 2025  
**Version:** 2.0  
**Status:** ✅ Production Ready
