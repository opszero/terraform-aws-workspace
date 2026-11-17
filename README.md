<!-- BEGIN_TF_DOCS -->
# terraform-aws-workspace

Creates an AWS Directory Service directory, registers it with Amazon WorkSpaces, and optionally provisions WorkSpaces and SAML 2.0 single sign-on (for example, JumpCloud).

## Usage

```hcl
module "workspace" {
  source = "github.com/opszero/terraform-aws-workspace"
  name   = "workspace"

  subnet_ids = module.subnets.private_subnet_id
  vpc_settings = {
    vpc_id     = module.vpc.id
    subnet_ids = join(",", module.subnets.private_subnet_id)
  }

  ad_name     = "corp.example.com"
  ad_password = var.ad_password

  enable_workspace = true
  workspaces = {
    workspace1 = {
      user_name = "admin"
      bundle_id = "wsb-208l8k46h"
    }
  }
}
```

Run the first `apply` with `enable_workspace = false`, create the users in the directory, then set `enable_workspace = true` and apply again.

## JumpCloud SSO

See [`example/jumpcloud-sso`](example/jumpcloud-sso).

1. **JumpCloud:** go to *SSO Applications → Add New Application → Custom SAML App* (or the *Amazon WorkSpaces* connector). Set:
   - IdP Entity ID: any unique value, for example `jumpcloud-workspaces`
   - SP Entity ID: `urn:amazon:webservices`
   - ACS URL: `https://signin.aws.amazon.com/saml`
   - SAMLSubject NameID: `username`, format `urn:oasis:names:tc:SAML:2.0:nameid-format:persistent`
   - IdP URL: for example `https://sso.jumpcloud.com/saml2/aws-workspaces` (this becomes `user_access_url`)

   Save the app and export its **IdP metadata** XML (see [`example/jumpcloud-sso/jumpcloud-metadata.example.xml`](example/jumpcloud-sso/jumpcloud-metadata.example.xml) for the expected format).
2. **Terraform:** pass the metadata as `saml_metadata_document`, set `user_access_url` and `status` (`ENABLED`, or `ENABLED_WITH_DIRECTORY_LOGIN_FALLBACK` while you roll it out), then apply.
3. **JumpCloud:** finish the app configuration using the Terraform outputs:
   - Default RelayState: the `saml_relay_state` output
   - Attribute `https://aws.amazon.com/SAML/Attributes/Role`: the `saml_role_attribute` output
   - Attribute `https://aws.amazon.com/SAML/Attributes/RoleSessionName`: `username`
   - Attribute `https://aws.amazon.com/SAML/Attributes/PrincipalTag:Email`: `email`
   - Assign the JumpCloud user groups that should have access.
4. In the WorkSpaces client, register with the directory's `registration_code`. Users are sent to JumpCloud to sign in. Each user's JumpCloud username must match the `user_name` of their WorkSpace.
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.58.0 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ad_name"></a> [ad\_name](#input\_ad\_name) | The fully qualified name for the directory, such as corp.example.com | `string` | `"corp.example.com"` | no |
| <a name="input_ad_password"></a> [ad\_password](#input\_ad\_password) | The password for the directory administrator or connector user. | `string` | `"xyzsf58f5fqar"` | no |
| <a name="input_ad_size"></a> [ad\_size](#input\_ad\_size) | The size of the directory (Small or Large are accepted values). | `string` | `"Small"` | no |
| <a name="input_alias"></a> [alias](#input\_alias) | The directory type (SimpleAD, ADConnector or MicrosoftAD are accepted values). | `string` | `""` | no |
| <a name="input_change_compute_type"></a> [change\_compute\_type](#input\_change\_compute\_type) | Whether WorkSpaces directory users can change the compute type (bundle) for their workspace. | `bool` | `true` | no |
| <a name="input_connect_settings"></a> [connect\_settings](#input\_connect\_settings) | (Required for ADConnector) Connector related information about the directory. Fields documented below. | `map(string)` | `{}` | no |
| <a name="input_custom_policy"></a> [custom\_policy](#input\_custom\_policy) | Custom policy ARN | `string` | `""` | no |
| <a name="input_description"></a> [description](#input\_description) | A textual description for the directory. | `string` | `"Workspace Active Directory"` | no |
| <a name="input_device_type_android"></a> [device\_type\_android](#input\_device\_type\_android) | Indicates whether users can use Android devices to access their WorkSpaces. | `string` | `"ALLOW"` | no |
| <a name="input_device_type_chromeos"></a> [device\_type\_chromeos](#input\_device\_type\_chromeos) | Indicates whether users can use Chromebooks to access their WorkSpaces. | `string` | `"ALLOW"` | no |
| <a name="input_device_type_ios"></a> [device\_type\_ios](#input\_device\_type\_ios) | Indicates whether users can use iOS devices to access their WorkSpaces. | `string` | `"ALLOW"` | no |
| <a name="input_device_type_linux"></a> [device\_type\_linux](#input\_device\_type\_linux) | Indicates whether users can use Linux devices to access their WorkSpaces. | `string` | `"ALLOW"` | no |
| <a name="input_device_type_osx"></a> [device\_type\_osx](#input\_device\_type\_osx) | Indicates whether users can use macOS clients to access their WorkSpaces. | `string` | `"ALLOW"` | no |
| <a name="input_device_type_web"></a> [device\_type\_web](#input\_device\_type\_web) | Indicates whether users can access their WorkSpaces through a web browser. | `string` | `"ALLOW"` | no |
| <a name="input_device_type_windows"></a> [device\_type\_windows](#input\_device\_type\_windows) | Indicates whether users can use Windows clients to access their WorkSpaces. | `string` | `"ALLOW"` | no |
| <a name="input_device_type_zeroclient"></a> [device\_type\_zeroclient](#input\_device\_type\_zeroclient) | Indicates whether users can use zero client devices to access their WorkSpaces. | `string` | `"ALLOW"` | no |
| <a name="input_edition"></a> [edition](#input\_edition) | The MicrosoftAD edition (Standard or Enterprise). | `string` | `"Standard"` | no |
| <a name="input_enable_internet_access"></a> [enable\_internet\_access](#input\_enable\_internet\_access) | (optional) Whether workspace virtual desktops should have internet access. Note that a VPC internet gateway is not required. | `bool` | `true` | no |
| <a name="input_enable_maintenance_mode"></a> [enable\_maintenance\_mode](#input\_enable\_maintenance\_mode) | Indicates whether maintenance mode is enabled for your WorkSpaces. | `bool` | `true` | no |
| <a name="input_enable_sso"></a> [enable\_sso](#input\_enable\_sso) | Whether to enable single-sign on for the directory. Requires alias. | `bool` | `false` | no |
| <a name="input_enable_workspace"></a> [enable\_workspace](#input\_enable\_workspace) | Flag to control the module creation. | `bool` | `false` | no |
| <a name="input_force_detach_policies"></a> [force\_detach\_policies](#input\_force\_detach\_policies) | Whether to force detaching any policies the role has before destroying it. | `bool` | `false` | no |
| <a name="input_increase_volume_size"></a> [increase\_volume\_size](#input\_increase\_volume\_size) | Whether WorkSpaces directory users can increase the volume size of the drives on their workspace. | `bool` | `true` | no |
| <a name="input_ip_whitelist"></a> [ip\_whitelist](#input\_ip\_whitelist) | List of IP's to for whitelist | `list(string)` | <pre>[<br/>  "103.59.207.249/32"<br/>]</pre> | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration (in seconds) for the specified role. | `number` | `3600` | no |
| <a name="input_name"></a> [name](#input\_name) | Name  (e.g. `app` or `cluster`). | `string` | `""` | no |
| <a name="input_path"></a> [path](#input\_path) | Path to the role. | `string` | `"/"` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the role. | `string` | `""` | no |
| <a name="input_rebuild_workspace"></a> [rebuild\_workspace](#input\_rebuild\_workspace) | Whether WorkSpaces directory users can rebuild the operating system of a workspace to its original state. | `bool` | `true` | no |
| <a name="input_relay_state_parameter_name"></a> [relay\_state\_parameter\_name](#input\_relay\_state\_parameter\_name) | The relay state parameter name supported by the SAML 2.0 identity provider (IdP). | `string` | `"RelayState"` | no |
| <a name="input_restart_workspace"></a> [restart\_workspace](#input\_restart\_workspace) | Whether WorkSpaces directory users can restart their workspace. | `bool` | `true` | no |
| <a name="input_saml_metadata_document"></a> [saml\_metadata\_document](#input\_saml\_metadata\_document) | SAML IdP metadata XML (e.g. downloaded from the JumpCloud SSO app). When set, an IAM SAML provider and a federation role for WorkSpaces are created. | `string` | `null` | no |
| <a name="input_saml_name_id_format"></a> [saml\_name\_id\_format](#input\_saml\_name\_id\_format) | Expected SAML NameID format (SAML:sub\_type) in the role trust policy. Configure the IdP to send this format; the NameID value must match the WorkSpaces user name. | `string` | `"persistent"` | no |
| <a name="input_saml_provider_name"></a> [saml\_provider\_name](#input\_saml\_provider\_name) | Name for the IAM SAML provider and federation role. Defaults to "<name>-workspaces-saml". | `string` | `null` | no |
| <a name="input_short_name"></a> [short\_name](#input\_short\_name) | The short name of the directory, such as CORP. | `string` | `"CORP"` | no |
| <a name="input_status"></a> [status](#input\_status) | Status of SAML 2.0 authentication: DISABLED, ENABLED (SSO only) or ENABLED\_WITH\_DIRECTORY\_LOGIN\_FALLBACK (SSO plus directory username/password). | `string` | `"DISABLED"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | VPC Subnet IDs to create workspaces in | `list(string)` | n/a | yes |
| <a name="input_switch_running_mode"></a> [switch\_running\_mode](#input\_switch\_running\_mode) | Whether WorkSpaces directory users can switch the running mode of their workspace. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | The directory type (SimpleAD, ADConnector or MicrosoftAD are accepted values). | `string` | `"SimpleAD"` | no |
| <a name="input_user_access_url"></a> [user\_access\_url](#input\_user\_access\_url) | The SAML 2.0 identity provider (IdP) user access URL. For JumpCloud this is the IdP URL of the WorkSpaces SSO app, e.g. https://sso.jumpcloud.com/saml2/<app-slug>. | `string` | `"https://idp.example.com/saml"` | no |
| <a name="input_user_enabled_as_local_administrator"></a> [user\_enabled\_as\_local\_administrator](#input\_user\_enabled\_as\_local\_administrator) | Indicates whether users are local administrators of their WorkSpaces. | `bool` | `true` | no |
| <a name="input_vpc_settings"></a> [vpc\_settings](#input\_vpc\_settings) | (Required for SimpleAD and MicrosoftAD) VPC related information about the directory. Fields documented below. | `map(string)` | `{}` | no |
| <a name="input_workspaces"></a> [workspaces](#input\_workspaces) | Map of workspace configurations. | <pre>map(object({<br/>    user_name                                 = string<br/>    bundle_id                                 = string<br/>    root_volume_encryption_enabled            = optional(bool, false)<br/>    user_volume_encryption_enabled            = optional(bool, false)<br/>    volume_encryption_key                     = optional(string, null)<br/>    compute_type_name                         = optional(string, "VALUE")<br/>    user_volume_size_gib                      = optional(number, 10)<br/>    root_volume_size_gib                      = optional(number, 80)<br/>    running_mode                              = optional(string, "AUTO_STOP")<br/>    running_mode_auto_stop_timeout_in_minutes = optional(number, 60)<br/>  }))</pre> | `{}` | no |
## Resources

| Name | Type |
|------|------|
| [aws_directory_service_directory.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/directory_service_directory) | resource |
| [aws_iam_role.saml](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.workspaces_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.saml_stream](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.workspaces_custom_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.workspaces_default_self_service_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.workspaces_default_service_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_saml_provider.workspaces](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_saml_provider) | resource |
| [aws_workspaces_directory.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/workspaces_directory) | resource |
| [aws_workspaces_ip_group.ipgroup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/workspaces_ip_group) | resource |
| [aws_workspaces_workspace.workspace_ad](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/workspaces_workspace) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.saml_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.saml_stream](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.workspaces](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_workspaces_bundle.bundle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/workspaces_bundle) | data source |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ad_id"></a> [ad\_id](#output\_ad\_id) | The concatenated ID(s) of the main AWS WorkSpaces directory, combining multiple IDs into a single string. |
| <a name="output_directory_dns_ip_addresses"></a> [directory\_dns\_ip\_addresses](#output\_directory\_dns\_ip\_addresses) | The DNS IP addresses of the created Directory Service Directory. |
| <a name="output_directory_id"></a> [directory\_id](#output\_directory\_id) | The ID of the created WorkSpaces directory. |
| <a name="output_directory_name"></a> [directory\_name](#output\_directory\_name) | The name of the created Directory Service Directory. |
| <a name="output_directory_service_id"></a> [directory\_service\_id](#output\_directory\_service\_id) | The ID of the Directory Service |
| <a name="output_registration_code"></a> [registration\_code](#output\_registration\_code) | WorkSpaces directory registration code. |
| <a name="output_saml_provider_arn"></a> [saml\_provider\_arn](#output\_saml\_provider\_arn) | ARN of the IAM SAML provider, if SSO is configured. |
| <a name="output_saml_relay_state"></a> [saml\_relay\_state](#output\_saml\_relay\_state) | Relay state URL to configure in the IdP (JumpCloud) SSO app. |
| <a name="output_saml_role_arn"></a> [saml\_role\_arn](#output\_saml\_role\_arn) | ARN of the WorkSpaces SAML federation role, if SSO is configured. |
| <a name="output_saml_role_attribute"></a> [saml\_role\_attribute](#output\_saml\_role\_attribute) | Value for the IdP attribute https://aws.amazon.com/SAML/Attributes/Role (role ARN,provider ARN). |
| <a name="output_saml_status"></a> [saml\_status](#output\_saml\_status) | The status of SAML 2.0 authentication. |
| <a name="output_user_access_url"></a> [user\_access\_url](#output\_user\_access\_url) | The user access URL for the SAML 2.0 identity provider (IdP). |
| <a name="output_workspaces_directory_id"></a> [workspaces\_directory\_id](#output\_workspaces\_directory\_id) | The ID of the WorkSpaces Directory |
| <a name="output_workspaces_ip_group_id"></a> [workspaces\_ip\_group\_id](#output\_workspaces\_ip\_group\_id) | The ID of the WorkSpaces IP Group |
# 🚀 Built by opsZero!

<a href="https://opszero.com"><img src="https://opszero.com/img/common/opsZero-Logo-Large.webp" width="300px"/></a>

[opsZero](https://opszero.com) provides software and consulting for DevOps. With our decade plus of experience scaling some of the world’s most innovative companies we have developed deep expertise in Kubernetes, DevOps, FinOps, and Compliance.

Our software and consulting solutions enable organizations to:

- migrate workloads to the Cloud
- setup compliance frameworks including SOC2, HIPAA, PCI-DSS, ITAR, FedRamp, CMMC, and more.
- FinOps solutions to reduce the cost of running Cloud workloads
- Kubernetes optimized for web scale and AI workloads
- finding underutilized Cloud resources
- setting up custom AI training and delivery
- building data integrations and scrapers
- modernizing onto modern ARM based processors

We do this with a high-touch support model where you:

- Get access to us on Slack, Microsoft Teams or Email
- Get 24/7 coverage of your infrastructure
- Get an accelerated migration to Kubernetes

Please [schedule a call](https://calendly.com/opszero-llc/discovery) if you need support.

<br/><br/>

<div style="display: block">
  <img src="https://opszero.com/img/common/aws-advanced.png" alt="AWS Advanced Tier" width="150px" >
  <img src="https://opszero.com/img/common/aws-devops-competency.png" alt="AWS DevOps Competency" width="150px" >
  <img src="https://opszero.com/img/common/aws-eks.png" alt="AWS EKS Delivery" width="150px" >
  <img src="https://opszero.com/img/common/aws-public-sector.png" alt="AWS Public Sector" width="150px" >
</div>
<!-- END_TF_DOCS -->