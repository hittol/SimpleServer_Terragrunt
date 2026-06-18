variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "natgw_name" {
  type = string
}

variable "subnet_ids" {
  description = "Subnet IDs to associate with the NAT Gateway."
  type        = map(string)
  default     = {}
}



