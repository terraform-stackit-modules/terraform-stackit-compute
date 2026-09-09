output "server_id" {
  description = "The ID of the server created by the example."
  value       = module.compute.server_id
}

output "server_name" {
  description = "The name of the server created by the example."
  value       = module.compute.server_name
}

output "keypair_name" {
  description = "The name of the key pair used by the example server."
  value       = module.compute.keypair_name
}

output "network_id" {
  description = "The ID of the network created for the example."
  value       = module.network.network_id
}

output "network_interface_ids" {
  description = "The network interface IDs created by the compute module."
  value       = module.compute.network_interface_ids
}
