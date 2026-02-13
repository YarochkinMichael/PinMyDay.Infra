variable "name_prefix" { type = string }
variable "location"    { type = string }
variable "rg_name"     { type = string }
variable "tags"        { type = map(string) }

variable "vnet_cidr" {
  type = string
}

variable "subnets" {
  description = "Subnets map. Must contain keys: front, back, db"
  type = map(object({
    cidr = string
  }))

  validation {
    condition = (
    contains(keys(var.subnets), "front") &&
    contains(keys(var.subnets), "back")  &&
    contains(keys(var.subnets), "db")
    )
    error_message = "subnets must include keys: front, back, db."
  }
}
