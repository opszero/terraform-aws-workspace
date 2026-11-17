# SAML 2.0 single sign-on for WorkSpaces (e.g. JumpCloud, Okta, Entra ID).
#
# Created only when `saml_metadata_document` is set. The IdP authenticates the
# user, AWS STS exchanges the assertion for this role, and the role allows the
# user to stream only the WorkSpace whose user name matches the SAML NameID.

locals {
  saml_enabled = var.saml_metadata_document != null
  saml_name    = coalesce(var.saml_provider_name, "${var.name}-workspaces-saml")
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "aws_iam_saml_provider" "workspaces" {
  count = local.saml_enabled ? 1 : 0

  name                   = local.saml_name
  saml_metadata_document = var.saml_metadata_document
  tags                   = var.tags
}

data "aws_iam_policy_document" "saml_assume" {
  count = local.saml_enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithSAML", "sts:TagSession"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_saml_provider.workspaces[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "SAML:sub_type"
      values   = [var.saml_name_id_format]
    }
  }
}

data "aws_iam_policy_document" "saml_stream" {
  count = local.saml_enabled ? 1 : 0

  statement {
    actions = ["workspaces:Stream"]
    resources = [
      "arn:${data.aws_partition.current.partition}:workspaces:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:directory/${aws_directory_service_directory.main.id}",
    ]

    condition {
      test     = "StringEquals"
      variable = "workspaces:userId"
      values   = ["$${saml:sub}"]
    }
  }
}

resource "aws_iam_role" "saml" {
  count = local.saml_enabled ? 1 : 0

  name                 = local.saml_name
  description          = "WorkSpaces SAML federation role for ${local.saml_name}"
  assume_role_policy   = data.aws_iam_policy_document.saml_assume[0].json
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}

resource "aws_iam_role_policy" "saml_stream" {
  count = local.saml_enabled ? 1 : 0

  name   = "workspaces-stream"
  role   = aws_iam_role.saml[0].id
  policy = data.aws_iam_policy_document.saml_stream[0].json
}
