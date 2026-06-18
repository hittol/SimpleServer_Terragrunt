variable "location" {
  type = string
}

variable "mysql_setting" {
  type = map(object({
    managed_rg_name     = string
    sql_rg_name         = string
    sql_name            = string
    mysql_login         = string
    mysql_passwd        = string
    backup_day          = number
    dbsubnet_id         = string
    backup_grs          = bool
    dns_zone_id         = string
    mysql_sku           = string
    mysql_version       = string

    storage             = object({
      mysql_gbsize      = number
    })
  
    identity            = object({
      type              = string
    })

    high_availability = optional(object({
      mode                      = string
      standby_availability_zone = optional(string)
    }))
  }))
} 

variable "mysql_entra_login" {
  type = string
  sensitive = true
}

variable "client_id" {
  type = string
  sensitive = true
}