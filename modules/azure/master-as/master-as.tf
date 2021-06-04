resource "azurerm_managed_disk" "master_etcd" {
  count                = var.master_count
  name                 = "${var.cluster_name}-master-etcd-disk-${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.storage_type
  create_option        = "Empty"
  disk_size_gb         = var.etcd_disk_size
  tags = {
    GiantSwarmRole = "etcd"
    # etcd member ID is 1-based
    GiantSwarmEtcdID = count.index + 1
  }
}

resource "azurerm_virtual_machine_scale_set" "masters" {
  location            = var.location
  name                = "${var.cluster_name}-masters"
  resource_group_name = var.resource_group_name

  upgrade_policy_mode = "Rolling"
  health_probe_id     = var.node_health_probe_id
  rolling_upgrade_policy {
    max_batch_instance_percent              = 40
    max_unhealthy_instance_percent          = 40
    max_unhealthy_upgraded_instance_percent = 40
    pause_time_between_batches              = "PT30S"
  }
  network_profile {
    name                   = "master-nic-0"
    primary                = true
    accelerated_networking = var.enable_accelerated_networking
    ip_forwarding          = true
    ip_configuration {
      name      = "master-ipconfig-0"
      primary   = true
      subnet_id = var.subnet_id
      load_balancer_backend_address_pool_ids = var.load_balancer_backend_address_pool_ids
    }
  }
  overprovision = false
  plan {
    name      = var.flatcar_linux_channel
    publisher = "kinvolk"
    product   = "flatcar-container-linux-free"
  }
  os_profile {
    admin_username       = "core"
    computer_name_prefix = "master-"
    custom_data          = base64encode(data.ignition_config.loader.rendered)
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/core/.ssh/authorized_keys"
      key_data = var.core_ssh_key
    }
  }
  sku {
    name     = var.vm_size
    capacity = var.master_count
    tier     = "standard"
  }
  storage_profile_image_reference {
    publisher = "kinvolk"
    offer     = "flatcar-container-linux-free"
    sku       = var.flatcar_linux_channel
    version   = var.flatcar_linux_version
  }
  storage_profile_os_disk {
    managed_disk_type = var.os_disk_storage_type
    create_option     = "FromImage"
    caching           = "ReadWrite"
    os_type           = "linux"
  }
  storage_profile_data_disk {
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = var.docker_disk_size
    managed_disk_type = var.storage_type
  }
  identity {
    type = "SystemAssigned"
  }

  tags = {
    GiantSwarmInstallation       = var.cluster_name
    "cluster-autoscaler-enabled" = "false"
    "cluster-autoscaler-name"    = var.cluster_name
    min                          = var.master_count
    max                          = var.master_count
  }

  timeouts {
    create = "60m"
    delete = "2h"
  }
}

# can be added only when vm is created with identity
# https://github.com/hashicorp/terraform/issues/25578
resource "azurerm_role_assignment" "vmss_contributor" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_virtual_machine_scale_set.masters.identity[0].principal_id
}
