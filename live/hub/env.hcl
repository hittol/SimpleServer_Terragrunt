locals {
  environment = "hub"

  common_tags = {
    Environment = "hub"
    Project     = "SimpleArchi"
    ManagedBy   = "Terragrunt"
  }
}