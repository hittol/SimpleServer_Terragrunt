# root.hcl
# 모든 live 하위 terragrunt.hcl에서 include 하는 공통 설정입니다.


generate "provider" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOT
terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {  
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.14.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}
EOT
}

remote_state {
  backend = "azurerm"

  generate = {
  // 생성할 파일 이름
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }  

  config = {
    resource_group_name  = "RG-TFSTATE"
    storage_account_name = "wrtfstate001"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"

    use_azuread_auth     = true
  }
}

locals {
  location = "koreacentral"
}