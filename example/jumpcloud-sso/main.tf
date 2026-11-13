provider "aws" {
  region = "us-east-1"
}

module "workspace" {
  source = "../../"
  name   = "workspace"

  subnet_ids = var.private_subnet_ids

  vpc_settings = {
    vpc_id     = var.vpc_id
    subnet_ids = join(",", var.private_subnet_ids)
  }

  ad_name     = "corp.example.com"
  ad_password = var.ad_password

  # JumpCloud SAML 2.0 SSO
  saml_metadata_document     = file(var.jumpcloud_metadata_file)
  user_access_url            = var.jumpcloud_sso_url
  relay_state_parameter_name = "RelayState"
  status                     = "ENABLED_WITH_DIRECTORY_LOGIN_FALLBACK"

  enable_workspace = true
  workspaces = {
    jdoe = {
      # Must match the NameID JumpCloud sends (the JumpCloud username).
      user_name = "jdoe"
      bundle_id = "wsb-208l8k46h"
    }
  }
}

output "saml_relay_state" {
  value = module.workspace.saml_relay_state
}

output "saml_role_attribute" {
  value = module.workspace.saml_role_attribute
}
