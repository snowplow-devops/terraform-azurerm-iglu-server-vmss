[![Release][release-image]][release] [![CI][ci-image]][ci] [![License][license-image]][license] [![Registry][registry-image]][registry] [![Source][source-image]][source]

# terraform-azurerm-iglu-server-vmss

A Terraform module which deploys a Snowplow Iglu Server application on Azure running on top of a scale-set.

## Telemetry

This module by default collects and forwards telemetry information to Snowplow to understand how our applications are being used.  No identifying information about your sub-account or account fingerprints are ever forwarded to us - it is very simple information about what modules and applications are deployed and active.

If you wish to subscribe to our mailing list for updates to these modules or security advisories please set the `user_provided_id` variable to include a valid email address which we can reach you at.

### How do I disable it?

To disable telemetry simply set variable `telemetry_enabled = false`.

### What are you collecting?

For details on what information is collected please see this module: https://github.com/snowplow-devops/terraform-snowplow-telemetry

## Usage

The Iglu Server stack requires a Load Balancer and a Postgres instance to save information into for its backend. Here we are using several managed modules to facilitate this requirement but you can also sub in your own Postgres Host and Load Balancer if you prefer to do so.

```hcl
locals {
  iglu_db_name     = "iglu"
  iglu_db_username = "iglu"

  # Keep this secret!!
  iglu_db_password = "Hell0W0rld!"

  # Used for API actions on the Iglu Server. Keep this secret!!
  iglu_super_api_key = "2f48ad70-b70c-4f58-af3b-f19d8b7706e1"
}

module "iglu_db" {
  source  = "snowplow-devops/postgresql-server/azurerm"
  version = "0.1.0"

  name                = "iglu-db"
  resource_group_name = var.resource_group_name

  subnet_id = var.subnet_id

  db_name     = local.iglu_db_name
  db_username = local.iglu_db_username
  db_password = local.iglu_db_password
}

module "iglu_lb" {
  source  = "snowplow-devops/lb/azurerm"
  version = "0.1.0"

  name                = "iglu-lb"
  resource_group_name = var.resource_group_name
  subnet_id           = var.agw_subnet_id

  probe_path = "/api/meta/health"
}

module "iglu_server" {
  source = "snowplow-devops/iglu-server-vmss/azurerm"

  name                = "iglu-server"
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  application_gateway_backend_address_pool_ids = [module.iglu_lb.agw_backend_address_pool_id]

  ingress_port = module.iglu_lb.agw_backend_egress_port

  ssh_public_key   = "your-public-key-here"
  ssh_ip_allowlist = ["0.0.0.0/0"]

  db_name     = module.iglu_db.db_name
  db_host     = module.iglu_db.db_host
  db_port     = module.iglu_db.db_port
  db_username = module.iglu_db.db_username
  db_password = module.iglu_db.db_password

  super_api_key = local.iglu_super_api_key
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.58.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.58.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_service"></a> [service](#module\_service) | snowplow-devops/service-vmss/azurerm | 0.1.0 |
| <a name="module_telemetry"></a> [telemetry](#module\_telemetry) | snowplow-devops/telemetry/snowplow | 0.5.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.egress_tcp_443](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.egress_tcp_80](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.egress_tcp_db](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.egress_udp_123](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.ingress_tcp_22](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | The hostname of the database to connect to | `string` | n/a | yes |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The name of the database to connect to | `string` | n/a | yes |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | The password to use to connect to the database | `string` | n/a | yes |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | The port the database is running on | `number` | n/a | yes |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | The username to use to connect to the database | `string` | n/a | yes |
| <a name="input_ingress_port"></a> [ingress\_port](#input\_ingress\_port) | The port that the Iglu Server will be bound to and expose over HTTP | `number` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | A name which will be pre-pended to the resources created | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group to deploy the service into | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | The SSH public key attached for access to the servers | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The subnet id to deploy the load balancer across | `string` | n/a | yes |
| <a name="input_super_api_key"></a> [super\_api\_key](#input\_super\_api\_key) | A UUIDv4 string to use as the master API key for Iglu Server management | `string` | n/a | yes |
| <a name="input_application_gateway_backend_address_pool_ids"></a> [application\_gateway\_backend\_address\_pool\_ids](#input\_application\_gateway\_backend\_address\_pool\_ids) | The ID of an Application Gateway backend address pool to bind the VM scale-set to the load balancer | `list(string)` | `[]` | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | Whether to assign a public ip address to this instance | `bool` | `true` | no |
| <a name="input_java_opts"></a> [java\_opts](#input\_java\_opts) | Custom JAVA Options | `string` | `"-Dorg.slf4j.simpleLogger.defaultLogLevel=info -XX:MinRAMPercentage=50 -XX:MaxRAMPercentage=75"` | no |
| <a name="input_patches_allowed"></a> [patches\_allowed](#input\_patches\_allowed) | Whether or not patches are allowed for published Iglu Schemas | `bool` | `true` | no |
| <a name="input_ssh_ip_allowlist"></a> [ssh\_ip\_allowlist](#input\_ssh\_ip\_allowlist) | The comma-seperated list of CIDR ranges to allow SSH traffic from | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to append to this resource | `map(string)` | `{}` | no |
| <a name="input_telemetry_enabled"></a> [telemetry\_enabled](#input\_telemetry\_enabled) | Whether or not to send telemetry information back to Snowplow Analytics Ltd | `bool` | `true` | no |
| <a name="input_user_provided_id"></a> [user\_provided\_id](#input\_user\_provided\_id) | An optional unique identifier to identify the telemetry events emitted by this stack | `string` | `""` | no |
| <a name="input_vm_instance_count"></a> [vm\_instance\_count](#input\_vm\_instance\_count) | The instance count to use | `number` | `1` | no |
| <a name="input_vm_sku"></a> [vm\_sku](#input\_vm\_sku) | The instance type to use | `string` | `"Standard_B1ms"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nsg_id"></a> [nsg\_id](#output\_nsg\_id) | ID of the network security group attached to the Iglu Server nodes |
| <a name="output_vmss_id"></a> [vmss\_id](#output\_vmss\_id) | ID of the VM scale-set |

# Copyright and license

The Terraform Azurerm Iglu Server on VMSS project is Copyright 2023-present Snowplow Analytics Ltd.

Licensed under the [Apache License, Version 2.0][license] (the "License");
you may not use this software except in compliance with the License.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

[release]: https://github.com/snowplow-devops/terraform-azurerm-iglu-server-vmss/releases/latest
[release-image]: https://img.shields.io/github/v/release/snowplow-devops/terraform-azurerm-iglu-server-vmss

[ci]: https://github.com/snowplow-devops/terraform-azurerm-iglu-server-vmss/actions?query=workflow%3Aci
[ci-image]: https://github.com/snowplow-devops/terraform-azurerm-iglu-server-vmss/workflows/ci/badge.svg

[license]: https://www.apache.org/licenses/LICENSE-2.0
[license-image]: https://img.shields.io/badge/license-Apache--2-blue.svg?style=flat

[registry]: https://registry.terraform.io/modules/snowplow-devops/iglu-server-vmss/azurerm/latest
[registry-image]: https://img.shields.io/static/v1?label=Terraform&message=Registry&color=7B42BC&logo=terraform

[source]: https://github.com/snowplow-incubator/iglu-server
[source-image]: https://img.shields.io/static/v1?label=Snowplow&message=Iglu%20Server&color=0E9BA4&logo=GitHub
