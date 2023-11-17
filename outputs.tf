output "context" {
  description = "The input context, a map, which is used for orchestration."
  value       = var.context
}

output "selector" {
  description = "The selector, a map, which is used for dependencies or collaborations."
  value       = local.tags
}

output "endpoint_internal" {
  description = "The internal endpoints, a string list, which are used for internal access."
  value       = [format("%s.%s:3306", alicloud_pvtz_zone_record.primary.rr, var.infrastructure.domain_suffix)]
}

output "endpoint_internal_readonly" {
  description = "The internal readonly endpoints, a string list, which are used for internal readonly access."
  value       = local.architecture == "replication" ? [for c in alicloud_pvtz_zone_record.secondary : format("%s.%s:3306", c.rr, var.infrastructure.domain_suffix)] : []
}

output "database" {
  description = "The name of database to access."
  value       = var.database
}

output "username" {
  description = "The username of the account to access the database."
  value       = var.username
}

output "password" {
  description = "The password of the account to access the database."
  value       = local.password
  sensitive   = true
}