resource "azurerm_network_security_group" "this" {
  for_each            = var.subnets
  name                = "nsg-${var.name_prefix}-${each.key}"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

# Attach each NSG to its subnet
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = var.subnets
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
