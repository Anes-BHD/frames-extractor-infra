locals {
  prefix = "${var.project}-${var.environment}"
}

resource "azurerm_application_security_group" "app" {
  name                = "${local.prefix}-app-asg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# --- Load balancer (Application Gateway) subnets ---
resource "azurerm_network_security_group" "public" {
  name                = "${local.prefix}-public-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-web-from-internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-gateway-manager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
}

# --- App tier: web traffic only from the load balancer subnet ---
resource "azurerm_network_security_group" "app" {
  name                = "${local.prefix}-app-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                                       = "allow-web-from-lb-subnet"
    priority                                   = 100
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    destination_port_ranges                    = var.app_ports
    source_address_prefixes                    = [var.subnet_cidrs["public-a"], var.subnet_cidrs["public-b"]]
    destination_application_security_group_ids = [azurerm_application_security_group.app.id]
  }

  security_rule {
    name                       = "deny-all-other-vnet-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# --- DB tier: PostgreSQL only from the app tier ---
resource "azurerm_network_security_group" "db" {
  name                = "${local.prefix}-db-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                                  = "allow-postgres-from-app"
    priority                              = 100
    direction                             = "Inbound"
    access                                = "Allow"
    protocol                              = "Tcp"
    source_port_range                     = "*"
    destination_port_range                = "5432"
    source_application_security_group_ids = [azurerm_application_security_group.app.id]
    destination_address_prefix            = "*"
  }

  security_rule {
    name                       = "deny-all-other-vnet-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# --- Attach each NSG to its subnets ---
locals {
  associations = {
    "public-a" = azurerm_network_security_group.public.id
    "public-b" = azurerm_network_security_group.public.id
    "app-a"    = azurerm_network_security_group.app.id
    "app-b"    = azurerm_network_security_group.app.id
    "db-a"     = azurerm_network_security_group.db.id
    "db-b"     = azurerm_network_security_group.db.id
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.associations

  subnet_id                 = var.subnet_ids[each.key]
  network_security_group_id = each.value
}