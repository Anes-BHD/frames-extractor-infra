locals {
  prefix    = "${var.project}-${var.environment}"
  instances = var.enable_monitoring ? 1 : 0
}

# What to collect from the VM and where to send it.
resource "azurerm_monitor_data_collection_rule" "this" {
  count               = local.instances
  name                = "${local.prefix}-dcr"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "Linux"
  tags                = var.tags

  destinations {
    log_analytics {
      workspace_resource_id = var.workspace_id
      name                  = "law"
    }
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["law"]
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Syslog"]
    destinations = ["law"]
  }

  data_sources {
    # Feeds the portal Monitor blade (VM insights).
    performance_counter {
      name                          = "vminsights"
      streams                       = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
    }

    # Plain counters for KQL queries and the memory alert.
    performance_counter {
      name                          = "perf"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "Processor(*)\\% Processor Time",
        "Memory(*)\\% Used Memory",
        "Memory(*)\\Available MBytes Memory",
        "Logical Disk(*)\\% Used Space",
        "Network(*)\\Total Bytes",
      ]
    }

    # The app container logs through the syslog driver (facility daemon, tag "frames").
    syslog {
      name           = "syslog"
      streams        = ["Microsoft-Syslog"]
      facility_names = ["daemon", "auth", "cron", "kern", "user"]
      log_levels     = ["Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency"]
    }
  }
}

# The agent runs inside the VM and authenticates with the user-assigned identity.
resource "azurerm_virtual_machine_extension" "ama" {
  count                      = local.instances
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = var.vm_id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  tags                       = var.tags

  settings = jsonencode({
    authentication = {
      managedIdentity = {
        "identifier-name"  = "mi_res_id"
        "identifier-value" = var.identity_id
      }
    }
  })
}

resource "azurerm_monitor_data_collection_rule_association" "this" {
  count                   = local.instances
  name                    = "${local.prefix}-dcra"
  target_resource_id      = var.vm_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.this[0].id

  depends_on = [azurerm_virtual_machine_extension.ama]
}

# ---------- alerts ----------
resource "azurerm_monitor_action_group" "this" {
  count               = local.instances
  name                = "${local.prefix}-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "framesdev"
  tags                = var.tags

  email_receiver {
    name          = "owner"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "cpu" {
  count               = local.instances
  name                = "${local.prefix}-cpu-high"
  resource_group_name = var.resource_group_name
  scopes              = [var.vm_id]
  description         = "Sustained high CPU on the app VM (indexing or a runaway process)."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.this[0].id
  }
}

# B-series VMs are throttled when credits run out: long indexing jobs can drain them.
resource "azurerm_monitor_metric_alert" "cpu_credits" {
  count               = local.instances
  name                = "${local.prefix}-cpu-credits-low"
  resource_group_name = var.resource_group_name
  scopes              = [var.vm_id]
  description         = "B-series CPU credits are nearly exhausted: the VM is about to be throttled."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "CPU Credits Remaining"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 20
  }

  action {
    action_group_id = azurerm_monitor_action_group.this[0].id
  }
}

# fp32 SigLIP needs about 4.5 GB of the 8 GiB: warn before the OOM killer does.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "memory" {
  count                = local.instances
  name                 = "${local.prefix}-memory-high"
  resource_group_name  = var.resource_group_name
  location             = "francecentral"
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [var.workspace_id]
  severity             = 2
  description          = "Memory used on the app VM is above 90 percent."
  tags                 = var.tags

  criteria {
    query                   = <<-KQL
      Perf
      | where ObjectName == "Memory" and CounterName == "% Used Memory"
      | project TimeGenerated, Computer, CounterValue
    KQL
    time_aggregation_method = "Average"
    metric_measure_column   = "CounterValue"
    operator                = "GreaterThan"
    threshold               = 90

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.this[0].id]
  }
}
