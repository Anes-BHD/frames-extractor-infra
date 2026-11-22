data "azurerm_subscription" "current" {}

# The remote state account (created by bootstrap). CI needs blob access to read/lock state.
data "azurerm_storage_account" "tfstate" {
  name                = var.tfstate_storage_account_name
  resource_group_name = var.tfstate_resource_group_name
}

locals {
  tags = {
    Project     = var.project
    Environment = "ci"
    Owner       = var.owner
    ManagedBy   = "terraform"
  }

  issuer = "https://token.actions.githubusercontent.com"
  repo   = "${var.github_owner}/${var.github_repo}"

  # Plan identity: pull requests and runs on main.
  plan_subjects = {
    pull-request = "repo:${local.repo}:pull_request"
    main         = "repo:${local.repo}:ref:refs/heads/main"
  }

  # Apply identity: only jobs that run inside a GitHub environment.
  apply_subjects = { for e in var.environments : e => "repo:${local.repo}:environment:${e}" }

  plan_roles = {
    reader     = { role = "Reader", scope = data.azurerm_subscription.current.id }
    kv-secrets = { role = "Key Vault Secrets User", scope = data.azurerm_subscription.current.id }
    state      = { role = "Storage Blob Data Contributor", scope = data.azurerm_storage_account.tfstate.id }
  }

  apply_roles = {
    contributor = { role = "Contributor", scope = data.azurerm_subscription.current.id }
    rbac-admin  = { role = "Role Based Access Control Administrator", scope = data.azurerm_subscription.current.id }
    state       = { role = "Storage Blob Data Contributor", scope = data.azurerm_storage_account.tfstate.id }
  }
}

resource "azurerm_resource_group" "ci" {
  name     = "${var.project}-ci-rg"
  location = var.location
  tags     = local.tags
}

resource "azurerm_user_assigned_identity" "plan" {
  name                = "${var.project}-ci-plan-id"
  resource_group_name = azurerm_resource_group.ci.name
  location            = var.location
  tags                = local.tags
}

resource "azurerm_user_assigned_identity" "apply" {
  name                = "${var.project}-ci-apply-id"
  resource_group_name = azurerm_resource_group.ci.name
  location            = var.location
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "plan" {
  for_each = local.plan_subjects

  name      = "github-${each.key}"
  parent_id = azurerm_user_assigned_identity.plan.id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = local.issuer
  subject   = each.value
}

resource "azurerm_federated_identity_credential" "apply" {
  for_each = local.apply_subjects

  name      = "github-env-${each.key}"
  parent_id = azurerm_user_assigned_identity.apply.id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = local.issuer
  subject   = each.value
}

resource "azurerm_role_assignment" "plan" {
  for_each = local.plan_roles

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_user_assigned_identity.plan.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "apply" {
  for_each = local.apply_roles

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_user_assigned_identity.apply.principal_id
  principal_type       = "ServicePrincipal"
}
