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
