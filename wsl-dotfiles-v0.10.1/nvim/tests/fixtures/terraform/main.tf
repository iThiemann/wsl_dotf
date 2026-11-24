terraform {
  required_version = ">= 1.6"
}

variable "name" {
  type    = string
  default = "demo"
}

output "greeting" {
  value = "hello ${var.name}"
}
