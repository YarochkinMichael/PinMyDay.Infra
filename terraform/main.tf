resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = local.location
  tags     = local.tags
}

module "network" {
  source      = "./modules/network"
  name_prefix = local.name_prefix
  location    = local.location
  rg_name     = azurerm_resource_group.main.name
  tags        = local.tags

  vnet_cidr = var.vnet_cidr
  subnets   = var.subnets
}

module "appservice" {
  source      = "./modules/appservice"
  name_prefix = local.name_prefix
  location    = local.location
  rg_name     = azurerm_resource_group.main.name
  tags        = local.tags

  sku_name = var.appservice_sku
}
