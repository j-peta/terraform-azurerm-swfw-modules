vm-series scale set terraform module
===========

A terraform module for VMSS VM series firewalls in Azure.

Usage
-----

```hcl
module "vmss" {
  source      = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules/modules/vmss"
  location    = "Australia Central"
  name_prefix = "panostf"
  password    = "your-password"
  subnet-mgmt    = azurerm_subnet.subnet-mgmt
  subnet-private = azurerm_subnet.subnet-private
  subnet-public  = module.networks.subnet-public
  bootstrap-storage-account     = module.panorama.bootstrap-storage-account
  bootstrap-share-name  = "inboundsharename"
  vhd-container           = "vhd-storage-container-name"
  lb_backend_pool_id = "private-backend-pool-id"
}
```

## Requirements

| Name | Version |
|------|---------|
| azurerm | >=2.26.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >=2.26.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bootstrap-share-name | File share for bootstrap config | `any` | n/a | yes |
| bootstrap-storage-account | Storage account setup for bootstrapping | `any` | n/a | yes |
| lb\_backend\_pool\_id | ID Of inbound load balancer backend pool to associate with the VM series firewall | `any` | n/a | yes |
| location | Region to install VM Series Scale sets and dependencies. | `any` | n/a | yes |
| name\_domain\_name\_label | n/a | `string` | `"inbound-vm-mgmt"` | no |
| name\_fw | n/a | `string` | `"inbound-fw"` | no |
| name\_fw\_mgmt\_pip | n/a | `string` | `"inbound-fw-mgmt-pip"` | no |
| name\_mgmt\_nic\_ip | n/a | `string` | `"inbound-nic-fw-mgmt"` | no |
| name\_mgmt\_nic\_profile | n/a | `string` | `"inbound-nic-fw-mgmt-profile"` | no |
| name\_prefix | Prefix to add to all the object names here | `any` | n/a | yes |
| name\_private\_nic\_ip | n/a | `string` | `"inbound-nic-fw-private"` | no |
| name\_private\_nic\_profile | n/a | `string` | `"inbound-nic-fw-private-profile"` | no |
| name\_public\_nic\_ip | n/a | `string` | `"inbound-nic-fw-public"` | no |
| name\_public\_nic\_profile | n/a | `string` | `"inbound-nic-fw-public-profile"` | no |
| name\_rg | n/a | `string` | `"vmseries-rg"` | no |
| name\_scale\_set | n/a | `string` | `"inbound-scaleset"` | no |
| password | Password for VM Series firewalls | `any` | n/a | yes |
| sep | Seperator | `string` | `"-"` | no |
| subnet-mgmt | Management subnet. | `any` | n/a | yes |
| subnet-private | internal/private subnet | `any` | n/a | yes |
| subnet-public | External/public subnet | `any` | n/a | yes |
| username | Username | `string` | `"panadmin"` | no |
| vhd-container | Storage container for storing VMSS instance VHDs. | `any` | n/a | yes |
| vm\_count | Minimum instances per scale set. | `number` | `2` | no |
| vm\_series\_sku | VM-series SKU - list available with az vm image list --publisher paloaltonetworks --all | `string` | `"bundle2"` | no |
| vm\_series\_version | VM-series Software version | `string` | `"9.0.4"` | no |
| vmseries\_size | Default size for VM series | `string` | `"Standard_D5_v2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| inbound-scale-set-name | Name of inbound scale set |
