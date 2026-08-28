variable "resource_group_name" {
  type        = string
  description = "Tên của Azure Resource Group"
  default     = "rg-ansible-terraform-demo"
}

variable "location" {
  type        = string
  description = "Vị trí địa lý triển khai tài nguyên"
  default     = "East US"
}
