resource "azurerm_availability_set" "workers" {
  name                = "${var.cluster_name}-workers"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  managed             = true

  tags {
    Environment = "${var.cluster_name}"
  }
}

resource "azurerm_managed_disk" "worker_docker" {
  count                = "${var.worker_count}"
  name                 = "${var.cluster_name}-worker-docker-disk-${count.index}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  storage_account_type = "${var.storage_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.docker_disk_size}"
}

resource "azurerm_virtual_machine" "worker" {
  count = "${var.worker_count}"

  # Name and computer_name in os_profile should be equal.
  # Both are used as identifiers of VM.
  name = "worker${count.index}"

  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${var.network_interface_ids[count.index]}"]
  availability_set_id   = "${azurerm_availability_set.workers.id}"
  vm_size               = "${var.vm_size}"

  lifecycle {
    # Workaround to ignore Kubernetes-managed persistent volumes.
    ignore_changes = ["storage_data_disk"]
  }

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "CoreOS"
    offer     = "CoreOS"
    sku       = "${var.container_linux_channel}"
    version   = "${var.container_linux_version}"
  }

  storage_os_disk {
    name              = "worker-${count.index}-os"
    managed_disk_type = "${var.storage_type}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    os_type           = "linux"
  }

  storage_data_disk {
    name            = "${element(azurerm_managed_disk.worker_docker.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.worker_docker.*.id, count.index)}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${element(azurerm_managed_disk.worker_docker.*.disk_size_gb, count.index)}"
  }

  os_profile {
    computer_name  = "worker${count.index}"
    admin_username = "core"
    admin_password = ""
    custom_data    = "${base64encode("${var.cloud_config_data}")}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/core/.ssh/authorized_keys"
      key_data = "${var.core_ssh_key}"
    }
  }

  tags {
    Environment = "${var.cluster_name}"
  }
}
