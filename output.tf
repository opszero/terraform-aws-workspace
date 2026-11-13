# outputs of aws workspaces directory id
output "ad_id" {
  value       = join("", aws_workspaces_directory.main[*].id)
  description = "The concatenated ID(s) of the main AWS WorkSpaces directory, combining multiple IDs into a single string."
}

# Output for the Directory Service
output "directory_service_id" {
  value       = aws_directory_service_directory.main.id
  description = "The ID of the Directory Service"
}

# Output for the WorkSpaces IP Group
output "workspaces_ip_group_id" {
  value       = aws_workspaces_ip_group.ipgroup.id
  description = "The ID of the WorkSpaces IP Group"
}

# Output for the WorkSpaces Directory
output "workspaces_directory_id" {
  value       = aws_workspaces_directory.main.id
  description = "The ID of the WorkSpaces Directory"
}

output "directory_name" {
  value       = aws_directory_service_directory.main.name
  description = "The name of the created Directory Service Directory."
}

output "directory_dns_ip_addresses" {
  value       = aws_directory_service_directory.main.dns_ip_addresses
  description = "The DNS IP addresses of the created Directory Service Directory."
}

output "directory_id" {
  value       = join(", ", aws_workspaces_directory.main[*].id)
  description = "The ID of the created WorkSpaces directory."
}

output "saml_status" {
  value       = aws_workspaces_directory.main.saml_properties[0].status
  description = "The status of SAML 2.0 authentication."
}

output "user_access_url" {
  value       = aws_workspaces_directory.main.saml_properties[0].user_access_url
  description = "The user access URL for the SAML 2.0 identity provider (IdP)."
}

output "saml_provider_arn" {
  value       = try(aws_iam_saml_provider.workspaces[0].arn, null)
  description = "ARN of the IAM SAML provider, if SSO is configured."
}

output "saml_role_arn" {
  value       = try(aws_iam_role.saml[0].arn, null)
  description = "ARN of the WorkSpaces SAML federation role, if SSO is configured."
}

output "saml_role_attribute" {
  value       = try("${aws_iam_role.saml[0].arn},${aws_iam_saml_provider.workspaces[0].arn}", null)
  description = "Value for the IdP attribute https://aws.amazon.com/SAML/Attributes/Role (role ARN,provider ARN)."
}

output "registration_code" {
  value       = aws_workspaces_directory.main.registration_code
  description = "WorkSpaces directory registration code."
}

output "saml_relay_state" {
  value       = "https://workspaces.euc-sso.${data.aws_region.current.region}.aws.amazon.com/sso-idp?registrationCode=${aws_workspaces_directory.main.registration_code}"
  description = "Relay state URL to configure in the IdP (JumpCloud) SSO app."
}
