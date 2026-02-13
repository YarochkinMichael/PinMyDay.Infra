output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "webapp_default_hostname" {
  value = module.appservice.default_hostname
}
