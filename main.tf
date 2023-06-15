locals {
  module_name    = "iglu-server-vmss"
  module_version = "0.1.0"

  app_name    = "iglu-server"
  app_version = "0.10.0"

  local_tags = {
    Name           = var.name
    app_name       = local.app_name
    app_version    = local.app_version
    module_name    = local.module_name
    module_version = local.module_version
  }

  tags = merge(
    var.tags,
    local.local_tags
  )
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

module "telemetry" {
  source  = "snowplow-devops/telemetry/snowplow"
  version = "0.5.0"

  count = var.telemetry_enabled ? 1 : 0

  user_provided_id = var.user_provided_id
  cloud            = "AZURE"
  region           = data.azurerm_resource_group.rg.location
  app_name         = local.app_name
  app_version      = local.app_version
  module_name      = local.module_name
  module_version   = local.module_version
}

# --- Network: Security Group Rules

resource "azurerm_network_security_group" "nsg" {
  name                = var.name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_network_security_rule" "ingress_tcp_22" {
  name                        = "${var.name}_ingress_tcp_22"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.ssh_ip_allowlist
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "egress_tcp_80" {
  name                        = "${var.name}_egress_tcp_80"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "egress_tcp_443" {
  name                        = "${var.name}_egress_tcp_443"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "egress_tcp_db" {
  name                        = "${var.name}_egress_tcp_db"
  priority                    = 102
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = var.db_port
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Needed for clock synchronization
resource "azurerm_network_security_rule" "egress_udp_123" {
  name                        = "${var.name}_egress_udp_123"
  priority                    = 103
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "123"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# --- Compute: VM scale-set deployment

locals {
  iglu_server_hocon = templatefile("${path.module}/templates/config.hocon.tmpl", {
    port            = var.ingress_port
    db_host         = var.db_host
    db_port         = var.db_port
    db_name         = var.db_name
    db_username     = var.db_username
    db_password     = var.db_password
    patches_allowed = var.patches_allowed
    super_api_key   = lower(var.super_api_key)
  })

  user_data = templatefile("${path.module}/templates/user-data.sh.tmpl", {
    port    = var.ingress_port
    config  = local.iglu_server_hocon
    version = local.app_version

    telemetry_script = join("", module.telemetry.*.azurerm_ubuntu_22_04_user_data)

    java_opts = var.java_opts
  })
}

module "service" {
  source  = "snowplow-devops/service-vmss/azurerm"
  version = "0.1.0"

  user_supplied_script = local.user_data
  name                 = var.name
  resource_group_name  = var.resource_group_name

  subnet_id                   = var.subnet_id
  network_security_group_id   = azurerm_network_security_group.nsg.id
  associate_public_ip_address = var.associate_public_ip_address
  admin_ssh_public_key        = var.ssh_public_key

  sku            = var.vm_sku
  instance_count = var.vm_instance_count

  application_gateway_backend_address_pool_ids = var.application_gateway_backend_address_pool_ids

  tags = local.tags
}
