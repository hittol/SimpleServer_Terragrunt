locals {
  environment = "spoke"

  common_tags = {
    Environment = "spoke"
    Project     = "SimpleArchi"
    ManagedBy   = "Terragrunt"
  }
}