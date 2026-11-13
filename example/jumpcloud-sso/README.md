# Amazon WorkSpaces with JumpCloud SSO

This example creates a Simple AD directory, registers it with Amazon WorkSpaces, provisions one WorkSpace, and enables SAML 2.0 single sign-on through JumpCloud.

Users sign in to the WorkSpaces client with JumpCloud (password + MFA, as configured in JumpCloud) instead of the directory password.

## How it works

```
WorkSpaces client ──> JumpCloud (login + MFA) ──SAML──> AWS STS (AssumeRoleWithSAML)
                                                              │
                     WorkSpace session <── workspaces:Stream ─┘
```

When `saml_metadata_document` is set, the module creates:

| Resource | Purpose |
|---|---|
| `aws_iam_saml_provider` | Trusts JumpCloud's signing certificate (from the metadata XML). |
| `aws_iam_role` | Assumed via SAML. Trust policy requires `SAML:sub_type = persistent`. |
| `aws_iam_role_policy` | Allows `workspaces:Stream` on this directory only, and only when `workspaces:userId` equals the SAML NameID. |

and sets `saml_properties` on the WorkSpaces directory (`status`, `user_access_url`, `relay_state_parameter_name`).

## Prerequisites

- Terraform >= 1.15.8, AWS provider >= 6.58.0
- An AWS profile with permission for Directory Service, WorkSpaces and IAM
- A VPC with two private subnets in different AZs, in a [region that supports WorkSpaces](https://docs.aws.amazon.com/workspaces/latest/adminguide/azs-workspaces.html)
- JumpCloud admin access

## Step 1: Create the JumpCloud SSO app

In the JumpCloud Admin Portal go to **SSO Applications → + Add New Application → Custom Application** (SAML 2.0) and set:

| Field | Value |
|---|---|
| IdP Entity ID | `jumpcloud-workspaces` (any unique value) |
| SP Entity ID | `urn:amazon:webservices` |
| ACS URL | `https://signin.aws.amazon.com/saml` |
| SAMLSubject NameID | `username` |
| SAMLSubject NameID Format | `urn:oasis:names:tc:SAML:2.0:nameid-format:persistent` |
| Signature Algorithm | `RSA-SHA256` |
| Sign | Assertion |
| IdP URL | `https://sso.jumpcloud.com/saml2/aws-workspaces` |

Save, then **Export Metadata** and save the file here as `jumpcloud-metadata.xml` (git-ignored). See [`jumpcloud-metadata.example.xml`](jumpcloud-metadata.example.xml) for what it looks like.

## Step 2: Configure and apply Terraform

```sh
cp terraform.tfvars.example terraform.tfvars   # fill in vpc_id, private_subnet_ids, jumpcloud_sso_url
export TF_VAR_ad_password='<strong directory admin password>'
export AWS_PROFILE=<profile>

terraform init
terraform plan -out tfplan
terraform apply tfplan
```

The example sets `status = "ENABLED_WITH_DIRECTORY_LOGIN_FALLBACK"`, so the directory password still works while you test. Switch to `"ENABLED"` to force JumpCloud-only login.

| `status` | Behaviour |
|---|---|
| `DISABLED` | Directory username/password only (module default). |
| `ENABLED_WITH_DIRECTORY_LOGIN_FALLBACK` | JumpCloud SSO, falls back to directory login. |
| `ENABLED` | JumpCloud SSO only. |

Creating the directory and WorkSpace takes about 20–40 minutes.

## Step 3: Finish the JumpCloud app

Get the values from Terraform:

```sh
terraform output saml_relay_state
terraform output saml_role_attribute
```

Back in the JumpCloud app:

1. **Default RelayState**: value of `saml_relay_state`
   (`https://workspaces.euc-sso.<region>.aws.amazon.com/sso-idp?registrationCode=<code>`).
2. **Attributes** (*Attribute Statements*):

   | Service Provider Attribute Name | JumpCloud value |
   |---|---|
   | `https://aws.amazon.com/SAML/Attributes/Role` | Constant: value of `saml_role_attribute` (`<role ARN>,<provider ARN>`) |
   | `https://aws.amazon.com/SAML/Attributes/RoleSessionName` | `username` |
   | `https://aws.amazon.com/SAML/Attributes/PrincipalTag:Email` | `email` |

3. **User Groups**: bind the groups that should have WorkSpaces access. Save.

## Step 4: Users and sign-in

- Each JumpCloud **username must equal the WorkSpace `user_name`** (the directory user). The IAM policy only allows streaming when they match.
- Users open the WorkSpaces client (or <https://clients.amazonworkspaces.com>), enter the directory **registration code** (`terraform output` → module `registration_code`), and are redirected to JumpCloud to sign in.

## Troubleshooting

| Symptom | Check |
|---|---|
| "Not authorized to perform sts:AssumeRoleWithSAML" | NameID format must be `persistent`; the `Role` attribute must be exactly `role_arn,provider_arn`. |
| JumpCloud login succeeds, WorkSpace won't connect | JumpCloud username ≠ WorkSpace `user_name`, or the user has no WorkSpace. |
| Client never redirects to JumpCloud | `status` is `DISABLED`, or the client was registered before SSO was enabled; re-register. |
| "Invalid SAML metadata" on apply | `jumpcloud-metadata.xml` is the example placeholder, not the real export. |

## Disable SSO

Set `status = "DISABLED"` and apply. To remove the IAM SAML provider and role, also remove `saml_metadata_document`.
