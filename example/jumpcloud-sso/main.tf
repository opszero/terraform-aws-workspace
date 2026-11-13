provider "aws" {
  region = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "VPC to place the directory and WorkSpaces in."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Two private subnets in different AZs."
}

variable "jumpcloud_sso_url" {
  type        = string
  description = "IdP URL of the JumpCloud SSO app, e.g. https://sso.jumpcloud.com/saml2/aws-workspaces."
}

variable "jumpcloud_metadata_file" {
  type        = string
  description = "Path to the IdP metadata XML exported from the JumpCloud SSO app."
}

variable "ad_password" {
  type      = string
  sensitive = true
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
