locals {
  timenow = formatdate("YYYY-MM-DD'T'00:00:00'Z'", timestamp())
}

# Only necessary, because azurerm_storage_blob requires file as a source.
resource "local_file" "master_ignition" {
  content  = var.user_data
  filename = "${path.cwd}/generated/master-ignition.yaml"
}

resource "azurerm_storage_blob" "ignition_blob" {
  name = "master-ignition-${md5(var.user_data)}.yaml"

  storage_account_name   = var.storage_acc
  storage_container_name = var.storage_container

  type   = "Block"
  source = "${path.cwd}/generated/master-ignition.yaml"
}

# Create temporary credentials to access storage account objects.
data "azurerm_storage_account_sas" "sas" {
  connection_string = var.storage_acc_url
  https_only        = true

  # Set TTL to 6 months from execution time.
  start  = local.timenow
  expiry = timeadd(local.timenow, "4320h")

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
  replace {
    source = "${azurerm_storage_blob.ignition_blob.url}${data.azurerm_storage_account_sas.sas.sas}"
  }
}
