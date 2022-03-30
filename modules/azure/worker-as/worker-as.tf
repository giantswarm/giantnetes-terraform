locals {
  common_tags = var.additional_tags
}

resource "azurerm_linux_virtual_machine_scale_set" "workers" {
  location            = var.location
  name                = "${var.cluster_name}-workers"
  resource_group_name = var.resource_group_name
  upgrade_mode        = "Manual"
  health_probe_id     = var.node_health_probe_id

  admin_username = "core"
  instances      = var.min_worker_count
  sku            = var.vm_size

  terminate_notification {
    enabled = true
    timeout = "PT5M"
  }
  network_interface {
    name                          = "worker-nic-0"
    primary                       = true
    enable_accelerated_networking = var.enable_accelerated_networking
    enable_ip_forwarding          = true
    ip_configuration {
      name      = "worker-ipconfig-0"
      primary   = true
      subnet_id = var.subnet_id
      load_balancer_backend_address_pool_ids = [
        var.ingress_backend_address_pool_id
      ]
    }
  }
  overprovision = false
  plan {
    name      = var.flatcar_linux_channel
    publisher = "kinvolk"
    product   = "flatcar-container-linux-free"
  }
  computer_name_prefix = "worker-"
  custom_data          = base64encode(var.user_data)
  admin_ssh_key {
    public_key = var.core_ssh_key
    username   = "core"
  }
  disable_password_authentication = true
  source_image_reference {
    publisher = "kinvolk"
    offer     = "flatcar-container-linux-free"
    sku       = var.flatcar_linux_channel
    version   = var.flatcar_linux_version
  }
  os_disk {
    storage_account_type = var.os_disk_storage_type
    caching              = "ReadWrite"
  }
  data_disk {
    create_option        = "Empty"
    lun                  = 0
    disk_size_gb         = var.docker_disk_size
    storage_account_type = var.storage_type
    caching              = "None"
  }
  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.common_tags, map(
    "GiantSwarmInstallation", var.cluster_name,
    "cluster-autoscaler-enabled", "true",
    "cluster-autoscaler-name", var.cluster_name,
    "min", var.min_worker_count,
    "max", var.max_worker_count
  ))

  timeouts {
    create = "60m"
    delete = "2h"
  }

  lifecycle {
    ignore_changes = [instances,rolling_upgrade_policy]
  }
}

# can be added only when vm is created with identity
# https://github.com/hashicorp/terraform/issues/25578
resource "azurerm_role_assignment" "vmss_contributor" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_virtual_machine_scale_set.workers.identity[0].principal_id
}
