variable "location" {
  description = "Région Azure pour le déploiement."
  type        = string
  default     = "francecentral"
}

variable "resource_group_name" {
  description = "Group-n8n-AKS"
  type        = string
  default     = "RG-N8N-AKS"
}

variable "acr_name_prefix" {
  description = "Acr"
  type        = string
  default     = "acrn8ntf"
}

variable "pg_admin_password" {
  description = "Mdp admin postgreSQL"
  type        = string
  sensitive   = true
}

variable "pg_admin_user" {
  description = "Nom d'utilisateur admin PostgreSQL"
  type        = string
  default     = "n8nadmin"
}

variable "n8n_encryption_key" {
  description = "Clé de chiffrement N8N (optionnelle, générée si non fournie)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "subscription_id" {
  description = "ID de l'abonnement Azure"
  type        = string
}