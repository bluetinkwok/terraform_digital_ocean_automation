# Output values
output "droplet_ip" {
  description = "The public IP address of the droplet"
  value       = digitalocean_droplet.apps.ipv4_address
}

output "n8n_url" {
  description = "The URL for accessing n8n"
  value       = "https://n8n.${var.domain}"
}

output "flowise_url" {
  description = "The URL for accessing Flowise"
  value       = "https://flowise.${var.domain}"
}

output "digitalocean_nameservers" {
  description = "Nameservers for the DigitalOcean domain"
  value       = local.digitalocean_nameservers
} 