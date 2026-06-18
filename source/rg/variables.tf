variable "rg_setting" {
  type = map(object({
    location = optional(string, "koreacentral")
    name     = string
  }))
} 