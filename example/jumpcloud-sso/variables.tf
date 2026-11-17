variable "region" {
  type        = string
  default     = "us-east-2"
  description = "AWS region. Must match the region of vpc_id and support WorkSpaces SAML 2.0."
}

variable "bundle_id" {
  type        = string
  description = "WorkSpaces bundle ID, e.g. the Amazon Ubuntu 26.04 LTS bundle for the region (aws workspaces describe-workspace-bundles --owner AMAZON)."
}

variable "compute_type_name" {
  type        = string
  default     = "STANDARD"
  description = "Compute type; must match the bundle. Ubuntu bundles have no VALUE size."
}

variable "vpc_id" {
  type        = string
  description = "VPC to place the directory and WorkSpaces in."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Two subnets in different AZs (WorkSpaces-supported AZ IDs). Private subnets with a NAT route, or public subnets with an IGW route and enable_internet_access = true."
}

variable "jumpcloud_sso_url" {
  type        = string
  description = "IdP URL of the JumpCloud SSO app, e.g. https://sso.jumpcloud.com/saml2/aws-workspaces."
}

variable "jumpcloud_metadata_file" {
  type        = string
  description = "Path to the IdP metadata XML exported from the JumpCloud SSO app (format: see jumpcloud-metadata.example.xml)."
}

variable "ad_password" {
  type      = string
  sensitive = true
}

variable "ip_whitelist" {
  type        = list(string)
  description = "Client CIDRs allowed to connect to WorkSpaces."
}
