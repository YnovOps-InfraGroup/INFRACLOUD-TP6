# ⚡ Actions Immédiates - TP-6

## ✅ Configuration Validée

```bash
./check-config.sh
```

**Résultat :** Toutes les ressources Azure existent et Terraform est valide ✅

---

## 🎯 Action 1 : Permissions Key Vault (REQUIS)

```bash
az keyvault set-policy \
  --name akv-n8n-tf-secrets \
  --spn df5bd568-b12d-4f9a-bb6d-79901ca7d3c7 \
  --secret-permissions get list set delete
```

**Pourquoi ?** Le Service Principal doit pouvoir lire le mot de passe PostgreSQL dans Key Vault.

---

## 🎯 Action 2 : Git Commit & Push

```bash
git add .
git commit -m "feat: configuration K8s dynamique via Terraform

- Ajout kubernetes-resources.tf pour ConfigMap/Secret dynamiques
- Variables pg_admin_user et n8n_encryption_key
- Pipeline simplifié sans sed manuel
- DB_HOST et REDIS_HOST récupérés automatiquement"

git push origin main
```

---

## 🎯 Action 3 : Surveiller le Pipeline

**URL :** https://github.com/YnovOps-InfraGroup/INFRACLOUD-TP6/actions

**Ce qui va se passer :**

```
✅ Job 1: Validate Terraform (2 min)
   ├─ terraform fmt
   ├─ terraform validate
   └─ SUCCESS

✅ Job 2: Plan (2 min)
   ├─ terraform init
   ├─ terraform plan
   │  └─ + kubernetes_config_map.n8n_config
   │  └─ + kubernetes_secret.n8n_secrets
   └─ Upload tfplan

✅ Job 3: Deploy Infra & App (3-5 min)
   ├─ terraform apply
   │  └─ Crée ConfigMap avec DB_HOST dynamique
   │  └─ Crée Secret avec credentials
   ├─ docker build & push
   └─ kubectl apply deployments/services
```

**Durée totale :** ~7-10 minutes

---

## 🎯 Action 4 : Vérification Post-Déploiement

```bash
# 1. Connecter kubectl
az aks get-credentials --resource-group RG-N8N-AKS --name aks-n8n-cluster --overwrite-existing

# 2. Vérifier ConfigMap
kubectl get configmap n8n-config-vars -n n8n -o yaml | grep DB_HOST
# Attendu: DB_HOST: pg-n8n-tf-server.postgres.database.azure.com

# 3. Vérifier Secret
kubectl get secret n8n-sensitive-secrets -n n8n
# Attendu: NAME                      TYPE     DATA   AGE
#          n8n-sensitive-secrets     Opaque   4      1m

# 4. Vérifier Pods
kubectl get pods -n n8n
# Attendu: 
# n8n-main-0        1/1   Running   0   2m
# n8n-main-1        1/1   Running   0   2m
# n8n-worker-xxx    1/1   Running   0   2m

# 5. Obtenir l'IP d'accès
kubectl get svc n8n-service -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

## 📚 Documentation Complète

| Document | Description |
|----------|-------------|
| [PLAN_ACTION.md](PLAN_ACTION.md) | **Guide complet en 5 étapes** |
| [CONFIGURATION_ACTUELLE.md](CONFIGURATION_ACTUELLE.md) | Configuration détaillée |
| [RESUME_MODIFICATIONS.md](RESUME_MODIFICATIONS.md) | Liste des changements |
| [check-config.sh](check-config.sh) | Script de validation |

---

## 🆘 En Cas de Problème

### Pipeline échoue sur Terraform Apply
```bash
cd terraform
terraform init -backend-config="storage_account_name=stoynovgroup"
terraform plan -var="pg_admin_password=VOTRE_MOT_DE_PASSE_PG" -var="n8n_encryption_key=VOTRE_CLE"
```

### Pods en CrashLoopBackOff
```bash
kubectl logs -n n8n n8n-main-0 --tail=100
kubectl describe pod -n n8n n8n-main-0
```

### Secret pas créé
```bash
# Vérifier dans Terraform
cd terraform
terraform state show kubernetes_secret.n8n_secrets
```

---

## 🎉 Changements Principaux

| Avant | Après |
|-------|-------|
| ❌ DB_HOST hardcodé | ✅ DB_HOST depuis `azurerm_postgresql_flexible_server.pg.fqdn` |
| ❌ Secrets avec sed + base64 | ✅ Secrets auto-encodés par Terraform |
| ❌ ConfigMap YAML statique | ✅ ConfigMap dynamique via Terraform |
| ❌ Maintenance manuelle | ✅ Tout automatique |

---

**Commencez maintenant :**

```bash
./check-config.sh  # Déjà fait ✅
# Puis exécutez Action 1 et Action 2 ci-dessus
```

🚀 **Prêt à déployer !**
