locals {
  project_name     = coalesce(try(var.context["project"]["name"], null), "default")
  project_id       = coalesce(try(var.context["project"]["id"], null), "default_id")
  environment_name = coalesce(try(var.context["environment"]["name"], null), "test")
  environment_id   = coalesce(try(var.context["environment"]["id"], null), "test_id")
  resource_name    = coalesce(try(var.context["resource"]["name"], null), "example")
  resource_id      = coalesce(try(var.context["resource"]["id"], null), "example_id")

  namespace = join("-", [local.project_name, local.environment_name])

  tags = {
    "Name" = join("-", [local.namespace, local.resource_name])

    "walrus.seal.io-catalog-name"     = "terraform-azure-postgresql"
    "walrus.seal.io-project-id"       = local.project_id
    "walrus.seal.io-environment-id"   = local.environment_id
    "walrus.seal.io-resource-id"      = local.resource_id
    "walrus.seal.io-project-name"     = local.project_name
    "walrus.seal.io-environment-name" = local.environment_name
    "walrus.seal.io-resource-name"    = local.resource_name
  }

  architecture = coalesce(var.architecture, "standalone")
}

# create resource group.

resource "azurerm_resource_group" "default" {
  count = var.infrastructure.resource_group == null ? 1 : 0

  name     = "default"
  location = "eastus"
}

# create virtual network.

resource "azurerm_virtual_network" "default" {
  count = var.infrastructure.virtual_network == null ? 1 : 0

  name                = "default"
  resource_group_name = data.azurerm_resource_group.selected.name
  location            = data.azurerm_resource_group.selected.location
  address_space       = ["10.0.0.0/16"]
}

# create subnet.

resource "azurerm_subnet" "default" {
  count = var.infrastructure.subnet == null || var.infrastructure.virtual_network == null ? 1 : 0

  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.selected.name
  virtual_network_name = data.azurerm_virtual_network.selected.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# create private dns.

resource "azurerm_private_dns_zone" "default" {
  count = var.infrastructure.domain_suffix == null || var.infrastructure.resource_group == null ? 1 : 0

  name                = "example.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.selected.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  count = var.infrastructure.domain_suffix == null || var.infrastructure.resource_group == null ? 1 : 0

  name                  = "example_virtual_network_link"
  private_dns_zone_name = data.azurerm_private_dns_zone.selected.name
  virtual_network_id    = data.azurerm_virtual_network.selected.id
  resource_group_name   = data.azurerm_resource_group.selected.name
}

#
# Ensure
#
data "azurerm_resource_group" "selected" {
  name = var.infrastructure.resource_group != null ? var.infrastructure.resource_group : azurerm_resource_group.default[0].name

  lifecycle {
    postcondition {
      condition     = self.id != null
      error_message = "Resource group is not avaiable"
    }
  }
}

data "azurerm_virtual_network" "selected" {
  name                = var.infrastructure.virtual_network != null ? var.infrastructure.virtual_network : azurerm_virtual_network.default[0].name
  resource_group_name = data.azurerm_resource_group.selected.name

  lifecycle {
    postcondition {
      condition     = self.id != null
      error_message = "Virtual network is not avaiable"
    }
  }
}

data "azurerm_subnet" "selected" {
  name = var.infrastructure.subnet != null && var.infrastructure.virtual_network != null ? var.infrastructure.subnet : azurerm_subnet.default[0].name

  virtual_network_name = data.azurerm_virtual_network.selected.name
  resource_group_name  = data.azurerm_resource_group.selected.name

  lifecycle {
    postcondition {
      condition     = self.id != null
      error_message = "Subnet is not avaiable"
    }
  }
}

data "azurerm_private_dns_zone" "selected" {
  name                = var.infrastructure.domain_suffix == null ? azurerm_private_dns_zone.default[0].name : var.infrastructure.domain_suffix
  resource_group_name = data.azurerm_resource_group.selected.name

  lifecycle {
    postcondition {
      condition     = self.id != null
      error_message = "Failed to get available private dns zone"
    }
  }
}

#
# Random
#

# create a random password for blank password input.

resource "random_password" "password" {
  length      = 16
  special     = false
  lower       = true
  min_lower   = 3
  min_upper   = 3
  min_numeric = 3
}

# create the name with a random suffix.

resource "random_string" "name_suffix" {
  length  = 10
  special = false
  upper   = false
}

#
# Deployment
#

# create server.

locals {
  name     = join("-", [local.resource_name, random_string.name_suffix.result])
  fullname = join("-", [local.namespace, local.name])
  version  = coalesce(try(split(".", var.engine_version)[0], null), "16")
  database = coalesce(var.database, "mydb")
  username = coalesce(var.username, "rdsuser")
  password = coalesce(var.password, random_password.password.result)

  replication_readonly_replicas = var.replication_readonly_replicas == 0 ? 1 : var.replication_readonly_replicas

  storage_mb = coalesce(var.storage.size, 32768)
}

resource "azurerm_postgresql_flexible_server" "primary" {
  name = local.fullname
  tags = local.tags

  resource_group_name = data.azurerm_resource_group.selected.name
  location            = data.azurerm_resource_group.selected.location

  administrator_login    = local.username
  administrator_password = local.password

  backup_retention_days = 7

  delegated_subnet_id = data.azurerm_subnet.selected.id
  private_dns_zone_id = data.azurerm_private_dns_zone.selected.id
  sku_name            = var.resources.class

  version = local.version

  storage_mb = local.storage_mb

  lifecycle {
    ignore_changes = [
      administrator_login,
      administrator_password,
    ]
  }
}

resource "azurerm_postgresql_flexible_server" "secondary" {
  count = local.architecture == "replication" ? local.replication_readonly_replicas : 0

  name = join("-", [local.fullname, "secondary", tostring(count.index)])
  tags = local.tags

  resource_group_name = data.azurerm_resource_group.selected.name
  location            = data.azurerm_resource_group.selected.location

  administrator_login    = local.username
  administrator_password = local.password

  backup_retention_days = 7

  delegated_subnet_id = data.azurerm_subnet.selected.id
  private_dns_zone_id = data.azurerm_private_dns_zone.selected.id
  sku_name            = var.resources.class

  version = local.version

  source_server_id = azurerm_postgresql_flexible_server.primary.id
  create_mode      = "Replica"

  storage_mb = local.storage_mb

  lifecycle {
    ignore_changes = [
      administrator_login,
      administrator_password,
    ]
  }

}

# create database.

resource "azurerm_postgresql_flexible_server_database" "database" {
  name      = local.database
  server_id = azurerm_postgresql_flexible_server.primary.id
  charset   = "utf8"
  collation = "en_US.utf8"

  lifecycle {
    ignore_changes = [
      name,
      charset,
      collation
    ]
  }
}
