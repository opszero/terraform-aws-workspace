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
