# 🚀 Plan d'Action - Déploiement TP-6

## ✅ Étape 0 : Vérifications (FAIT)

- ✅ Configuration Terraform ajustée pour utiliser vos ressources existantes
- ✅ Pipeline GitHub Actions mis à jour
- ✅ Variables dynamiques configurées
- ✅ Validation Terraform réussie

## 📋 Ce qui a été modifié

### Fichiers Terraform
1. **[variables.tf](terraform/variables.tf)** 
   - Ajout `pg_admin_user` et `n8n_encryption_key`
   - Correction `location` → `francecentral`

2. **[providers.tf](terraform/providers.tf)**
   - Ajout provider `random`

3. **[databases.tf](terraform/databases.tf)**
   - `administrator_login` maintenant variable

4. **[kubernetes-resources.tf](terraform/kubernetes-resources.tf)** (NOUVEAU)
   - ConfigMap avec valeurs dynamiques (DB_HOST, REDIS_HOST)
   - Secret avec credentials automatiques

### Pipeline GitHub Actions
5. **[.github/workflows/terraform-ci-cd.yml](.github/workflows/terraform-ci-cd.yml)**
   - Ajout variable `n8n_encryption_key` au plan
   - Simplification du déploiement K8s
   - Suppression des `sed` manuels

---

## 🎯 Étape 1 : Permissions Key Vault

Le Service Principal doit avoir les permissions sur Key Vault :

```bash
az keyvault set-policy \
  --name akv-n8n-tf-secrets \
  --spn df5bd568-b12d-4f9a-bb6d-79901ca7d3c7 \
  --secret-permissions get list set delete
```

**Vérification :**
```bash
az keyvault show --name akv-n8n-tf-secrets --query properties.accessPolicies
```

---

## 🎯 Étape 2 : Test Local (OPTIONNEL)

Si vous voulez tester avant de pusher :

```bash
cd terraform

# Init
terraform init -backend-config="storage_account_name=stoynovgroup"

# Plan avec vos secrets
terraform plan \
  -var="pg_admin_password=VOTRE_MOT_DE_PASSE_PG" \
  -var="n8n_encryption_key=VOTRE_CLE_N8N"
```

**Que va faire Terraform ?**
- ✅ Aucune modification sur les ressources Azure existantes
- ➕ Création de `kubernetes_config_map.n8n_config`
- ➕ Création de `kubernetes_secret.n8n_secrets`
- ➕ Création de `random_password.n8n_encryption_key` (si clé non fournie)

---

## 🎯 Étape 3 : Commit & Push

```bash
# Depuis /home/gyme/INFRA-CLOUD-TP/TP-6
git add .
git commit -m "feat: configuration K8s dynamique via Terraform

- Ajout kubernetes-resources.tf pour ConfigMap/Secret
- Variables pg_admin_user et n8n_encryption_key
- Pipeline simplifié (plus de sed manuel)
- ConfigMap avec DB_HOST/REDIS_HOST dynamiques"

git push origin main
```

---

## 🎯 Étape 4 : Monitoring Pipeline

### 4.1 Accéder au pipeline
- URL : https://github.com/YnovOps-InfraGroup/INFRACLOUD-TP6/actions

### 4.2 Jobs à surveiller

#### Job 1 : `Validate Terraform`
```
✅ Terraform Init
✅ Terraform fmt
✅ Terraform Validate
```

#### Job 2 : `Plan`
```
✅ Login to Azure
✅ Terraform Init
✅ Terraform Plan → Création de tfplan
✅ Upload Plan Artifact
```

**À vérifier :** Le plan doit montrer :
- `+` kubernetes_config_map.n8n_config
- `+` kubernetes_secret.n8n_secrets
- `~` rien ne doit changer sur PostgreSQL/Redis/AKS

#### Job 3 : `Deploy Infra & App`
```
✅ Terraform Apply → Crée ConfigMap + Secret
✅ Terraform Output → Récupère ACR server
✅ Docker Build & Push → Image vers ACR
✅ Deploy Kubernetes Resources → Deployments + Services
```

---

## 🎯 Étape 5 : Validation Post-Déploiement

### 5.1 Récupérer les credentials AKS
```bash
az aks get-credentials \
  --resource-group RG-N8N-AKS \
  --name aks-n8n-cluster \
  --overwrite-existing
```

### 5.2 Vérifier ConfigMap
```bash
kubectl get configmap n8n-config-vars -n n8n -o yaml
```

**Attendu :**
```yaml
data:
  DB_HOST: pg-n8n-tf-server.postgres.database.azure.com
  QUEUE_BULL_REDIS_HOST: redis-n8n-tf-cache.redis.cache.windows.net
  # ... autres variables
```

### 5.3 Vérifier Secret
```bash
kubectl get secret n8n-sensitive-secrets -n n8n -o jsonpath='{.data}' | jq
```

**Attendu :** Toutes les clés encodées en base64 :
- `DB_USER`
- `DB_PASSWORD`
- `QUEUE_BULL_REDIS_PASSWORD`
- `N8N_ENCRYPTION_KEY`

### 5.4 Vérifier les Pods
```bash
kubectl get pods -n n8n
```

**Attendu :**
```
NAME                          READY   STATUS    RESTARTS   AGE
n8n-main-0                    1/1     Running   0          2m
n8n-main-1                    1/1     Running   0          2m
n8n-worker-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
n8n-worker-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
n8n-worker-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
```

### 5.5 Obtenir l'URL d'accès
```bash
# Si LoadBalancer
kubectl get svc n8n-service -n n8n

# Récupérer l'IP
export N8N_IP=$(kubectl get svc n8n-service -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "N8N disponible sur : http://$N8N_IP:5678"
```

### 5.6 Tester la connexion
```bash
curl http://$N8N_IP:5678/healthz
```

**Attendu :** `{"status":"ok"}`

---

## 🔍 Debug : Si ça ne fonctionne pas

### Pods en CrashLoopBackOff
```bash
# Logs du pod principal
kubectl logs -n n8n n8n-main-0 --tail=100

# Logs des workers
kubectl logs -n n8n -l app=n8n-worker --tail=50
```

**Erreurs fréquentes :**
- ❌ `ECONNREFUSED` → Vérifier DB_HOST et REDIS_HOST dans ConfigMap
- ❌ `Authentication failed` → Vérifier DB_PASSWORD dans Secret
- ❌ `SSL required` → PostgreSQL nécessite SSL

### Vérifier les variables d'environnement
```bash
kubectl exec -n n8n n8n-main-0 -- env | grep -E "DB_|QUEUE_|N8N_"
```

### Tester la connexion PostgreSQL depuis un pod
```bash
kubectl run -it --rm psql-test --image=postgres:14 --restart=Never -n n8n -- \
  psql "postgresql://n8nadmin:VOTRE_MOT_DE_PASSE_PG@pg-n8n-tf-server.postgres.database.azure.com:5432/n8n_db?sslmode=require"
```

### Tester la connexion Redis
```bash
kubectl run -it --rm redis-test --image=redis:alpine --restart=Never -n n8n -- \
  redis-cli -h redis-n8n-tf-cache.redis.cache.windows.net -p 6380 --tls PING
```

---

## 📊 Comparaison Avant/Après

| Aspect | Avant | Après |
|--------|-------|-------|
| **ConfigMap** | YAML statique avec valeurs hardcodées | Terraform dynamique depuis ressources Azure |
| **Secret** | sed + base64 manuel dans pipeline | Terraform avec auto-encoding |
| **DB_HOST** | Écrit en dur dans YAML | Récupéré depuis `azurerm_postgresql_flexible_server.pg.fqdn` |
| **REDIS_HOST** | Écrit en dur dans YAML | Récupéré depuis `azurerm_redis_cache.redis.hostname` |
| **Passwords** | Manipulation manuelle | Key Vault → Terraform → K8s Secret |
| **Maintenance** | Changer host = éditer YAML | Changer host = Terraform redéploie auto |
| **Traçabilité** | Fichiers YAML séparés | Terraform State unifié |

---

## 🎉 Résumé de la Nouvelle Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      GITHUB SECRETS                          │
│  • AZURE_CREDENTIALS                                         │
│  • TF_POSTGRES_PASSWORD                                      │
│  • N8N_ENCRYPTION_KEY                                        │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                  GITHUB ACTIONS PIPELINE                     │
│  1. terraform init                                           │
│  2. terraform plan (avec variables)                          │
│  3. terraform apply                                          │
│     ├─ Crée kubernetes_config_map.n8n_config                │
│     └─ Crée kubernetes_secret.n8n_secrets                   │
│  4. docker build & push                                      │
│  5. kubectl apply deployments/services                       │
└──────────────────┬──────────────────────────────────────────┘
                   │
      ┌────────────┴────────────┐
      ▼                         ▼
┌──────────────┐        ┌──────────────┐
│ AZURE INFRA  │        │ KUBERNETES   │
├──────────────┤        ├──────────────┤
│ • PostgreSQL │───────>│ • ConfigMap  │
│   └─ FQDN    │  Auto  │   └─ DB_HOST │
│              │        │              │
│ • Redis      │───────>│ • Secret     │
│   └─ Host    │  Auto  │   └─ Creds   │
│              │        │              │
│ • Key Vault  │───────>│ • Pods       │
│   └─ Pass    │  Auto  │   └─ N8N     │
└──────────────┘        └──────────────┘
```

---

## ✅ Checklist Finale

Avant de continuer, vérifiez :

- [ ] Permissions Key Vault accordées au Service Principal
- [ ] GitHub Secrets en place : `AZURE_CREDENTIALS`, `TF_POSTGRES_PASSWORD`, `N8N_ENCRYPTION_KEY`
- [ ] Fichiers Terraform validés localement
- [ ] Git commit + push effectué
- [ ] Pipeline GitHub Actions en cours d'exécution

---

**Prêt à déployer ?** Exécutez l'Étape 1 puis l'Étape 3 ! 🚀

---

**Documentation Complète :** [CONFIGURATION_ACTUELLE.md](CONFIGURATION_ACTUELLE.md)
