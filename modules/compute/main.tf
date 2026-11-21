locals {
  prefix = "${var.project}-${var.environment}"
}

resource "azurerm_linux_virtual_machine_scale_set" "this" {
  for_each = var.scale_sets

  name                = "${local.prefix}-vmss-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.vm_size
  instances           = var.min_capacity

  zones                       = [each.value.zone]
  platform_fault_domain_count = 1
  overprovision               = false
  upgrade_mode                = "Automatic"

  computer_name_prefix            = "${local.prefix}-${each.key}"
  admin_username                  = var.admin_username
  disable_password_authentication = true
  custom_data                     = base64encode(file("${path.module}/cloud-init.yaml"))

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name                                         = "internal"
      primary                                      = true
      subnet_id                                    = each.value.subnet_id
      application_security_group_ids               = [var.app_asg_id]
      application_gateway_backend_address_pool_ids = var.backend_pool_ids
    }
  }

  extension {
    name                       = "health"
    publisher                  = "Microsoft.ManagedServices"
    type                       = "ApplicationHealthLinux"
    type_handler_version       = "1.0"
    auto_upgrade_minor_version = true

    settings = jsonencode({
      protocol    = "http"
      port        = var.health_port
      requestPath = "/"
    })
  }
  automatic_instance_repair {
    enabled      = true
    grace_period = "PT10M"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [instances]
  }
}

resource "azurerm_monitor_autoscale_setting" "this" {
  for_each = var.scale_sets

  name                = "${local.prefix}-autoscale-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this[each.key].id
  tags                = var.tags

  profile {
    name = "cpu"

    capacity {
      default = var.min_capacity
      minimum = var.min_capacity
      maximum = var.max_capacity
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this[each.key].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this[each.key].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }
}