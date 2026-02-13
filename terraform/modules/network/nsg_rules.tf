# FRONT: allow inbound from Internet only on 80/443
resource "azurerm_network_security_rule" "front_allow_http_https" {
  name                        = "allow-http-https"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.this["front"].name
}

# FRONT: deny everything else inbound (this overrides default AllowVnetInBound)
resource "azurerm_network_security_rule" "front_deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.this["front"].name
}

# BACK: allow inbound only from FRONT subnet (any port for now)
resource "azurerm_network_security_rule" "back_allow_from_front" {
  name                        = "allow-from-front"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.subnets["front"].cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.this["back"].name
}

# BACK: deny everything else inbound
resource "azurerm_network_security_rule" "back_deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.this["back"].name
}

# DB: allow inbound only from BACK subnet on PostgreSQL port (5432)
resource "azurerm_network_security_rule" "db_allow_postgres_from_back" {
  name                        = "allow-postgres-from-back"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = var.subnets["back"].cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.this["db"].name
}

# DB: deny everything else inbound
resource "azurerm_network_security_rule" "db_deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.this["db"].name
}