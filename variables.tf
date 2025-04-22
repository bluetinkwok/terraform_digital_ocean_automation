variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "sgp1"  # Singapore region
}

variable "droplet_size" {
  description = "Droplet size for applications"
  type        = string
  default     = "s-1vcpu-2gb"  # 1 CPU, 2GB RAM
}

variable "domain" {
  description = "Domain name for applications (must be managed by DigitalOcean)"
  type        = string
}

variable "email" {
  description = "Email address for SSL certificates"
  type        = string
}

variable "n8n_username" {
  description = "Username for n8n admin"
  type        = string
}

variable "n8n_password" {
  description = "Password for n8n admin"
  type        = string
  sensitive   = true
}

variable "flowise_username" {
  description = "Username for Flowise admin"
  type        = string
}

variable "flowise_password" {
  description = "Password for Flowise admin"
  type        = string
  sensitive   = true
}

variable "enable_backups" {
  description = "Enable daily backups for n8n and Flowise data"
  type        = bool
  default     = false
}

variable "backup_time" {
  description = "Time to run daily backups in cron format (e.g., '0 2 * * *' for 2 AM)"
  type        = string
  default     = "0 2 * * *"  # 2 AM daily
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
} 

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

