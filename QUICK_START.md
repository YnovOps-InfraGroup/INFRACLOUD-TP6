# 🚀 DÉMARRAGE RAPIDE - TP-6

## ✅ Ce que tu as déjà

- ✅ Service Principal : `github-sp-terraform-n8n`
- ✅ AKS Cluster : `aks-n8n-cluster`
- ✅ Key Vault : `akv-n8n-tf-secrets`
- ✅ Storage Account : `stoynovgroup`

## 🎯 4 Étapes à Suivre MAINTENANT

### 1️⃣ Permissions Key Vault (1 commande)

```bash
az keyvault set-policy \
  --name akv-n8n-tf-secrets \
  --spn df5bd568-b12d-4f9a-bb6d-79901ca7d3c7 \
  --secret-permissions get list set delete
```

**Résultat attendu :** `✓ Access policy added`

---

### 2️⃣ GitHub Secrets (via interface web)

**Aller sur :** `https://github.com/YnovOps-InfraGroup/INFRACLOUD-TP6/settings/secrets/actions`

**Créer 2 secrets :**

#### Secret 1 : `AZURE_CREDENTIALS`
Copier-coller exactement ce JSON :
```json
{
  "clientId": "df5bd568-b12d-4f9a-bb6d-79901ca7d3c7",
  "clientSecret": "VOTRE_CLIENT_SECRET_ICI",
  "subscriptionId": "cd3fa1ba-5253-4f92-8571-9b1fde759c19",
  "tenantId": "3c4107f0-14b9-4991-84e8-0f60a9add6d8",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

#### Secret 2 : `PG_ADMIN_PASSWORD`
Valeur :
```
VOTRE_MOT_DE_PASSE_PG
```

---

### 3️⃣ Push vers GitHub (3 commandes)

```bash
cd /home/gyme/INFRA-CLOUD-TP/TP-6

git add .
git commit -m "feat: add dynamic configuration and GitHub Actions"
git push origin main
```

**Le pipeline démarre automatiquement !**

---

### 4️⃣ Vérifier le Déploiement

#### Sur GitHub
1. Aller sur : `Actions` tab
2. Cliquer sur le workflow "Deploy Infrastructure"
3. Suivre l'exécution en temps réel

#### Localement (après le pipeline)
```bash
# Récupérer les credentials AKS
az aks get-credentials \
  --resource-group RG-N8N-AKS \
  --name aks-n8n-cluster \
  --overwrite-existing

# Vérifier que le ConfigMap est créé avec les bonnes valeurs
kubectl get configmap n8n-config-vars -n n8n -o yaml

# Vérifier le Secret
kubectl get secret n8n-sensitive-secrets -n n8n

# Voir les pods
kubectl get pods -n n8n

# Récupérer l'URL d'accès
kubectl get svc n8n-service -n n8n
```

---

## 📊 Checklist Rapide

- [ ] Étape 1 : Permissions Key Vault ✓
- [ ] Étape 2 : Secret `AZURE_CREDENTIALS` dans GitHub ✓
- [ ] Étape 3 : Secret `PG_ADMIN_PASSWORD` dans GitHub ✓
- [ ] Étape 4 : `git push origin main` ✓
- [ ] Étape 5 : Pipeline GitHub Actions réussi ✓
- [ ] Étape 6 : ConfigMap créé avec hosts dynamiques ✓
- [ ] Étape 7 : Secret K8s créé ✓
- [ ] Étape 8 : Pods N8N running ✓

---

## 🐛 Si Problème

### Pipeline échoue avec "Access Denied"
```bash
# Redonner les permissions
az keyvault set-policy \
  --name akv-n8n-tf-secrets \
  --spn df5bd568-b12d-4f9a-bb6d-79901ca7d3c7 \
  --secret-permissions get list set delete
```

### ConfigMap pas créé
```bash
# Vérifier que Terraform a bien tourné
# Regarder les logs GitHub Actions

# Manuellement si besoin
cd terraform
terraform apply -target=kubernetes_config_map.n8n_config
```

### Pods ne démarrent pas
```bash
# Voir les logs
kubectl logs -n n8n -l app=n8n-main --tail=50

# Voir les events
kubectl get events -n n8n --sort-by='.lastTimestamp'
```

---

## ⏱️ Temps Estimé

- Étape 1 : **1 minute**
- Étape 2 : **2 minutes** (création secrets GitHub)
- Étape 3 : **30 secondes** (git push)
- Étape 4 : **5-10 minutes** (pipeline exécution)

**Total : ~15 minutes**

---

## 🎯 Résultat Final

Après ces étapes, tu auras :
- ✅ Infrastructure déployée via Terraform
- ✅ ConfigMap K8s avec hosts dynamiques
- ✅ Secret K8s avec password sécurisé
- ✅ Pods N8N en cours d'exécution
- ✅ Application accessible via LoadBalancer

**Commande pour obtenir l'URL :**
```bash
kubectl get svc n8n-service -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

**C'est parti ! Commence par l'étape 1** 🚀
