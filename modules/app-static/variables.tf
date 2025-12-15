variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

# Variable de l'Étape 6 pour la création dynamique des Storage Accounts
variable "storage_configs" {
  type = map(object({
    kind = string
    replication_type = string
  }))
}