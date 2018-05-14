resource "azurerm_availability_set" "bastions" {
  name                        = "${var.cluster_name}-bastions"
  location                    = "${var.location}"
  resource_group_name         = "${var.resource_group_name}"
  managed                     = true
  platform_fault_domain_count = "${var.platform_fault_domain_count}"

  tags {
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}

resource "azurerm_virtual_machine" "bastion" {
  count                 = "${var.bastion_count}"
  name                  = "bastion${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${var.network_interface_ids[count.index]}"]
  vm_size               = "${var.vm_size}"
  availability_set_id   = "${azurerm_availability_set.bastions.id}"

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "CoreOS"
    offer     = "CoreOS"
    sku       = "${var.container_linux_channel}"
    version   = "${var.container_linux_version}"
  }

  storage_os_disk {
    name              = "bastion-${count.index}-os"
    managed_disk_type = "${var.storage_type}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    os_type           = "linux"
  }

  os_profile {
    computer_name  = "bastion${count.index}"
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
