output "server_id" {
  description = "The ID of the server created by the example."
  value       = module.compute.server_id
}

output "service_account_email" {
  description = "The email of the service account created and attached to the server."
  value       = stackit_service_account.ci.email
}

output "service_account_attachment_ids" {
  description = "Map of service account key to attachment resource ID."
  value       = module.compute.service_account_attachment_ids
}
