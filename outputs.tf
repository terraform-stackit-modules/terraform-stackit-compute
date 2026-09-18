output "server_id" {
  description = "The ID of the created server (null when create_server is false)."
  value       = var.create_server ? stackit_server.this[0].server_id : null
}

output "server_name" {
  description = "The name of the created server (null when create_server is false)."
  value       = var.create_server ? stackit_server.this[0].name : null
}

output "keypair_name" {
  description = "The name of the key pair used by the server (created or provided)."
  value       = var.create_key_pair ? stackit_key_pair.this[0].name : var.keypair_name
}

output "keypair_fingerprint" {
  description = "The fingerprint of the created key pair (null when no key pair is created)."
  value       = var.create_key_pair ? stackit_key_pair.this[0].fingerprint : null
}

output "public_ips" {
  description = "Map of public IP key to allocated IP address."
  value       = { for k, pip in stackit_public_ip.this : k => pip.ip }
}

output "public_ip_ids" {
  description = "Map of public IP key to public IP ID."
  value       = { for k, pip in stackit_public_ip.this : k => pip.public_ip_id }
}

output "network_interface_ids" {
  description = "Map of network interface key to created network interface ID."
  value       = { for k, nic in stackit_network_interface.this : k => nic.network_interface_id }
}

output "network_interface_ipv4s" {
  description = "Map of network interface key to its IPv4 address."
  value       = { for k, nic in stackit_network_interface.this : k => nic.ipv4 }
}

output "backup_enabled" {
  description = "Whether the server backup service is enabled (null when not managed by this module)."
  value       = var.create_server && var.enable_backup ? stackit_server_backup_enable.this[0].enabled : null
}

output "backup_schedule_ids" {
  description = "Map of backup schedule key to backup schedule ID."
  value       = { for k, s in stackit_server_backup_schedule.this : k => s.backup_schedule_id }
}

output "update_enabled" {
  description = "Whether the server update service is enabled (null when not managed by this module)."
  value       = var.create_server && var.enable_update ? stackit_server_update_enable.this[0].enabled : null
}

output "service_account_attachment_ids" {
  description = "Map of service account key to its attachment resource ID."
  value       = { for k, a in stackit_server_service_account_attach.this : k => a.id }
}
