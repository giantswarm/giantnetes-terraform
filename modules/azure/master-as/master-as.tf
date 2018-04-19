resource "azurerm_availability_set" "masters" {
  name                = "${var.cluster_name}-masters"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  managed             = true

  tags {
    GiantSwarmInstallation = "${var.cluster_name}"
  }
}

resource "azurerm_managed_disk" "master_docker" {
  count                = "${var.master_count}"
  name                 = "${var.cluster_name}-master-docker-disk-${count.index}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  storage_account_type = "${var.storage_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.docker_disk_size}"
}

resource "azurerm_managed_disk" "master_etcd" {
  count                = "${var.master_count}"
  name                 = "${var.cluster_name}-master-etcd-disk-${count.index}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  storage_account_type = "${var.storage_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.etcd_disk_size}"
}

resource "azurerm_virtual_machine" "master" {
  count = "${var.master_count}"

  # Name and computer_name in os_profile should be equal.
  # Both are used as identifiers of VM.
  name = "master${count.index}"

  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${var.network_interface_ids[count.index]}"]
  availability_set_id   = "${azurerm_availability_set.masters.id}"
  vm_size               = "${var.vm_size}"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = false

  storage_image_reference {
    publisher = "CoreOS"
    offer     = "CoreOS"
    sku       = "${var.container_linux_channel}"
    version   = "${var.container_linux_version}"
  }

  storage_os_disk {
    name              = "master-${count.index}-os"
    managed_disk_type = "${var.storage_type}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    os_type           = "linux"
  }

  storage_data_disk {
    name            = "${element(azurerm_managed_disk.master_docker.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.master_docker.*.id, count.index)}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${element(azurerm_managed_disk.master_docker.*.disk_size_gb, count.index)}"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.master_etcd.name}"
    managed_disk_id = "${azurerm_managed_disk.master_etcd.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.master_etcd.disk_size_gb}"
  }

  os_profile {
    computer_name  = "master${count.index}"
    admin_username = "core"
    admin_password = ""
    custom_data    = "${base64encode("${data.ignition_config.loader.rendered}")}"
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

resource "local_file" "master_ignition" {
  content  = "${var.user_data}"
  filename = "${path.cwd}/generated/master-ignition.yaml"
}

resource "azurerm_storage_blob" "ignition_blob" {
  name = "master-ignition-${timestamp()}.yaml"

  resource_group_name    = "${var.resource_group_name}"
  storage_account_name   = "${var.blob_storage_account}"
  storage_container_name = "${var.blob_storage_container}"

  type   = "block"
  source = "${path.cwd}/generated/master-ignition.yaml"
}

data "ignition_config" "loader" {
  replace {
    source = "${azurerm_storage_blob.ignition_blob.url}"
  }
}
