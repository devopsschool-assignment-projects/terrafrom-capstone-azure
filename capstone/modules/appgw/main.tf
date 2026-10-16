# Application Gateway module (with WAF): the public front door.
#
#   Internet --> Public IP --> Application Gateway (WAF) --> internal Load Balancer --> frontend pods
#
# The backend is the private IP of the AKS internal load balancer. We choose
# that IP ahead of time, so there is no circular dependency with the cluster.

resource "azurerm_public_ip" "this" {
  name                = "pip-${var.name}-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "this" {
  name                = "waf-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  policy_settings {
    enabled = true
    mode    = var.waf_mode
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

locals {
  frontend_ip_name   = "public"
  frontend_port_name = "http-80"
  pool_name          = "aks-internal-lb"
  settings_name      = "http-to-aks"
  probe_name         = "frontend-health"
  listener_name      = "http"
  rule_name          = "route-all"
}

resource "azurerm_application_gateway" "this" {
  name                = "agw-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id
  tags                = var.tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_name
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  backend_address_pool {
    name         = local.pool_name
    ip_addresses = [var.backend_ip]
  }

  probe {
    name                = local.probe_name
    protocol            = "Http"
    host                = "127.0.0.1"
    path                = "/healthz"
    interval            = 15
    timeout             = 10
    unhealthy_threshold = 3
    match {
      status_code = ["200"]
    }
  }

  backend_http_settings {
    name                  = local.settings_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = local.probe_name
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.rule_name
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.pool_name
    backend_http_settings_name = local.settings_name
  }
}
