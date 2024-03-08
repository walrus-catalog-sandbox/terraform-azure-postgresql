# Azure PostgreSQL Flexible Server
Terrafom module to deploy a PostgreSQL Flexible Server on Azure Cloud.

- [x] Support standalone(one read-write instance) and replication(one read-write instance and multiple read-only instances, for read write splitting).

## Usage

```hcl
module "postgresql" {
  source = "..."

  infrastructure = {
    resource_group  = "..."
    virtual_network = "..."
    subnet          = "..."
    domain_suffix   = "..."
  }
}
```

## Examples

- [Replication](./examples/replication)
- [Standalone](./examples/standalone)

## Contributing

Please read our [contributing guide](./docs/CONTRIBUTING.md) if you're interested in contributing to Walrus template.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.88.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.88.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_postgresql_flexible_server.primary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server.secondary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_database.database](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_private_dns_zone.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_private_dns_zone.selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/private_dns_zone) | data source |
| [azurerm_resource_group.selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_architecture"></a> [architecture](#input\_architecture) | Specify the deployment architecture, select from standalone or replication. | `string` | `"standalone"` | no |
| <a name="input_context"></a> [context](#input\_context) | Receive contextual information. When Walrus deploys, Walrus will inject specific contextual information into this field.<br><br>Examples:<pre>context:<br>  project:<br>    name: string<br>    id: string<br>  environment:<br>    name: string<br>    id: string<br>  resource:<br>    name: string<br>    id: string</pre> | `map(any)` | `{}` | no |
| <a name="input_database"></a> [database](#input\_database) | Specify the database name. The database name must be 2-64 characters long and start with any lower letter, combined with number, or symbols: - \_. <br>The database name cannot be PostgreSQL forbidden keyword. | `string` | `"mydb"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Specify the deployment engine version of the PostgreSQL Flexible Server to use. Possible values are 11.0, 12.0, 13.0, 14.0, 15.0, and 16.0. | `string` | `"16.0"` | no |
| <a name="input_infrastructure"></a> [infrastructure](#input\_infrastructure) | Specify the infrastructure information for deploying.<br><br>Examples:<pre>infrastructure:<br>  resource_group: string, optional             # the resource group name where to deploy the PostgreSQL Flexible Server<br>  virtual_network: string, optional            # the virtual network name where to deploy the PostgreSQL Flexible Server<br>  subnet: string, optional                     # the subnet name under the virtual network where to deploy the PostgreSQL Flexible Server<br>  domain_suffix: string, optional              # a private DNS namespace of the PrivateZone where to register the applied PostgreSQL service. It must end with 'postgres.database.azure.com'</pre> | <pre>object({<br>    resource_group  = optional(string)<br>    virtual_network = optional(string)<br>    subnet          = optional(string)<br>    domain_suffix   = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_password"></a> [password](#input\_password) | Specify the account password. The password must be 8-32 characters long and start with any letter, number, or symbols: ! # $ % ^ & * ( ) \_ + - =.<br>If not specified, it will generate a random password. | `string` | `null` | no |
| <a name="input_replication_readonly_replicas"></a> [replication\_readonly\_replicas](#input\_replication\_readonly\_replicas) | Specify the number of read-only replicas under the replication deployment. | `number` | `1` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Specify the computing resources.<br>The computing resource design of Azure Cloud is very complex, it also needs to consider on the storage resource, please view the specification document for more information.<br>For example: B\_Standard\_B1ms, GP\_Standard\_D2s\_v3, MO\_Standard\_E4s\_v3<br>See https://docs.microsoft.com/en-us/azure/postgresql/concepts-pricing-tiers for more information.<br>Examples:<pre>resources:<br>  class: string, optional            # sku</pre> | <pre>object({<br>    class = optional(string, "B_Standard_B1ms")<br>  })</pre> | <pre>{<br>  "class": "B_Standard_B1ms"<br>}</pre> | no |
| <a name="input_storage"></a> [storage](#input\_storage) | Specify the storage resources.<br><br>Examples:<pre>storage:<br>  size: number, optional         # in megabyte</pre> | <pre>object({<br>    size = optional(number, 32768)<br>  })</pre> | <pre>{<br>  "size": 32768<br>}</pre> | no |
| <a name="input_username"></a> [username](#input\_username) | Specify the account username. The username must be 2-16 characters long and start with lower letter, combined with number.<br>The username cannot be PostgreSQL forbidden keyword and azure\_superuser, azure\_pg\_admin, admin, administrator, root, guest or public. | `string` | `"rdsuser"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address"></a> [address](#output\_address) | The address, a string only has host, might be a comma separated string or a single string. |
| <a name="output_address_readonly"></a> [address\_readonly](#output\_address\_readonly) | The readonly address, a string only has host, might be a comma separated string or a single string. |
| <a name="output_connection"></a> [connection](#output\_connection) | The connection, a string combined host and port, might be a comma separated string or a single string. |
| <a name="output_connection_readonly"></a> [connection\_readonly](#output\_connection\_readonly) | The readonly connection, a string combined host and port, might be a comma separated string or a single string. |
| <a name="output_context"></a> [context](#output\_context) | The input context, a map, which is used for orchestration. |
| <a name="output_database"></a> [database](#output\_database) | The name of PostgreSQL database to access. |
| <a name="output_password"></a> [password](#output\_password) | The password of the account to access the database. |
| <a name="output_port"></a> [port](#output\_port) | The port of the service. |
| <a name="output_refer"></a> [refer](#output\_refer) | The refer, a map, including hosts, ports and account, which is used for dependencies or collaborations. |
| <a name="output_username"></a> [username](#output\_username) | The username of the account to access the database. |
<!-- END_TF_DOCS -->