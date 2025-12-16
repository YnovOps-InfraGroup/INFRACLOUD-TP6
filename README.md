<<<<<<< HEAD
voici une documentationn
=======
# Infrastructure Réseau Azure (N8N - AKS)

Ce dépôt contient le code **Terraform** permettant de déployer l'infrastructure réseau nécessaire pour le projet N8N sur Azure Kubernetes Service (AKS).

L'état de l'infrastructure (State) est stocké dans un backend distant sur Azure Storage.

##  Architecture

Le code déploie un **Virtual Network (VNet)** segmenté en plusieurs sous-réseaux pour isoler les charges de travail.

| Ressource | Nom | CIDR | Description |
| :--- | :--- | :--- | :--- |
| **VNet** | `vnet1` | `10.0.0.0/16` | Réseau principal |
| **Subnet** | `Snet-Aks` | `10.0.1.0/24` | Sous-réseau pour AKS. **Délégué** au service `Microsoft.ServiceNetworking/trafficControllers` (ALB). |
| **Subnet** | `Snet-DB` | `10.0.2.0/24` | Sous-réseau dédié à la base de données. |
| **Subnet** | `Snet-ADMIN`| `10.0.3.0/24` | Sous-réseau d'administration. |

### Association ALB
Le subnet `Snet-Aks` est automatiquement associé à l'Application Load Balancer (Traffic Controller) identifié dans le groupe de ressources `RG-N8N-AKS`.

---

##  Prérequis

Avant d'exécuter ce code, assurez-vous que les ressources suivantes existent déjà sur Azure, car elles sont référencées par le code (Data Sources ou IDs fixes) :

1.  **Resource Group** : `RG-N8N-AKS`
2.  **Storage Account (Backend)** : `stoynovgroup` (Container : `tfstate`)
3.  **Traffic Controller (ALB)** : `AGC-N8N-AKS` (Nécessaire pour l'association du subnet).

---

##  CI/CD (GitHub Actions)

Le déploiement est automatisé via le workflow défini dans `.github/workflows/push.yaml`.

### Déclenchement
* **Push** sur la branche `feat/DEV-Thibaut`.
* **Manuel** via l'interface GitHub (`workflow_dispatch`).

### Pipeline
Le workflow effectue les actions suivantes sur un runner `ubuntu-latest` :
1.  **Login Azure** (via Service Principal).
2.  **Terraform Setup** (v1.9.0).
3.  **Init & Validation** (Formatage et syntaxe).
4.  **Plan** (Génération du plan d'exécution).
5.  **Apply** (Déploiement automatique, uniquement sur push).

### Configuration des Secrets
Le secret suivant doit être configuré dans le dépôt GitHub :
* `AZURE_CREDENTIALS` : JSON du Service Principal (avec droits sur la souscription).

---

## Utilisation Locale

Pour tester ou modifier l'infrastructure depuis votre poste :

1.  **Authentification**
    ```bash
    az login
    az account set --subscription "ID_DE_SUB"
    ```

2.  **Commandes Terraform**
    ```bash
    # Initialisation du backend et des providers
    terraform init

    # Vérification du formatage
    terraform fmt

    # Validation de la configuration
    terraform validate

    # Prévisualisation des changements
    terraform plan
    ```

---

##  Informations Techniques

* **Provider Azure** : `hashicorp/azurerm` v4.56.0
* **Terraform Version** : v1.9.0+
* **Backend** : Azure Storage (`terraform.tfstate`)
>>>>>>> 73079a2398e45efcc9631ab18cfaf17e59563c4b
