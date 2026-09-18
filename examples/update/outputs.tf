output "server_id" {
  description = "The ID of the server created by the example."
  value       = module.compute.server_id
}

output "update_enabled" {
  description = "Whether the server update service is enabled."
  value       = module.compute.update_enabled
}
