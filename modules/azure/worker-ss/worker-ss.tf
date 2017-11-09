# This is worlaround until bug will be fixed
# https://github.com/terraform-providers/terraform-provider-azurerm/issues/490
#
# IMPORTANT:
# This breaks terraform destroy. Please execute `az vmss delete -n worker -g <resource-group>` before terraform destroy.

resource "azurerm_template_deployment" "worker" {
  name                = "${var.cluster_name}-worker"
  resource_group_name = "${var.resource_group_name}"

  # Incremental will not be touching existing resources in res group.
  deployment_mode = "Incremental"

  parameters {
    "adminUsername"          = "core"
    "adminSSHKeyData"        = "${var.core_ssh_key}"
    "instanceCount"          = "${var.worker_count}"
    "containerLinuxChannel"  = "${var.container_linux_channel}"
    "containerLinuxVersion"  = "${var.container_linux_version}"
    "cloudConfigData"        = "${base64encode("${var.cloud_config_data}")}"
    "diskSizeDocker"         = "${var.docker_disk_size}"
    "lbIngressBackendPoolID" = "${var.ingress_backend_address_pool_id}"
    "storageType"            = "${var.storage_type}"
    "subnetID"               = "${var.subnet_id}"
    "vmSku"                  = "${var.vm_size}"
    "vmssName"               = "worker"
  }

  template_body = <<DEPLOY
{
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "adminUsername": {
      "type": "string",
      "metadata": {
        "description": "Admin username on all VMs."
      }
    },
    "adminSSHKeyData": {
      "type": "string",
      "metadata": {
        "description": "Admin ssh public key data."
      }
    },
    "instanceCount": {
      "type": "string",
      "metadata": {
        "description": "Number of VM instances (100 or less)."
      }
    },
    "containerLinuxChannel": {
      "type": "string"
    },
    "containerLinuxVersion": {
      "type": "string"
    },
    "cloudConfigData": {
      "type": "string",
      "metadata": {
        "description": "Base64 enconded cloud config data."
      }
    },
    "diskSizeDocker": {
      "type": "string",
      "metadata": {
        "description": "Disk size for Docker."
      }
    },
    "lbIngressBackendPoolID": {
      "type": "string",
      "metadata": {
        "description": "Load balancer backend pool ID."
      }
    },
    "storageType": {
      "type": "string",
      "metadata": {
        "description": "vm storage type (e.g. Premium_LRS)."
      }
    },
    "subnetID": {
      "type": "string",
      "metadata": {
        "description": "ID of subnet"
      }
    },
    "vmSku": {
      "type": "string",
      "defaultValue": "Standard_D1_v2",
      "metadata": {
        "description": "Size of VMs in the VM Scale Set."
      }
    },
    "vmssName": {
      "type": "string",
      "metadata": {
        "description": "String used as a base for naming resources (9 characters or less). A hash is prepended to this string for some resources, and resource-specific information is appended."
      },
      "maxLength": 9
    }
  },
  "variables": {
    "adminSSHKeyPath": "[concat('/home/', parameters('adminUsername'), '/.ssh/authorized_keys')]",
    "location": "[resourceGroup().location]",
    "nicName": "[concat(parameters('vmssName'), 'nic')]",
    "ipConfigName": "[concat(parameters('vmssName'), 'ipconfig')]",
    "scaleRuleName": "[concat(parameters('vmssName'), 'scalingrule')]",
    "osType": {
      "publisher": "CoreOS",
      "offer": "CoreOS",
      "sku": "[parameters('containerLinuxChannel')]",
      "version": "[parameters('containerLinuxVersion')]"
    },
    "imageReference": "[variables('osType')]"
  },
  "resources": [
    {
      "type": "Microsoft.Insights/autoscaleSettings",
      "name": "[variables('scaleRuleName')]",
      "location": "[variables('location')]",
      "apiVersion": "2015-04-01",
      "tags": {
        "Environment": "[parameters('vmssName')]"
      },
      "dependsOn": [
        "[concat('Microsoft.Compute/virtualMachineScaleSets/', parameters('vmssName'))]"
      ],
      "properties": {
        "profiles": [
          {
            "name": "Autoscale to specific instance count",
            "capacity": {
              "minimum": "[int(parameters('instanceCount'))]",
              "maximum": "[int(parameters('instanceCount'))]",
              "default": "[int(parameters('instanceCount'))]"
            },
            "rules": []
          }
        ],
        "enabled": true,
        "name": "[variables('scaleRuleName')]",
        "targetResourceUri": "[concat('/subscriptions/',subscription().subscriptionId, '/resourceGroups/',  resourceGroup().name, '/providers/Microsoft.Compute/virtualMachineScaleSets/', parameters('vmssName'))]",
        "targetResourceLocation": "[variables('location')]",
        "notifications": []
      }
    },
    {
      "type": "Microsoft.Compute/virtualMachineScaleSets",
      "name": "[parameters('vmssName')]",
      "location": "[variables('location')]",
      "apiVersion": "2017-03-30",
      "tags": {
        "Environment": "[parameters('vmssName')]"
      },
      "sku": {
        "name": "[parameters('vmSku')]",
        "tier": "Standard",
        "capacity": "[int(parameters('instanceCount'))]"
      },
      "properties": {
        "overprovision": "false",
        "upgradePolicy": {
          "mode": "Manual"
        },
        "virtualMachineProfile": {
          "storageProfile": {
            "osDisk": {
              "caching": "ReadWrite",
              "createOption": "FromImage"
            },
            "imageReference": "[variables('imageReference')]",
            "dataDisks": [
              {
                "diskSizeGB": "[int(parameters('diskSizeDocker'))]",
                "lun": 0,
                "caching": "ReadWrite",
                "createOption": "Empty",
                "managedDisk": {
                  "storageAccountType": "[parameters('storageType')]"
                }
              }
             ]
          },
          "osProfile": {
            "computerNamePrefix": "[parameters('vmssName')]",
            "adminUsername": "[parameters('adminUsername')]",
            "customData": "[parameters('cloudConfigData')]",
            "linuxConfiguration": {
              "disablePasswordAuthentication": true,
              "ssh": {
                "publicKeys": [
                  {
                    "keyData": "[parameters('adminSSHKeyData')]",
                    "path": "[variables('adminSSHKeyPath')]"
                  }
                ]
              }
            }
          },
          "networkProfile": {
            "networkInterfaceConfigurations": [
              {
                "name": "[variables('nicName')]",
                "properties": {
                  "primary": true,
                  "ipConfigurations": [
                    {
                      "name": "[variables('ipConfigName')]",
                      "properties": {
                        "subnet": {
                          "id": "[parameters('subnetID')]"
                        },
                        "loadBalancerBackendAddressPools": [
                          {
                            "id": "[parameters('lbIngressBackendPoolID')]"
                          }
                        ]
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      }
    }
  ]
}
DEPLOY
}
