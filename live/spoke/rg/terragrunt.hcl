include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  env_config = read_terragrunt_config(
    find_in_parent_folders("env.hcl")
  )
}

terraform {
  source = "../../../modules/rg"
}

inputs = {

  rg_setting = {
    "Spoke" = {
      name     = "RG-Terra-Spoke"
      location = include.root.locals.location
    }
  }
}