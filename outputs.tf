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
