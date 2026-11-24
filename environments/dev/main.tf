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
    for k, v in {
      "a" = { zone = "1", subnet_id = module.network.subnet_ids["app-a"] }
      "b" = { zone = "2", subnet_id = module.network.subnet_ids["app-b"] }
    } : k => v if var.enable_nginx_tier
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


module "keyvault" {
  source = "../../modules/keyvault"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  store_db_password = var.enable_database
  db_admin_password = module.database.admin_password
}


data "azurerm_container_registry" "shared" {
  count               = var.enable_app ? 1 : 0
  name                = var.acr_name
  resource_group_name = var.shared_resource_group_name
}

data "azurerm_storage_account" "models" {
  count               = var.enable_app ? 1 : 0
  name                = var.models_storage_account_name
  resource_group_name = var.shared_resource_group_name
}

module "app" {
  source = "../../modules/app"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  enable_app           = var.enable_app
  subnet_id            = module.network.subnet_ids["app-a"]
  app_asg_id           = module.security.app_asg_id
  admin_ssh_public_key = var.admin_ssh_public_key

  identity_id           = module.keyvault.identity_id
  identity_principal_id = module.keyvault.identity_principal_id
  identity_client_id    = module.keyvault.identity_client_id

  acr_id                        = try(data.azurerm_container_registry.shared[0].id, "")
  acr_login_server              = try(data.azurerm_container_registry.shared[0].login_server, "")
  models_storage_account_id     = try(data.azurerm_storage_account.models[0].id, "")
  models_storage_account_name   = var.models_storage_account_name
  model_folder                  = var.model_folder
  image_tag                     = var.app_image_tag
  attach_to_gateway             = var.enable_app_gateway
  backend_pool_ids              = tolist(module.load_balancer.backend_pool_ids)
  appinsights_connection_string = try(data.azurerm_application_insights.shared[0].connection_string, "")
}


data "azurerm_log_analytics_workspace" "shared" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.project}-shared-law"
  resource_group_name = var.shared_resource_group_name
}

data "azurerm_application_insights" "shared" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.project}-shared-appi"
  resource_group_name = var.shared_resource_group_name
}

module "monitoring" {
  source = "../../modules/monitoring"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  enable_monitoring = var.enable_monitoring && var.enable_app
  vm_id             = module.app.vm_id
  identity_id       = module.keyvault.identity_id
  workspace_id      = try(data.azurerm_log_analytics_workspace.shared[0].id, "")
  alert_email       = var.alert_email
}
