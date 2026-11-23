variable "env" {
  type    = string
  default = "dev"
}

output "env" {
  value = var.env
}
