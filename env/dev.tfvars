environment     = "dev"
location        = "westeurope"
location_short  = "we"
extra_tags = {
  costCenter = "dev"
}

vnet_cidr = "10.10.0.0/16"
subnets = {
  front = { cidr = "10.10.1.0/24" }
  back  = { cidr = "10.10.2.0/24" }
  db    = { cidr = "10.10.3.0/24" }
}
appservice_sku = "B1"
