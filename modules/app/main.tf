locals {
  prefix    = "${var.project}-${var.environment}"
  instances = var.enable_app ? 1 : 0
}

resource "azurerm_network_interface" "this" {
  count               = local.instances
  name                = "${local.prefix}-app-nic"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Same ASG as the nginx sets: the db NSG already allows 5432 from it.
resource "azurerm_network_interface_application_security_group_association" "this" {
  count                         = local.instances
  network_interface_id          = azurerm_network_interface.this[0].id
  application_security_group_id = var.app_asg_id
}

# The identity pulls the image (AcrPull) and the model weights (Blob Data Reader).
resource "azurerm_role_assignment" "acr_pull" {
  count                = local.instances
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = var.identity_principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "models_reader" {
  count                = local.instances
  scope                = var.models_storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.identity_principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_linux_virtual_machine" "this" {
  count                           = local.instances
  name                            = "${local.prefix}-app"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  tags                            = var.tags
  size                            = var.vm_size
  zone                            = var.zone
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.this[0].id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_public_key
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml.tftpl", {
    acr_login_server   = var.acr_login_server
    image_tag          = var.image_tag
    models_account     = var.models_storage_account_name
    model_folder       = var.model_folder
    identity_client_id = var.identity_client_id
  }))

  # Boot only after the roles exist, so the first pull does not race them.
  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.models_reader,
  ]
}

# Videos, frames and the index live here, not on the 30 GB OS disk.
resource "azurerm_managed_disk" "data" {
  count                = local.instances
  name                 = "${local.prefix}-app-data"
  resource_group_name  = var.resource_group_name
  location             = var.location
  tags                 = var.tags
  zone                 = var.zone
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count              = local.instances
  managed_disk_id    = azurerm_managed_disk.data[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.this[0].id
  lun                = 0
  caching            = "ReadWrite"
}


# Joins the Application Gateway backend pool. The gateway probes port 80, so the container publishes 80.
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "this" {
  for_each                = var.enable_app && var.attach_to_gateway ? toset(["pool"]) : toset([])
  network_interface_id    = azurerm_network_interface.this[0].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.backend_pool_ids[0]
}
