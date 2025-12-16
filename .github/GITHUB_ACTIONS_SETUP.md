# 🔐 Configuration GitHub Actions - TP-6

## 📋 Secrets à Configurer dans GitHub

Pour que le pipeline fonctionne, tu dois configurer ces secrets dans ton dépôt GitHub.

### 1. AZURE_CREDENTIALS

**Créer un Service Principal Azure:**

```bash
# Se connecter à Azure
az login

# Créer le Service Principal
az ad sp create-for-rbac \
  --name "github-actions-tp6" \
  --role contributor \
  --scopes /subscriptions/cd3fa1ba-5253-4f92-8571-9b1fde759c19/resourceGroups/RG-N8N-AKS \
  --sdk-auth
```

**Exemple de sortie (à copier dans le secret GitHub):**
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "cd3fa1ba-5253-4f92-8571-9b1fde759c19",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### 2. PG_ADMIN_PASSWORD

**Ton mot de passe actuel:**
```
VOTRE_MOT_DE_PASSE_PG
```

Ce mot de passe sera :
1. ✅ Passé comme variable Terraform dans le pipeline
2. ✅ Stocké dans Azure Key Vault par Terraform
3. ✅ Injecté dans le Secret Kubernetes automatiquement

## 🔧 Configuration dans GitHub

### Étape 1: Aller dans les Settings du Repo

```
Ton Repo → Settings → Secrets and variables → Actions
```

### Étape 2: Ajouter les Secrets

**Cliquer sur "New repository secret":**

| Nom du Secret | Valeur |
|---------------|--------|
| `AZURE_CREDENTIALS` | Le JSON complet du Service Principal |
| `PG_ADMIN_PASSWORD` | `VOTRE_MOT_DE_PASSE_PG` |

### Étape 3: Donner les Permissions au Service Principal

Le Service Principal doit avoir accès au Key Vault pour lire/écrire les secrets :

```bash
# Récupérer l'Object ID du Service Principal
SP_OBJECT_ID=$(az ad sp list --display-name "github-actions-tp6" --query [0].id -o tsv)

# Donner les permissions sur le Key Vault
az keyvault set-policy \
  --name akv-n8n-tf-secrets \
  --object-id $SP_OBJECT_ID \
  --secret-permissions get list set delete
```

## 🔄 Flux de Déploiement avec GitHub Actions

### Diagramme du Flux

```
┌─────────────────────────────────────────────────────────────┐
│                    GITHUB ACTIONS                            │
│                                                              │
│  1. Checkout code                                           │
│  2. Login Azure avec AZURE_CREDENTIALS                      │
│  3. Setup Terraform                                          │
│     ↓                                                        │
│  4. Terraform Init                                          │
│  5. Terraform Plan -var="pg_admin_password=$SECRET"         │
│     ↓                                                        │
│  6. Terraform Apply (crée infra + ConfigMap/Secret K8s)     │
│     │                                                        │
│     ├──▶ Crée PostgreSQL                                   │
│     ├──▶ Crée Redis                                        │
│     ├──▶ Crée AKS                                          │
│     ├──▶ Stocke password dans Key Vault                   │
│     ├──▶ Crée ConfigMap K8s avec hosts dynamiques         │
│     └──▶ Crée Secret K8s avec password depuis Key Vault  │
│     ↓                                                        │
│  7. Get AKS credentials                                     │
│  8. kubectl apply Services et Deployments                   │
│     ↓                                                        │
│  9. Pods démarrent avec config automatique                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## ✅ Avantages de cette Approche

| Aspect | Ancien (manuel) | Nouveau (automatique) |
|--------|----------------|----------------------|
| **Password** | Codé dans le pipeline | Secret GitHub sécurisé |
| **Key Vault** | Mise à jour manuelle | Auto via Terraform |
| **ConfigMap** | Édition manuelle | Créé par Terraform |
| **Synchronisation** | Risque de désync | Toujours synchro |
| **Rotation password** | Modifier partout | Changer 1 secret GitHub |

## 🔐 Sécurité

### Où est Stocké le Mot de Passe ?

1. **GitHub Secret** : `PG_ADMIN_PASSWORD` (chiffré par GitHub)
2. **Azure Key Vault** : `pg-admin-password` (chiffré par Azure)
3. **Kubernetes Secret** : `n8n-sensitive-secrets` (chiffré dans etcd)

**Le mot de passe n'apparaît JAMAIS en clair dans :**
- ❌ Le code source
- ❌ Les logs Terraform
- ❌ Les logs GitHub Actions
- ❌ Les manifestes Kubernetes

### Rotation du Mot de Passe

Pour changer le mot de passe PostgreSQL :

```bash
# Option 1 : Via GitHub Secret
# 1. Aller dans Settings → Secrets → PG_ADMIN_PASSWORD
# 2. Modifier la valeur
# 3. Re-run le workflow

# Option 2 : Via Azure Key Vault directement
az keyvault secret set \
  --vault-name akv-n8n-tf-secrets \
  --name pg-admin-password \
  --value "NouveauMotDePasse123!"

# Puis re-run Terraform
terraform apply
```

## 🧪 Tester le Pipeline

### Test 1 : Push sur Main

```bash
git add .
git commit -m "test: pipeline deployment"
git push origin main
```

Le pipeline se déclenche automatiquement et :
1. Déploie l'infrastructure
2. Crée ConfigMap et Secret avec les bonnes valeurs
3. Déploie les pods N8N

### Test 2 : Workflow Manuel

Dans GitHub :
```
Actions → Deploy Infrastructure → Run workflow
```

Permet de redéployer sans faire de push.

## 📊 Variables d'Environnement Disponibles

Dans le workflow, ces variables sont automatiquement disponibles :

```yaml
env:
  # Depuis terraform.tfvars
  TF_VAR_location: "francecentral"
  TF_VAR_resource_group_name: "RG-N8N-AKS"
  TF_VAR_acr_name_prefix: "acrn8ntf"
  
  # Depuis GitHub Secrets
  TF_VAR_pg_admin_password: ${{ secrets.PG_ADMIN_PASSWORD }}
```

## 🔍 Vérifier que Tout Fonctionne

### Dans GitHub Actions Logs

Chercher ces lignes dans les logs :

```
✓ Terraform Apply Complete
✓ ConfigMap n8n-config-vars created
✓ Secret n8n-sensitive-secrets created
✓ Deployment n8n-main created
✓ Pods ready
```

### Dans Azure

```bash
# Vérifier le Key Vault
az keyvault secret show \
  --vault-name akv-n8n-tf-secrets \
  --name pg-admin-password

# Vérifier PostgreSQL
az postgres flexible-server show \
  --resource-group RG-N8N-AKS \
  --name pg-n8n-tf-server
```

### Dans Kubernetes

```bash
# Configurer kubectl
az aks get-credentials --resource-group RG-N8N-AKS --name aks-n8n-cluster

# Vérifier le ConfigMap
kubectl get configmap n8n-config-vars -n n8n -o yaml

# Vérifier le Secret (valeurs chiffrées)
kubectl get secret n8n-sensitive-secrets -n n8n

# Vérifier que les pods ont les bonnes valeurs
kubectl exec -n n8n deployment/n8n-main -- env | grep DB_
```

## 🐛 Troubleshooting

### Erreur : "Error: Insufficient permissions"

**Solution :**
Le Service Principal n'a pas les permissions nécessaires.

```bash
# Donner le rôle Contributor sur le Resource Group
az role assignment create \
  --assignee <SERVICE_PRINCIPAL_APP_ID> \
  --role Contributor \
  --scope /subscriptions/cd3fa1ba-5253-4f92-8571-9b1fde759c19/resourceGroups/RG-N8N-AKS
```

### Erreur : "Error: Key Vault access denied"

**Solution :**
Le Service Principal n'a pas accès au Key Vault.

```bash
az keyvault set-policy \
  --name akv-n8n-tf-secrets \
  --spn <SERVICE_PRINCIPAL_APP_ID> \
  --secret-permissions get list set delete
```

### Erreur : "ConfigMap not created"

**Solution :**
Vérifier que le provider Kubernetes est bien configuré dans Terraform.

```bash
# Vérifier les providers
terraform providers

# Re-init si nécessaire
terraform init -upgrade
```

## 📚 Ressources

- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Azure Service Principal](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [Terraform in CI/CD](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)

## 📝 Checklist Configuration

- [ ] Service Principal créé et JSON sauvegardé
- [ ] Secret `AZURE_CREDENTIALS` ajouté dans GitHub
- [ ] Secret `PG_ADMIN_PASSWORD` ajouté dans GitHub
- [ ] Permissions Key Vault données au Service Principal
- [ ] Workflow `.github/workflows/deploy.yml` commité
- [ ] Premier push pour tester le pipeline
- [ ] Vérification que ConfigMap est créé avec bonnes valeurs
- [ ] Vérification que Secret est créé avec password correct
- [ ] Pods N8N démarrent correctement

---

**Important :** Avec cette configuration, le mot de passe `VOTRE_MOT_DE_PASSE_PG` est **totalement compatible** et sera utilisé automatiquement dans tout le pipeline !
