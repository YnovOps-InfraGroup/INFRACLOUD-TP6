variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "vnet_cidr" { type = string }
variable "tags" { type = map(string) }
variable "subnet_vnet" { type = string }

# Variable complexe pour les règles de sécurité (Étape 6)
variable "ingress_rules" {
  type = list(object({
    port        = number
    cidr_blocks = list(string)
  }))
  description = "Liste des règles de trafic entrant."

  # Validation : Interdire 0.0.0.0/0 sur le port 22 (SSH)
  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      !(contains(rule.cidr_blocks, "0.0.0.0/0") && rule.port == 22)
    ])
    error_message = "L'accès '0.0.0.0/0' est interdit sur le port 22 pour des raisons de sécurité."
  }
}

