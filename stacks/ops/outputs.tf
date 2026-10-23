output "oncall_schedule" {
  description = "Primary on-call schedule."
  value       = terraform_data.oncall_schedule.output.name
}

output "alert_rules" {
  description = "Alert rules and their thresholds."
  value       = { for name, rule in terraform_data.alert_rule : name => "${rule.output.threshold} ${rule.output.unit}" }
}

output "runbook_path" {
  description = "Where the on-call runbook was rendered."
  value       = local_file.runbook.filename
}
