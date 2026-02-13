locals {
  project     = "pmd"
  location    = var.location
  location_sh = var.location_short # e.g. "we"
  env         = var.environment    # "dev" | "prod"

  name_prefix = "${local.project}-${local.env}-${local.location_sh}"

  tags = merge({
    project     = "PinMyDay"
    env         = local.env
    managedBy   = "terraform"
    location    = local.location
  }, var.extra_tags)
}
