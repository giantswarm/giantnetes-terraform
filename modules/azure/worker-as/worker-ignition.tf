locals {
  timenow = timestamp()
}

# Only necessary, because azurerm_storage_blob requires file as a source.
resource "local_file" "worker_ignition" {
  content  = var.user_data
  filename = "${path.cwd}/generated/worker-ignition.yaml"
}

resource "azurerm_storage_blob" "ignition_blob" {
  name = "worker-ignition-${md5(var.user_data)}.yaml"

  storage_account_name   = var.storage_acc
  storage_container_name = var.storage_container

  type   = "Block"
  source = "${path.cwd}/generated/worker-ignition.yaml"
}

# Create temporary credentials to access storage account objects.
data "azurerm_storage_account_sas" "sas" {
  connection_string = var.storage_acc_url
  https_only        = true

  # Set TTL to 3 months from execution time.
  start  = local.timenow
  expiry = timeadd(local.timenow, "2160h")

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}

data "ignition_config" "loader" {
  count = var.worker_count

  replace {
    source = "${azurerm_storage_blob.ignition_blob.url}${data.azurerm_storage_account_sas.sas.sas}"
  }
}
