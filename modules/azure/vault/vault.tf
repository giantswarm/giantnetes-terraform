resource "azurerm_managed_disk" "vault_data" {
  name                 = "${var.cluster_name}-vault-data-disk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.storage_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size
}

resource "azurerm_managed_disk" "logs_data" {
  name                 = "${var.cluster_name}-logs-data-disk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.storage_type
  create_option        = "Empty"
  disk_size_gb         = var.logs_disk_size
}

resource "azurerm_virtual_machine" "vault" {
  name                  = "vault"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [var.network_interface_ids[0]]
  vm_size               = var.vm_size

  lifecycle {
    # Vault provisioned also by Ansible,
    # so prevent recreation if os_profile or storage_image_reference changed.
    ignore_changes = [os_profile, storage_image_reference]
  }

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = false

  storage_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.flatcar_linux_channel
    version   = var.flatcar_linux_version
  }

  # The plan needs to be added only if we use Flatcar.
  dynamic "plan" {
    for_each = var.image_publisher == "kinvolk" ? [1] : []
    content {
      name      = var.flatcar_linux_channel
      publisher = var.image_publisher
      product   = "flatcar-container-linux-free"
    }
  }

  storage_os_disk {
    name              = "vault-os"
    managed_disk_type = var.os_disk_storage_type
    create_option     = "FromImage"
    caching           = "ReadWrite"
    os_type           = "Linux"
  }

  storage_data_disk {
    name            = azurerm_managed_disk.vault_data.name
    managed_disk_id = azurerm_managed_disk.vault_data.id
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = azurerm_managed_disk.vault_data.disk_size_gb
  }

  storage_data_disk {
    name            = azurerm_managed_disk.logs_data.name
    managed_disk_id = azurerm_managed_disk.logs_data.id
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = azurerm_managed_disk.logs_data.disk_size_gb
  }

  os_profile {
    computer_name  = "vault"
    admin_username = "core"
    admin_password = ""
    custom_data    = base64encode(var.user_data)
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/core/.ssh/authorized_keys"
      key_data = var.core_ssh_key
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    GiantSwarmInstallation = var.cluster_name
  }
}

resource "azurerm_role_definition" "vault_access_role" {
  name        = "${var.cluster_name}-vault-access"
  scope       = "/subscriptions/${var.subscription_id}/resourceGroups/${var.cluster_name}"
  description = "Custom role used to provide vault access to VMs/VMSSs"

  permissions {
    actions = ["Microsoft.Compute/availabilitySets/read", "Microsoft.Compute/virtualMachines/read"]
  }
}

resource "azurerm_role_assignment" "vault_access_role_assignment" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.cluster_name}"
  role_definition_name = "${var.cluster_name}-vault-access" 
  principal_id         = azurerm_virtual_machine.vault.identity[0].principal_id
}
