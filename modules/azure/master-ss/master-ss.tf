resource "azurerm_virtual_machine_scale_set" "master" {
  name                = "${var.cluster_name}-master"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  upgrade_policy_mode = "Manual"

  sku {
    name     = "${var.vm_size}"
    tier     = "Standard"
    capacity = "${var.master_count}"
  }

  network_profile {
    name    = "masterNetworkProfile"
    primary = true

    ip_configuration {
      name                                   = "masterIPConfiguration"
      subnet_id                              = "${var.subnet_id}"
      load_balancer_backend_address_pool_ids = ["${var.api_backend_address_pool_id}"]
    }
  }

  storage_profile_image_reference {
    publisher = "CoreOS"
    offer     = "CoreOS"
    sku       = "${var.container_linux_channel}"
    version   = "${var.container_linux_version}"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.storage_type}"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = "${var.docker_disk_size}"
  }

  storage_profile_data_disk {
    lun           = 1
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = "${var.etcd_disk_size}"
  }

  os_profile {
    computer_name_prefix = "master"
    admin_username       = "core"

    # this should be fixed.
    admin_password = "ResetPassw0rdInCloudConfig"
    custom_data    = "${base64encode("${var.cloud_config_data}")}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    Environment = "${var.cluster_name}"
  }
}
