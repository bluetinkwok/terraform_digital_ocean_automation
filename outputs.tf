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

output "digital_ocean_domain" {
  description = "The domain configured in DigitalOcean"
  value       = digitalocean_domain.domain.name
}

output "n8n_record" {
  description = "The n8n DNS record details"
  value       = {
    domain = digitalocean_record.n8n.domain
    name   = digitalocean_record.n8n.name
    fqdn   = digitalocean_record.n8n.fqdn
    value  = digitalocean_record.n8n.value
  }
}

output "digitalocean_nameservers" {
  description = "Nameservers for the DigitalOcean domain"
  value       = local.digitalocean_nameservers
} 