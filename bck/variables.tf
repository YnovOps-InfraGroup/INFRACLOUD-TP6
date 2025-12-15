variable "environment" {
  type        = string
  description = "Environnement cible (dev, staging, prod)"
}

variable "app_name" {
  type        = string
  description = "Nom logique de l'application (doit être court)"
}

variable "location" {
  type        = string
  description = "Région Azure pour le déploiement"
  default     = "switzerlandnorth" # Région par défaut mise à jour
}

variable "mandatory_tags" {
  type        = map(string)
  description = "Tags obligatoires pour toutes les ressources"
}

# Variable ajoutée pour l'Étape 6 (Gestion dynamique du stockage)
variable "storage_configs" {
  type = map(object({
    kind = string
    replication_type = string
  }))
  description = "Configuration des Storage Accounts à créer de manière dynamique."
  default = {
    "primary" = {
      kind = "StorageV2"
      replication_type = "LRS"
    }
    "logs" = {
      kind = "StorageV2"
      replication_type = "LRS"
    }
  }
}

variable "vnet_cidr" {
  type        = string
  description = "CIDR global du réseau"
  default     = "10.0.0.0/16"
}

variable "ingress_rules" {
  type = list(object({
    port        = number
    cidr_blocks = list(string)
  }))
  description = "Règles de sécurité pour le réseau"
  default     = [] # Vide par défaut
}