# DNS module (Azure DNS): the student's own subdomain.
#
#   1. Azure DNS zone        student03.lab.collabgigs.com
#   2. A record              app.student03.lab.collabgigs.com -> Application Gateway IP
#   3. (optional) Cloudflare 4 NS records that hand the subdomain over to Azure DNS.
#                            Without this step the public internet cannot find the zone.

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

resource "azurerm_dns_zone" "this" {
  name                = var.zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_dns_a_record" "app" {
  name                = "app"
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = 60
  records             = [var.app_ip]
}

resource "cloudflare_record" "delegation" {
  count = var.enable_cloudflare_delegation ? 4 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.zone_name
  type    = "NS"
  content = trimsuffix(tolist(azurerm_dns_zone.this.name_servers)[count.index], ".")
  ttl     = 300
  comment = "capstone lab - managed by Terraform"
}
