output "resource_group_id" {
  value       = azurerm_resource_group.demo.id
  description = "ID của Resource Group được tạo ra"
}

output "resource_group_name" {
  value       = azurerm_resource_group.demo.name
  description = "Tên của Resource Group"
}

output "vnet_name" {
  value       = azurerm_virtual_network.demo.name
  description = "Tên của Virtual Network"
}
