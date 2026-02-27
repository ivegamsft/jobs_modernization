# Backend configuration for dev environment
# Usage: terraform init -backend-config=backend-dev.hcl

resource_group_name  = "jobsite-tfstate-rg"
storage_account_name = "jobsitetfstatedev"
container_name       = "tfstate"
key                  = "dev/terraform.tfstate"
