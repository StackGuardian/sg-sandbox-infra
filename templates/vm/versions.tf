# Mock template: every resource is terraform_data, so nothing is created in any
# cloud and no provider or cloud connector is needed. State is managed by
# StackGuardian, so there is no backend block.
terraform {
  required_version = ">= 1.5.7"
}
