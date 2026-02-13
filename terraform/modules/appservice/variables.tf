variable "name_prefix" { type = string }
variable "location"    { type = string }
variable "rg_name"     { type = string }
variable "tags"        { type = map(string) }

variable "sku_name"    { type = string } # e.g. "P1v3" prod, "B1" dev
