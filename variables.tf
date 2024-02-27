#
# Contextual Fields
#

variable "context" {
  description = <<-EOF
Receive contextual information. When Walrus deploys, Walrus will inject specific contextual information into this field.

Examples:
```
context:
  project:
    name: string
    id: string
  environment:
    name: string
    id: string
  resource:
    name: string
    id: string
```
EOF
  type        = map(any)
  default     = {}
}

#
# Infrastructure Fields
#

variable "infrastructure" {
  description = <<-EOF
Specify the infrastructure information for deploying.

Examples:
```
infrastructure:
  resource_group: string             # the resource group name where to deploy the PostgreSQL Flexible Server
  virtual_network: string            # the virtual network name where to deploy the PostgreSQL Flexible Server
  subnet: string                     # the subnet name under the virtual network where to deploy the PostgreSQL Flexible Server
  domain_suffix: string              # a private DNS namespace of the PrivateZone where to register the applied PostgreSQL service. It must end with 'postgres.database.azure.com'
```
EOF
  type = object({
    resource_group  = string
    virtual_network = string
    subnet          = string
    domain_suffix   = string
  })
}

#
# Deployment Fields
#

variable "architecture" {
  description = <<-EOF
Specify the deployment architecture, select from standalone or replication.
EOF
  type        = string
  default     = "standalone"
  validation {
    condition     = var.architecture == "" || contains(["standalone", "replication"], var.architecture)
    error_message = "Invalid architecture"
  }
}

variable "replication_readonly_replicas" {
  description = <<-EOF
Specify the number of read-only replicas under the replication deployment.
EOF
  type        = number
  default     = 1
  validation {
    condition     = var.replication_readonly_replicas == 0 || contains([1, 3, 5], var.replication_readonly_replicas)
    error_message = "Invalid number of read-only replicas"
  }
}

variable "engine_version" {
  description = <<-EOF
Specify the deployment engine version of the PostgreSQL Flexible Server to use. Possible values are 11.0, 12.0, 13.0, 14.0, 15.0, and 16.0.
EOF
  type        = string
  default     = "16.0"
  validation {
    condition     = var.engine_version == "" || contains(["11.0", "12.0", "13.0", "14.0", "15.0", "16.0"], var.engine_version)
    error_message = "Invalid version"
  }
}

variable "database" {
  description = <<-EOF
Specify the database name. The database name must be 2-64 characters long and start with any lower letter, combined with number, or symbols: - _. 
The database name cannot be PostgreSQL forbidden keyword.
EOF
  type        = string
  default     = "mydb"
  validation {
    condition     = var.database == "" || can(regex("^[a-z][-a-z0-9_]{0,61}[a-z0-9]$", var.database))
    error_message = format("Invalid database: %s", var.database)
  }
}

variable "username" {
  description = <<-EOF
Specify the account username. The username must be 2-16 characters long and start with lower letter, combined with number.
The username cannot be PostgreSQL forbidden keyword and azure_superuser, azure_pg_admin, admin, administrator, root, guest or public.
EOF
  type        = string
  default     = "rdsuser"
  validation {
    condition = var.username == "" || (
      !can(regex("^(azure_superuser|azure_pg_admin|admin|administrator|root|guest|public)$", var.username)) &&
      can(regex("^[a-z][a-z0-9_]{0,14}[a-z0-9]$", var.username))
    )
    error_message = format("Invalid username: %s", var.username)
  }
}

variable "password" {
  description = <<-EOF
Specify the account password. The password must be 8-32 characters long and start with any letter, number, or symbols: ! # $ % ^ & * ( ) _ + - =.
If not specified, it will generate a random password.
EOF
  type        = string
  default     = null
  sensitive   = true
  validation {
    condition     = var.password == null || var.password == "" || can(regex("^[A-Za-z0-9\\!#\\$%\\^&\\*\\(\\)_\\+\\-=]{8,32}", var.password))
    error_message = "Invalid password"
  }
}

variable "resources" {
  description = <<-EOF
Specify the computing resources.
The computing resource design of Azure Cloud is very complex, it also needs to consider on the storage resource, please view the specification document for more information.
For example: B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3
See https://docs.microsoft.com/en-us/azure/postgresql/concepts-pricing-tiers for more information.
Examples:
```
resources:
  class: string, optional            # sku
```
EOF
  type = object({
    class = optional(string, "B_Standard_B1ms")
  })
  default = {
    class = "B_Standard_B1ms"
  }
}

variable "storage" {
  description = <<-EOF
Choosing the storage resource is also related to the computing resource, please view the specification document for more information.

Examples:
```
storage:
  size: number, optional         # in megabyte
```
EOF
  type = object({
    size = optional(number, 32768)
  })
  default = {
    size = 32768
  }
  validation {
    condition     = var.storage == null || contains([32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, 33554432], var.storage.size)
    error_message = "Storage size must be one of 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, 33554432"
  }
}
