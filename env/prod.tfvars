environment     = "prod"
location        = "westeurope"
location_short  = "we"
extra_tags = {
  costCenter = "prod"
}

vnet_cidr = "10.20.0.0/16"
subnets = {
  app      = { cidr = "10.20.1.0/24" }
  appsvc   = { cidr = "10.20.2.0/24" }
}
appservice_sku = "P1v3"
