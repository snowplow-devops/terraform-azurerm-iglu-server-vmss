resource "azurerm_resource_group" "rg" {
  name     = "${var.name}-rg"
  location = "North Europe"
}

module "vnet" {
  source  = "snowplow-devops/vnet/azurerm"
  version = "0.1.2"

  name                = "${var.name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [azurerm_resource_group.rg]
}

module "snowplow_db" {
  source  = "snowplow-devops/postgresql-server/azurerm"
  version = "0.1.1"

  name                = "${var.name}-iglu-db"
  resource_group_name = azurerm_resource_group.rg.name

  subnet_id = lookup(module.vnet.vnet_subnets_name_id, "iglu1")

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  depends_on  = [azurerm_resource_group.rg]
}

module "iglu_server_lb" {
  source  = "snowplow-devops/lb/azurerm"
  version = "0.2.0"

  name                = "${var.name}-clb"
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = lookup(module.vnet.vnet_subnets_name_id, "iglu-agw1")

  probe_path = "/api/meta/health"

  depends_on = [azurerm_resource_group.rg]
}

module "iglu_server" {
  source = "../.."

  accept_limited_use_license = true

  name                = "${var.name}-iglu-server"
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = lookup(module.vnet.vnet_subnets_name_id, "iglu1")

  application_gateway_backend_address_pool_ids = [module.iglu_server_lb.agw_backend_address_pool_id]

  ingress_port = module.iglu_server_lb.agw_backend_egress_port

  db_host       = module.snowplow_db.db_host
  db_port       = module.snowplow_db.db_port
  db_name       = module.snowplow_db.db_name
  db_username   = module.snowplow_db.db_username
  db_password   = module.snowplow_db.db_password
  super_api_key = var.iglu_super_api_key

  ssh_public_key   = var.ssh_public_key
  ssh_ip_allowlist = ["0.0.0.0/0"]

  user_provided_id = var.user_provided_id

  depends_on = [azurerm_resource_group.rg, module.snowplow_db]
}

output "iglu_server_lb_fqdn" {
  value = module.iglu_server_lb.ip_address_fqdn
}
