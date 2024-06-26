variable "name" {
  description = <<-EOF
  Name of the Storage Account.
  Either a new or an existing one (depending on the value of `storage_account.create`).

  The name you choose must be unique across Azure. The name also must be between 3 and 24 characters in length, and may include
  only numbers and lowercase letters.
  EOF
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = <<-EOF
    A Storage Account name must be between 3 and 24 characters, only lower case letters and numbers are allowed.
    EOF
  }
}

variable "resource_group_name" {
  description = "The name of the Resource Group to use."
  type        = string
}

variable "region" {
  description = "The name of the Azure region to deploy the resources in."
  default     = null
  type        = string
}

variable "tags" {
  description = "The map of tags to assign to all created resources."
  default     = {}
  type        = map(string)
}

variable "storage_account" {
  description = <<-EOF
  A map controlling basic Storage Account configuration.

  Following properties are available:

  - `create`           - (`bool`, optional, defaults to `true`) controls if the Storage Account is created or sourced.
  - `replication_type` - (`string`, optional, defaults to `LRS`) only for newly created Storage Accounts, defines the replication
                         type used. Can be one of the following values: `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` or `RAGZRS`.
  - `kind`             - (`string`, optional, defaults to `StorageV2`) only for newly created Storage Accounts, defines the
                         account type. Can be one of the following: `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage`
                         or `StorageV2`.
  - `tier`             - (`string`, optional, defaults to `Standard`) only for newly created Storage Accounts, defines the
                         account tier. Can be either `Standard` or `Premium`. Note, that for `kind` set to `BlockBlobStorage` or
                         `FileStorage` the `tier` can only be set to `Premium`.
  - `blob_retention`   - (`number`, optional, defaults to Azure default) specifies the number of days that the blob should be
                         retained before irreversibly deleted. When set to `0`, soft delete is disabled for the Storage Account.
  EOF
  default     = {}
  nullable    = false
  type = object({
    create           = optional(bool, true)
    replication_type = optional(string, "LRS")
    kind             = optional(string, "StorageV2")
    tier             = optional(string, "Standard")
    blob_retention   = optional(number)
  })
  validation { # replication_type
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account.replication_type)
    error_message = <<-EOF
    The `replication_type` property can be one of: \"LRS\", \"GRS\", \"RAGRS\", \"ZRS\", \"GZRS\" or \"RAGZRS\".
    EOF
  }
  validation { # kind
    condition = contains(
      ["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.storage_account.kind
    )
    error_message = <<-EOF
    The `kind` property can be one of: \"BlobStorage\", \"BlockBlobStorage\", \"FileStorage\", \"Storage\" or \"StorageV2\"."
    EOF
  }
  validation { # tier
    condition     = contains(["Standard", "Premium"], var.storage_account.tier)
    error_message = <<-EOF
    The `tier` property can be one of: \"Standard\" or \"Premium\".
    EOF
  }
  validation { # kind & tier
    condition = contains(
      ["BlockBlobStorage", "FileStorage"], var.storage_account.kind
    ) ? var.storage_account.tier == "Premium" : true
    error_message = <<-EOF
    If the `kind` property is set to either \"BlockBlobStorage\" or \"FileStorage\", the `tier` has to be set to \"Premium\"."
    EOF
  }
  validation { # blob_retention
    condition = var.storage_account.blob_retention != null ? (
      var.storage_account.blob_retention >= 0 && var.storage_account.blob_retention <= 365
    ) : true
    error_message = <<-EOF
    The `blob_retention` property can take values between 0 and 365.
    EOF
  }
}

variable "storage_network_security" {
  description = <<-EOF
  A map defining network security settings for a new storage account.

  When not set or set to `null` it will disable any network security setting.

  When you decide define this setting, at least one of `allowed_public_ips` or `allowed_subnet_ids` has to be defined.
  Otherwise you will cut anyone off the storage account. This will have implications on this Terraform code as it operates on
  File Shares. Files Shares API comes under this networks restrictions.

  Following properties are available:

  - `min_tls_version`     - (`string`, optional, defaults to `TLS1_2`) minimum supported TLS version.
  - `allowed_public_ips`  - (`list`, optional, defaults to `[]`) list of IP CIDR ranges that are allowed to access the Storage
                            Account. Only public IPs are allowed, RFC1918 address space is not permitted.
  - `allowed_subnet_ids`  - (`list`, optional, defaults to `[]`) list of the allowed VNet subnet ids. Note that this option
                            requires network service endpoint enabled for Microsoft Storage for the specified subnets.
                            If you are using [vnet module](../vnet/README.md), set `storage_private_access` to true for the
                            specific subnet.
  EOF
  default     = {}
  nullable    = false
  type = object({
    min_tls_version    = optional(string, "TLS1_2")
    allowed_public_ips = optional(list(string), [])
    allowed_subnet_ids = optional(list(string), [])
  })
  validation { # min_tls_version
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.storage_network_security.min_tls_version)
    error_message = <<-EOF
    The `min_tls_version` property can be one of: \"TLS1_0\", \"TLS1_1\", \"TLS1_2\".
    EOF
  }
}

variable "file_shares_configuration" {
  description = <<-EOF
  A map defining common File Share setting.

  Any of this can be overridden in a particular File Share definition. See [`file_shares`](#file_shares) variable for details.

  Following options are available:
  
  - `create_file_shares`            - (`bool`, optional, defaults to `true`) controls if the File Shares specified in the
                                      `file_shares` variable are created or sourced, if the latter, the storage account also 
                                      has to be sourced.
  - `disable_package_dirs_creation` - (`bool`, optional, defaults to `false`) for sourced File Shares, controls if the bootstrap
                                      package folder structure is created.
  - `quota`                         - (`number`, optional, defaults to `10`) maximum size of a File Share in GB, a value between
                                      1 and 5120 (5TB).
  - `access_tier`                   - (`string`, optional, defaults to `Cool`) access tier for a File Share, can be one of: 
                                      "Cool", "Hot", "Premium", "TransactionOptimized". 
  EOF
  default     = {}
  nullable    = false
  type = object({
    create_file_shares            = optional(bool, true)
    disable_package_dirs_creation = optional(bool, false)
    quota                         = optional(number, 10)
    access_tier                   = optional(string, "Cool")
  })
  validation { # disable_package_dirs_creation
    condition = (
      var.file_shares_configuration.create_file_shares ? !var.file_shares_configuration.disable_package_dirs_creation : true
    )
    error_message = <<-EOF
    The `disable_package_dirs_creation` cannot be set to true for newly created File Shares.
    EOF
  }
  validation { # quota
    condition     = var.file_shares_configuration.quota >= 1 && var.file_shares_configuration.quota <= 5120
    error_message = <<-EOF
    The `quota` property can take values between 1 and 5120.
    EOF
  }
  validation { # access_tier
    condition     = contains(["Cool", "Hot", "Premium", "TransactionOptimized"], var.file_shares_configuration.access_tier)
    error_message = <<-EOF
    The `access_tier` property can take one of the following values: \"Cool\", \"Hot\", \"Premium\", \"TransactionOptimized\".
    EOF
  }
}

variable "file_shares" {
  description = <<-EOF
  Definition of File Shares.

  This is a map of objects where each object is a File Share definition. There are situations where every firewall can use the
  same bootstrap package. But there are also situations where each firewall (or a group of firewalls) need a separate one.

  This configuration parameter can help you to create multiple File Shares, per your needs, w/o multiplying Storage Accounts
  at the same time.

  Following properties are available per each File Share definition:

  - `name`                    - (`string`, required) name of the File Share.
  - `bootstrap_package_path`  - (`string`, optional, defaults to `null`) a path to a folder containing a full bootstrap package.
                                For details on the bootstrap package structure see [documentation](https://docs.paloaltonetworks.com/vm-series/9-1/vm-series-deployment/bootstrap-the-vm-series-firewall/bootstrap-package).
  - `bootstrap_files`         - (`map`, optional, defaults to `{}`) a map of files that will be copied to the File Share and 
                                build the bootstrap package. 
                                
      Keys are local paths, values - remote. Only Unix like directory separator (`/`) is supported. If `bootstrap_package_path`
      is also specified, these files will overwrite any file uploaded from that path.

  - `bootstrap_files_md5`     - (`map`, optional, defaults to `{}`) a map of MD5 hashes for files specified in `bootstrap_files`.

      For static files (present and/or not modified before Terraform plan kicks in) this map can be empty. The MD5 hashes are
      calculated automatically. It's only required for files modified/created by Terraform. You can use `md5` or `filemd5`
      Terraform functions to calculate MD5 hashes dynamically.

      Keys in this map are local paths, variables - MD5 hashes. For files for which you would like to provide MD5 hashes, 
      keys in this map should match keys in `bootstrap_files` property.


  Additionally you can override the default `quota` and `access_tier` properties per File Share (same restrictions apply):

  - `quota`       - (`number`, optional, defaults to `var.file_shares_configuration.quota`) maximum size of a File Share in GB,
                    a value between 1 and 5120 (5TB).
  - `access_tier` - (`string`, optional, defaults to `var.file_shares_configuration.access_tier`) access tier for a File Share,
                    can be one of: "Cool", "Hot", "Premium", "TransactionOptimized".
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name                   = string
    bootstrap_package_path = optional(string)
    bootstrap_files        = optional(map(string), {})
    bootstrap_files_md5    = optional(map(string), {})
    quota                  = optional(number)
    access_tier            = optional(string)
  }))
  validation { # name
    condition = alltrue([
      for _, v in var.file_shares :
      alltrue([
        can(regex("^[a-z0-9](-?[a-z0-9])+$", v.name)),
        can(regex("^([a-z0-9-]){3,63}$", v.name))
      ])
    ])
    error_message = <<-EOF
    A File Share name must be between 3 and 63 characters, all lowercase numbers, letters or a dash, it must follow a valid URL
    schema.
    EOF
  }
  validation { # quota
    condition     = alltrue([for _, v in var.file_shares : v.quota >= 1 && v.quota <= 5120 if v.quota != null])
    error_message = <<-EOF
    The `quota` property can take values between 1 and 5120.
    EOF
  }
  validation { # access_tier
    condition = alltrue([
      for _, v in var.file_shares :
      contains(["Cool", "Hot", "Premium", "TransactionOptimized"], v.access_tier)
      if v.access_tier != null
    ])
    error_message = <<-EOF
    The `access_tier` property can take one of the following values: \"Cool\", \"Hot\", \"Premium\", \"TransactionOptimized\".
    EOF
  }
}
