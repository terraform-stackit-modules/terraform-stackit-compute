output "server_id" {
  description = "The ID of the server created by the example."
  value       = module.compute.server_id
}

output "backup_enabled" {
  description = "Whether the server backup service is enabled."
  value       = module.compute.backup_enabled
}

output "backup_schedule_ids" {
  description = "The backup schedule IDs created by the example."
  value       = module.compute.backup_schedule_ids
}
