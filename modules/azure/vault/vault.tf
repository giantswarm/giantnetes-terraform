resource "azurerm_user_assigned_identity" "vault" {
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"

  name = "${var.cluster_name}-keyvault-id"

  tags {
    Name                   = "${var.cluster_name}"
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}

resource "azurerm_managed_disk" "vault_data" {
  name                 = "${var.cluster_name}-vault-data-disk"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  storage_account_type = "${var.storage_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.data_disk_size}"
}

resource "azurerm_virtual_machine" "vault" {
  name                  = "vault"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${var.network_interface_ids[0]}"]
  vm_size               = "${var.vm_size}"

  identity = {
    type = "UserAssigned"
    identity_ids = ["${azurerm_user_assigned_identity.vault.id}"]
  }

  lifecycle {
    # Vault provisioned also by Ansible,
    # so prevent recreation if os_profile or storage_image_reference changed.
    ignore_changes = ["os_profile", "storage_image_reference"]
  }

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = false

  storage_image_reference {
    publisher = "CoreOS"
    offer     = "CoreOS"
    sku       = "${var.container_linux_channel}"
    version   = "${var.container_linux_version}"
  }

  storage_os_disk {
    name              = "vault-os"
    managed_disk_type = "${var.os_disk_storage_type}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    os_type           = "Linux"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.vault_data.name}"
    managed_disk_id = "${azurerm_managed_disk.vault_data.id}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${azurerm_managed_disk.vault_data.disk_size_gb}"
  }

  os_profile {
    computer_name  = "vault"
    admin_username = "core"
    admin_password = ""
    custom_data    = "${base64encode("${var.user_data}")}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/core/.ssh/authorized_keys"
      key_data = "${var.core_ssh_key}"
    }
  }

  tags {
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}
