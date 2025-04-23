# Create DNS records
resource "digitalocean_domain" "domain" {
  name = var.domain
}

# DigitalOcean nameservers are consistent
# These are the standard nameservers for DigitalOcean domains
locals {
  digitalocean_nameservers = [
    "ns1.digitalocean.com",
    "ns2.digitalocean.com",
    "ns3.digitalocean.com"
  ]
}

# Configure Cloudflare DNS to use DigitalOcean nameservers
resource "cloudflare_record" "ns1" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain 
  type    = "NS"
  content = local.digitalocean_nameservers[0]
  ttl     = 3600
  proxied = false
}

resource "cloudflare_record" "ns2" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = "NS"
  content = local.digitalocean_nameservers[1]
  ttl     = 3600
  proxied = false
}

resource "cloudflare_record" "ns3" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = "NS"
  content = local.digitalocean_nameservers[2]
  ttl     = 3600
  proxied = false
}

# Create app DNS records in DigitalOcean
resource "digitalocean_record" "n8n" {
  domain = digitalocean_domain.domain.name
  type   = "A"
  name   = "n8n"
  value  = digitalocean_droplet.apps.ipv4_address
}

resource "digitalocean_record" "flowise" {
  domain = digitalocean_domain.domain.name
  type   = "A"
  name   = "flowise"
  value  = digitalocean_droplet.apps.ipv4_address
} 