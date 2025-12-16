# Rapport de Sécurité et Conformité - TP-6

**Date de génération:** $(date '+%Y-%m-%d %H:%M:%S')

## Table des matières
1. [Résumé Exécutif](#résumé-exécutif)
2. [Statistiques Détaillées](#statistiques-détaillées)
3. [Échecs de Sécurité par Catégorie](#échecs-de-sécurité-par-catégorie)
4. [Recommandations Prioritaires](#recommandations-prioritaires)
5. [Détails Complets des Échecs](#détails-complets-des-échecs)

---

## Résumé Exécutif

### Vue d'ensemble
Ce rapport présente l'analyse de sécurité et de conformité du TP-6, incluant l'infrastructure Terraform et les manifestes Kubernetes.

### Statistiques par Framework

**kubernetes - _k8s:**
- ✅ Passés: 148
- ❌ Échoués: 32
- ⊘ Ignorés: 0

**kubernetes - _terraform:**
- ✅ Passés: 0
- ❌ Échoués: 0
- ⊘ Ignorés: 0

**secrets - _k8s:**
- ✅ Passés: 0
- ❌ Échoués: 0
- ⊘ Ignorés: 0

**secrets - _terraform:**
- ✅ Passés: 0
- ❌ Échoués: 0
- ⊘ Ignorés: 0

**terraform - _k8s:**
- ✅ Passés: 0
- ❌ Échoués: 0
- ⊘ Ignorés: 0

**terraform - _terraform:**
- ✅ Passés: 11
- ❌ Échoués: 33
- ⊘ Ignorés: 0


### Résultat Global
- **Total de contrôles:** 224
- **✅ Contrôles réussis:** 159
- **❌ Contrôles échoués:** 65
- **⊘ Contrôles ignorés:** 0
- **📊 Taux de conformité:** 71.0%

---

## Détails Complets des Échecs

### kubernetes - _k8s

**Nombre d'échecs:** 32

#### Ensure that the seccomp profile is set to docker/default or runtime/default
- **ID:** CKV_K8S_31
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-29

#### Ensure that Service Account Tokens are only mounted where necessary
- **ID:** CKV_K8S_38
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-35

#### Use read-only filesystem for containers where possible
- **ID:** CKV_K8S_22
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-21

#### Minimize the admission of containers with capabilities assigned
- **ID:** CKV_K8S_37
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-34

#### Apply security context to your pods and containers
- **ID:** CKV_K8S_29
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/ensure-securitycontext-is-applied-to-pods-and-containers

#### Minimize the admission of containers with the NET_RAW capability
- **ID:** CKV_K8S_28
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-27

#### Containers should not run with allowPrivilegeEscalation
- **ID:** CKV_K8S_20
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-19

#### Apply security context to your containers
- **ID:** CKV_K8S_30
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-28

#### Image should use digest
- **ID:** CKV_K8S_43
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-39

#### Image Pull Policy should be Always
- **ID:** CKV_K8S_15
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-14

#### The default namespace should not be used
- **ID:** CKV_K8S_21
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-20

#### Minimize the admission of root containers
- **ID:** CKV_K8S_23
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-22

#### Containers should run as a high UID to avoid host conflict
- **ID:** CKV_K8S_40
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-37

#### Prefer using secrets as files over secrets as environment variables
- **ID:** CKV_K8S_35
- **Ressource:** StatefulSet.default.n8n-main
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [1,53]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-33

#### Ensure that the seccomp profile is set to docker/default or runtime/default
- **ID:** CKV_K8S_31
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-29

#### Ensure that Service Account Tokens are only mounted where necessary
- **ID:** CKV_K8S_38
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-35

#### Use read-only filesystem for containers where possible
- **ID:** CKV_K8S_22
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-21

#### Minimize the admission of containers with capabilities assigned
- **ID:** CKV_K8S_37
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-34

#### Apply security context to your pods and containers
- **ID:** CKV_K8S_29
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/ensure-securitycontext-is-applied-to-pods-and-containers

#### Minimize the admission of containers with the NET_RAW capability
- **ID:** CKV_K8S_28
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-27

#### Containers should not run with allowPrivilegeEscalation
- **ID:** CKV_K8S_20
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-19

#### Apply security context to your containers
- **ID:** CKV_K8S_30
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-28

#### Image should use digest
- **ID:** CKV_K8S_43
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-39

#### Image Pull Policy should be Always
- **ID:** CKV_K8S_15
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-14

#### The default namespace should not be used
- **ID:** CKV_K8S_21
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-20

#### Minimize the admission of root containers
- **ID:** CKV_K8S_23
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-22

#### Containers should run as a high UID to avoid host conflict
- **ID:** CKV_K8S_40
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-37

#### Prefer using secrets as files over secrets as environment variables
- **ID:** CKV_K8S_35
- **Ressource:** Deployment.default.n8n-workers
- **Fichier:** /k8s/n8n-deployments.yaml
- **Lignes:** [54,108]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-33

#### The default namespace should not be used
- **ID:** CKV_K8S_21
- **Ressource:** Secret.default.n8n-sensitive-secrets
- **Fichier:** /k8s/n8n-secret.yaml
- **Lignes:** [2,12]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-20

#### The default namespace should not be used
- **ID:** CKV_K8S_21
- **Ressource:** ConfigMap.default.n8n-config-vars
- **Fichier:** /k8s/n8n-configmap.yaml
- **Lignes:** [2,19]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-20

#### The default namespace should not be used
- **ID:** CKV_K8S_21
- **Ressource:** Service.default.n8n-service
- **Fichier:** /k8s/n8n-services.yaml
- **Lignes:** [1,16]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-20

#### The default namespace should not be used
- **ID:** CKV_K8S_21
- **Ressource:** Service.default.n8n-worker-service
- **Fichier:** /k8s/n8n-services.yaml
- **Lignes:** [18,31]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/kubernetes-policies/kubernetes-policy-index/bc-k8s-20


### kubernetes - _terraform

✅ Aucun échec détecté

### secrets - _k8s

✅ Aucun échec détecté

### secrets - _terraform

✅ Aucun échec détecté

### terraform - _k8s

✅ Aucun échec détecté

### terraform - _terraform

**Nombre d'échecs:** 33

#### Ensure ACR admin account is disabled
- **ID:** CKV_AZURE_137
- **Ressource:** azurerm_container_registry.acr
- **Fichier:** /acr.tf
- **Lignes:** [2,12]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-iam-policies/bc-azure-137

#### Enable vulnerability scanning for container images.
- **ID:** CKV_AZURE_163
- **Ressource:** azurerm_container_registry.acr
- **Fichier:** /acr.tf
- **Lignes:** [2,12]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/azr-general-163

#### Ensure geo-replicated container registries to match multi-region container deployments.
- **ID:** CKV_AZURE_165
- **Ressource:** azurerm_container_registry.acr
- **Fichier:** /acr.tf
- **Lignes:** [2,12]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-networking-policies/azr-networking-165

#### Ensure ACR set to disable public networking
- **ID:** CKV_AZURE_139
- **Ressource:** azurerm_container_registry.acr
- **Fichier:** /acr.tf
- **Lignes:** [2,12]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-networking-policies/ensure-azure-acr-is-set-to-disable-public-networking

#### Ensure dedicated data endpoints are enabled.
- **ID:** CKV_AZURE_237
- **Ressource:** azurerm_container_registry.acr
- **Fichier:** /acr.tf
- **Lignes:** [2,12]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/bc-azure-237

#### Ensures that ACR uses signed/trusted images
- **ID:** CKV_AZURE_164
- **Ressource:** azurerm_container_registry.acr
- **Fichier:** /acr.tf
- **Lignes:** [2,12]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/azr-general-164

#### Ensure a retention policy is set to cleanup untagged manifests.
- **ID:** CKV_AZURE_167
- **Ressource:** azurerm_container_registry.acr
- **Fichier:** /acr.tf
- **Lignes:** [2,12]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/azr-general-167

#### Ensure Azure Container Registry (ACR) is zone redundant
- **ID:** CKV_AZURE_233
- **Ressource:** azurerm_container_registry.acr
- **Fichier:** /acr.tf
- **Lignes:** [2,12]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/bc-azure-233

#### Ensure container image quarantine, scan, and mark images verified
- **ID:** CKV_AZURE_166
- **Ressource:** azurerm_container_registry.acr
- **Fichier:** /acr.tf
- **Lignes:** [2,12]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/azr-general-166

#### Ensure AKS local admin account is disabled
- **ID:** CKV_AZURE_141
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-iam-policies/ensure-azure-kubernetes-service-aks-local-admin-account-is-disabled

#### Ensure that AKS uses Azure Policies Add-on
- **ID:** CKV_AZURE_116
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-kubernetes-policies/ensure-that-aks-uses-azure-policies-add-on

#### Ensure Azure Kubernetes Cluster (AKS) nodes should use a minimum number of 50 pods.
- **ID:** CKV_AZURE_168
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-kubernetes-policies/azr-kubernetes-168

#### Ensure that AKS uses disk encryption set
- **ID:** CKV_AZURE_117
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-kubernetes-policies/ensure-that-aks-uses-disk-encryption-set

#### Ensure AKS cluster has Network Policy configured
- **ID:** CKV_AZURE_7
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-kubernetes-policies/bc-azr-kubernetes-4

#### Ensure ephemeral disks are used for OS disks
- **ID:** CKV_AZURE_226
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-kubernetes-policies/bc-azure-226

#### Ensure that AKS use the Paid Sku for its SLA
- **ID:** CKV_AZURE_170
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/azr-general-170

#### Ensure that AKS enables private clusters
- **ID:** CKV_AZURE_115
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-kubernetes-policies/ensure-that-aks-enables-private-clusters

#### Ensure that the AKS cluster encrypt temp disks, caches, and data flows between Compute and Storage resources
- **ID:** CKV_AZURE_227
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-kubernetes-policies/bc-azure-227

#### Ensure autorotation of Secrets Store CSI Driver secrets for AKS clusters
- **ID:** CKV_AZURE_172
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/azr-general-172

#### Ensure AKS cluster upgrade channel is chosen
- **ID:** CKV_AZURE_171
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-networking-policies/azr-networking-171

#### Ensure AKS logging to Azure Monitoring is Configured
- **ID:** CKV_AZURE_4
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-kubernetes-policies/bc-azr-kubernetes-1

#### Ensure AKS has an API Server Authorized IP Ranges enabled
- **ID:** CKV_AZURE_6
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-kubernetes-policies/bc-azr-kubernetes-3

#### Ensure that only critical system pods run on system nodes
- **ID:** CKV_AZURE_232
- **Ressource:** azurerm_kubernetes_cluster.aks
- **Fichier:** /aks.tf
- **Lignes:** [1,27]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-kubernetes-policies/bc-azure-232

#### Ensure that PostgreSQL Flexible server enables geo-redundant backups
- **ID:** CKV_AZURE_136
- **Ressource:** azurerm_postgresql_flexible_server.pg
- **Fichier:** /databases.tf
- **Lignes:** [14,28]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/ensure-azure-postgresql-flexible-server-enables-geo-redundant-backups

#### Ensure Redis Cache is using the latest version of TLS encryption
- **ID:** CKV_AZURE_148
- **Ressource:** azurerm_redis_cache.redis
- **Fichier:** /databases.tf
- **Lignes:** [37,44]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-networking-policies/ensure-azure-aks-cluster-nodes-do-not-have-public-ip-addresses

#### Ensure that Azure Cache for Redis disables public network access
- **ID:** CKV_AZURE_89
- **Ressource:** azurerm_redis_cache.redis
- **Fichier:** /databases.tf
- **Lignes:** [37,44]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-networking-policies/ensure-that-azure-cache-for-redis-disables-public-network-access

#### Standard Replication should be enabled
- **ID:** CKV_AZURE_230
- **Ressource:** azurerm_redis_cache.redis
- **Fichier:** /databases.tf
- **Lignes:** [37,44]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-storage-policies/bc-azure-230

#### Ensure the key vault is recoverable
- **ID:** CKV_AZURE_42
- **Ressource:** azurerm_key_vault.akv
- **Fichier:** /keyvault.tf
- **Lignes:** [3,30]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/ensure-the-key-vault-is-recoverable

#### Ensure that key vault allows firewall rules settings
- **ID:** CKV_AZURE_109
- **Ressource:** azurerm_key_vault.akv
- **Fichier:** /keyvault.tf
- **Lignes:** [3,30]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-networking-policies/ensure-that-key-vault-allows-firewall-rules-settings

#### Ensure that key vault enables purge protection
- **ID:** CKV_AZURE_110
- **Ressource:** azurerm_key_vault.akv
- **Fichier:** /keyvault.tf
- **Lignes:** [3,30]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/ensure-that-key-vault-enables-purge-protection

#### Ensure that Azure Key Vault disables public network access
- **ID:** CKV_AZURE_189
- **Ressource:** azurerm_key_vault.akv
- **Fichier:** /keyvault.tf
- **Lignes:** [3,30]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-networking-policies/azr-networking-189

#### Ensure that the expiration date is set on all secrets
- **ID:** CKV_AZURE_41
- **Ressource:** azurerm_key_vault_secret.pg_password
- **Fichier:** /keyvault.tf
- **Lignes:** [32,36]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-secrets-policies/set-an-expiration-date-on-all-secrets

#### Ensure that key vault secrets have "content_type" set
- **ID:** CKV_AZURE_114
- **Ressource:** azurerm_key_vault_secret.pg_password
- **Fichier:** /keyvault.tf
- **Lignes:** [32,36]
- **Guide:** https://docs.prismacloud.io/en/enterprise-edition/policy-reference/azure-policies/azure-general-policies/ensure-that-key-vault-secrets-have-content-type-set



---

## Recommandations Prioritaires

### Sécurité Kubernetes
1. **Configurer seccomp profiles:** Activer les profils seccomp (docker/default ou runtime/default)
2. **Limiter les Service Account Tokens:** Ne monter les tokens que là où nécessaire
3. **Utiliser read-only filesystem:** Configurer les conteneurs avec système de fichiers en lecture seule
4. **Restreindre les capabilities:** Ne donner que les capabilities nécessaires
5. **Éviter les conteneurs privilégiés:** Désactiver le mode privileged
6. **Définir des limites de ressources:** Configurer CPU et mémoire limits/requests
7. **Utiliser des images signées:** Vérifier la signature des images

### Sécurité Terraform
1. **Chiffrement:** S'assurer que toutes les ressources sensibles sont chiffrées
2. **Accès réseau:** Restreindre les accès réseau au strict nécessaire
3. **Authentification forte:** Utiliser l'authentification multi-facteur
4. **Logs et monitoring:** Activer les logs pour toutes les ressources critiques
5. **Gestion des secrets:** Ne jamais stocker de secrets en dur

### Secrets
1. **Scanner régulièrement:** Vérifier qu'aucun secret n'est exposé dans le code
2. **Utiliser des gestionnaires de secrets:** Azure Key Vault, Kubernetes Secrets
3. **Rotation des secrets:** Implémenter une rotation régulière

---

## Fichiers de Rapport

- **Rapport Markdown:** `rapport_tp6_analyse.md` (ce fichier)
- **Rapport HTML:** `rapport_tp6.html`
- **Rapport PDF:** `rapport_tp6.pdf`
- **Rapports JSON détaillés:** `*.json`

---

*Rapport généré par Checkov - Infrastructure as Code Security Scanner*
