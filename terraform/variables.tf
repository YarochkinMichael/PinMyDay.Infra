variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod"
  }
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "location_short" {
  type    = string
  default = "we"
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}

variable "vnet_cidr" {
  type = string
}

variable "subnets" {
  type = map(object({
    cidr = string
  }))
}

variable "appservice_sku" {
  type = string
}
