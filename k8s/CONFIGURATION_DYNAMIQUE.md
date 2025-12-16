# 📚 Gestion des Variables et Configuration Dynamique

## 🎯 Problématique

Avant, les hosts étaient codés en dur dans [n8n-configmap.yaml](n8n-configmap.yaml) :
```yaml
DB_HOST: "pg-n8n-tf-server.postgres.database.azure.com"
QUEUE_BULL_REDIS_HOST: "redis-n8n-tf-cache.redis.cache.windows.net"
```

**Problèmes :**
- ❌ Risque d'erreur de saisie
- ❌ Valeurs non synchronisées avec Terraform
- ❌ Modification manuelle nécessaire après chaque changement
- ❌ Pas de gestion des environnements (dev/prod)

## ✅ Solution Implémentée

### Approche : ConfigMap/Secret gérés par Terraform

Les fichiers de configuration Kubernetes sont maintenant créés **directement par Terraform** dans [kubernetes-resources.tf](../terraform/kubernetes-resources.tf).

### Architecture du Flux de Données

```
┌─────────────────────────────────────────────────────────────┐
│                    TERRAFORM                                 │
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │ PostgreSQL   │────────▶│  .fqdn       │                 │
│  │ Resource     │         │  .name       │                 │
│  └──────────────┘         └──────────────┘                 │
│                                  │                           │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │ Redis        │────────▶│  .hostname   │                 │
│  │ Resource     │         │  .ssl_port   │                 │
│  └──────────────┘         └──────────────┘                 │
│                                  │                           │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │ Key Vault    │────────▶│  .value      │                 │
│  │ Secret       │         └──────────────┘                 │
│  └──────────────┘                │                          │
│                                   ▼                          │
│                    ┌──────────────────────────┐            │
│                    │ kubernetes_config_map    │            │
│                    │ kubernetes_secret        │            │
│                    └──────────────────────────┘            │
│                                   │                          │
└───────────────────────────────────│──────────────────────────┘
                                    ▼
                    ┌──────────────────────────┐
                    │   KUBERNETES CLUSTER     │
                    │                          │
                    │  ConfigMap: n8n-config   │
                    │  Secret: n8n-secrets     │
                    └──────────────────────────┘
                                    │
                                    ▼
                    ┌──────────────────────────┐
                    │      N8N PODS            │
                    │  - Variables d'env       │
                    │  - Connexions DB/Redis   │
                    └──────────────────────────┘
```

## 🔧 Comment ça fonctionne

### 1. **Références Terraform**

Dans `kubernetes-resources.tf`, on utilise les références aux ressources :

```hcl
resource "kubernetes_config_map" "n8n_config" {
  data = {
    # ✅ Valeur dynamique depuis la ressource PostgreSQL
    DB_HOST = azurerm_postgresql_flexible_server.pg.fqdn
    
    # ✅ Valeur dynamique depuis la ressource Redis
    QUEUE_BULL_REDIS_HOST = azurerm_redis_cache.redis.hostname
    
    # ✅ Valeur dynamique depuis la base de données
    DB_DATABASE = azurerm_postgresql_flexible_server_database.n8n_db.name
  }
}
```

### 2. **Dépendances Terraform**

Terraform s'assure que les ressources sont créées dans le bon ordre :

```hcl
depends_on = [
  kubernetes_namespace.n8n,
  azurerm_postgresql_flexible_server.pg,
  azurerm_redis_cache.redis
]
```

**Ordre d'exécution :**
1. Création du namespace K8s
2. Création PostgreSQL + Redis
3. Création ConfigMap avec les bonnes valeurs
4. Déploiement des pods

### 3. **Gestion des Secrets**

Les valeurs sensibles sont dans `kubernetes_secret` :

```hcl
resource "kubernetes_secret" "n8n_secrets" {
  data = {
    # ✅ Mot de passe récupéré depuis Key Vault
    DB_PASSWORD = base64encode(azurerm_key_vault_secret.pg_password.value)
    
    # ✅ Clé Redis récupérée automatiquement
    QUEUE_BULL_REDIS_PASSWORD = base64encode(azurerm_redis_cache.redis.primary_access_key)
    
    # ✅ Clé de chiffrement générée aléatoirement
    N8N_ENCRYPTION_KEY = base64encode(random_password.n8n_encryption_key.result)
  }
}
```

## 📝 Modifications Nécessaires

### ⚠️ Fichiers YAML à NE PLUS UTILISER

Les fichiers suivants sont maintenant **gérés par Terraform** :
- ~~`k8s/n8n-configmap.yaml`~~ → Remplacé par `terraform/kubernetes-resources.tf`
- ~~`k8s/n8n-secret.yaml`~~ → Remplacé par `terraform/kubernetes-resources.tf`

### ✅ Fichiers YAML toujours utilisés

Ces fichiers restent en YAML car ils ne contiennent pas de valeurs dynamiques :
- ✅ `k8s/n8n-deployments.yaml` - Définition des pods
- ✅ `k8s/n8n-services.yaml` - Définition des services

## 🚀 Déploiement

### Ancienne méthode (MANUELLE)
```bash
# ❌ Il fallait éditer manuellement le ConfigMap
vim k8s/n8n-configmap.yaml
# Modifier les hosts...

# Puis appliquer
kubectl apply -f k8s/n8n-configmap.yaml
kubectl apply -f k8s/n8n-secret.yaml
```

### Nouvelle méthode (AUTOMATIQUE)
```bash
# ✅ Terraform gère tout automatiquement
cd terraform
terraform apply

# Les ConfigMaps et Secrets sont créés avec les bonnes valeurs !
```

## 🔍 Vérification

### Voir les valeurs dans Kubernetes

```bash
# Voir le ConfigMap généré
kubectl get configmap n8n-config-vars -n n8n -o yaml

# Voir les clés du Secret (pas les valeurs, elles sont chiffrées)
kubectl get secret n8n-sensitive-secrets -n n8n -o jsonpath='{.data}' | jq

# Décoder une valeur du Secret (pour debug)
kubectl get secret n8n-sensitive-secrets -n n8n -o jsonpath='{.data.DB_HOST}' | base64 -d
```

### Vérifier dans un Pod

```bash
# Se connecter à un pod N8N
kubectl exec -it -n n8n deployment/n8n-main -- sh

# Voir les variables d'environnement
env | grep DB_
env | grep REDIS
env | grep N8N_
```

## 🎨 Avantages de cette Approche

| Avant (YAML statique) | Après (Terraform dynamique) |
|----------------------|----------------------------|
| ❌ Valeurs codées en dur | ✅ Valeurs dynamiques |
| ❌ Erreurs de saisie possibles | ✅ Références vérifiées |
| ❌ Désynchronisation | ✅ Toujours synchronisé |
| ❌ Modification manuelle | ✅ Automatique |
| ❌ Pas de validation | ✅ Terraform validate |
| ❌ Difficile multi-env | ✅ Variables Terraform |

## 🔐 Sécurité

### Secrets Management

```hcl
# ✅ Les secrets ne sont JAMAIS en clair dans le code
data = {
  DB_PASSWORD = base64encode(azurerm_key_vault_secret.pg_password.value)
}
```

**Flux sécurisé :**
1. Mot de passe stocké dans **Azure Key Vault**
2. Terraform lit depuis Key Vault (via API sécurisée)
3. Terraform crée le Secret K8s (chiffré dans etcd)
4. Pod monte le secret comme variable d'env

### Rotation des Secrets

Pour changer un mot de passe :
```bash
# 1. Mettre à jour dans Key Vault
az keyvault secret set --vault-name akv-n8n-tf-secrets \
  --name pg-admin-password \
  --value "NouveauMotDePasse123!"

# 2. Re-appliquer Terraform
terraform apply

# 3. Redémarrer les pods
kubectl rollout restart statefulset/n8n-main -n n8n
kubectl rollout restart deployment/n8n-workers -n n8n
```

## 🌍 Gestion Multi-Environnements

### Structure recommandée

```
terraform/
├── environments/
│   ├── dev/
│   │   └── terraform.tfvars
│   ├── staging/
│   │   └── terraform.tfvars
│   └── prod/
│       └── terraform.tfvars
├── kubernetes-resources.tf  # Même code pour tous les envs
└── ...
```

### Exemple dev vs prod

**dev.tfvars :**
```hcl
resource_group_name = "RG-N8N-AKS-DEV"
acr_name_prefix = "acrn8ndev"
```

**prod.tfvars :**
```hcl
resource_group_name = "RG-N8N-AKS-PROD"
acr_name_prefix = "acrn8nprod"
```

Les hosts seront **automatiquement différents** pour chaque environnement !

## 🐛 Troubleshooting

### Le ConfigMap n'a pas les bonnes valeurs

```bash
# 1. Vérifier les outputs Terraform
cd terraform
terraform output postgresql_fqdn
terraform output redis_hostname

# 2. Détruire et recréer le ConfigMap
terraform destroy -target=kubernetes_config_map.n8n_config
terraform apply -target=kubernetes_config_map.n8n_config

# 3. Redémarrer les pods
kubectl rollout restart statefulset/n8n-main -n n8n
```

### Les pods ne démarrent pas

```bash
# Vérifier que le ConfigMap existe
kubectl get configmap -n n8n

# Vérifier les événements
kubectl get events -n n8n --sort-by='.lastTimestamp'

# Vérifier les logs
kubectl logs -n n8n -l app=n8n-main --tail=50
```

## 📚 Ressources

- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [N8N Environment Variables](https://docs.n8n.io/hosting/configuration/environment-variables/)

---

**Note importante:** Après migration vers cette approche, **ne plus modifier** `n8n-configmap.yaml` et `n8n-secret.yaml` manuellement. Toutes les modifications doivent passer par Terraform.
