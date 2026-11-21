locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.location
  tags     = local.tags
}

module "network" {
  source              = "../../modules/network"
  enable_nat_gateway  = var.enable_nat_gateway
  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  subnets = {
    "public-a" = { cidr = "10.20.1.0/24" }
    "public-b" = { cidr = "10.20.2.0/24" }
    "app-a"    = { cidr = "10.20.11.0/24", private_subnet = true }
    "app-b"    = { cidr = "10.20.12.0/24", private_subnet = true }
    "db-a"     = { cidr = "10.20.21.0/24", delegation = "Microsoft.DBforPostgreSQL/flexibleServers" }
    "db-b"     = { cidr = "10.20.22.0/24" }
  }
}

module "database" {
  source = "../../modules/database"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  vnet_id         = module.network.vnet_id
  subnet_id       = module.network.subnet_ids["db-a"]
  enable_database = var.enable_database
}

module "security" {
  source = "../../modules/security"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  subnet_ids   = module.network.subnet_ids
  subnet_cidrs = module.network.subnet_cidrs
}

module "load_balancer" {
  source = "../../modules/load-balancer"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  subnet_id          = module.network.subnet_ids["public-a"]
  enable_app_gateway = var.enable_app_gateway
}

module "compute" {
  source = "../../modules/compute"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  app_asg_id           = module.security.app_asg_id
  admin_ssh_public_key = var.admin_ssh_public_key
  backend_pool_ids     = module.load_balancer.backend_pool_ids

  scale_sets = {
    "a" = { zone = "1", subnet_id = module.network.subnet_ids["app-a"] }
    "b" = { zone = "2", subnet_id = module.network.subnet_ids["app-b"] }
  }
}

module "storage" {
  source = "../../modules/storage"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}
