resource "azurerm_service_plan" "this" {
  name                = "asp-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.rg_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = "app-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.rg_name
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true
  tags                = var.tags

  site_config {
    always_on = true
  }
}
