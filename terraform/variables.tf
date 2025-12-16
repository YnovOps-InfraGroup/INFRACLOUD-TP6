variable "location" {
  description = "Région Azure pour le déploiement."
  type        = string
  default     = "france-central"
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