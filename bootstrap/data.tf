# O OIDC provider do GitHub já existe na conta (é um por conta), então só é lido aqui.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Só a main (apply) e PRs (plan) deste repo. Nenhum outro repo ou branch assume a role.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # Dois formatos de sub: o imutável (com IDs numéricos, usado quando o repo tem
      # use_immutable_subject = true) e o clássico (só nomes). O imutável não é enganado
      # por um repo/org recriado com o mesmo nome.
      values = [
        "repo:${var.github_org}@${var.github_org_id}/${var.github_repo}@${var.github_repo_id}:ref:refs/heads/main",
        "repo:${var.github_org}@${var.github_org_id}/${var.github_repo}@${var.github_repo_id}:pull_request",
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_org}/${var.github_repo}:pull_request",
      ]
    }
  }
}

data "aws_iam_policy_document" "pipeline" {
  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
  }

  statement {
    sid       = "StateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket}/*"]
  }

  statement {
    sid = "SsmParameters"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:AddTagsToResource",
      "ssm:RemoveTagsFromResource",
      "ssm:ListTagsForResource",
    ]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_prefix}/*"]
  }

  statement {
    sid       = "SsmDescribe"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  # O provider AWS 6.x lê o atributo de DNS reverso de todo EIP; a AmazonVPCFullAccess não cobre.
  statement {
    sid       = "EipAttributesRead"
    actions   = ["ec2:DescribeAddressesAttribute"]
    resources = ["*"]
  }

  statement {
    sid       = "EipAttributesWrite"
    actions   = ["ec2:ModifyAddressAttribute", "ec2:ResetAddressAttribute"]
    resources = ["arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:elastic-ip/*"]
  }
}
