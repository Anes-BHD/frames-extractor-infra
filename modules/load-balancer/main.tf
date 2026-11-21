locals {
  prefix = "${var.project}-${var.environment}"
}

resource "azurerm_public_ip" "this" {
  count               = var.enable_app_gateway ? 1 : 0
  name                = "${local.prefix}-agw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_application_gateway" "this" {
  count               = var.enable_app_gateway ? 1 : 0
  name                = "${local.prefix}-agw"
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = ["1", "2"]
  tags                = var.tags

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.this[0].id
  }

  backend_address_pool {
    name = "app"
  }

  probe {
    name                = "app-probe"
    protocol            = "Http"
    host                = "127.0.0.1"
    path                = "/"
    interval            = 15
    timeout             = 10
    unhealthy_threshold = 2
  }

  backend_http_settings {
    name                  = "app-http"
    cookie_based_affinity = "Disabled"
    port                  = var.backend_port
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "app-probe"
  }

  http_listener {
    name                           = "http"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-to-app"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "http"
    backend_address_pool_name  = "app"
    backend_http_settings_name = "app-http"
  }
}