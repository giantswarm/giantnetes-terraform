resource "vsphere_folder" "main" {
  path          = var.folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.main.id
}

resource "vsphere_tag_category" "category" {
  count = length(var.tags)

  name        = var.tags[count.index]["scope"]
  cardinality = "SINGLE"

  associable_types = [
    "VirtualMachine",
    "Folder"
  ]
}

resource "vsphere_tag" "tag" {
  count = length(var.tags)

  name        = var.tags[count.index]["tag"]
  category_id = vsphere_tag_category.category[count.index].id
}

resource "vsphere_virtual_machine" "main" {
  count = var.node_count

  name             = format("%s-worker-%s", var.cluster_name, count.index)
  resource_pool_id = data.vsphere_compute_cluster.main.resource_pool_id
  datastore_id     = data.vsphere_datastore.main.id
  folder           = var.folder

  num_cpus = var.cpus_count
  memory   = var.memory
  guest_id = data.vsphere_virtual_machine.main_template.guest_id

  network_interface {
    network_id = data.vsphere_network.main.id
  }

  disk {
    // It's recommended that you set the disk label to a format matching diskN,
    // where N is the number of the adisk, starting from disk number 0.
    // This will ensure that your configuration is compatible when importing a
    // virtual machine.
    //
    // For more information, see the section on importing.
    label            = "disk0"
    size             = var.root_disk_size
  }

  disk {
    label = "disk1"
    size  = var.docker_disk_size
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.main_template.id
  }

  extra_config = {
    "guestinfo.ignition.config.data.encoding" = "base64"
    "guestinfo.ignition.config.data"          = base64encode(var.ignition_data)
  }

  // Advanced options
  nested_hv_enabled = var.nested_hv_enabled

  depends_on = [
    vsphere_folder.main
  ]

  tags = vsphere_tag.tag.*.id
}
