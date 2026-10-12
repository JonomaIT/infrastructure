# The GitHub OIDC provider already exists in the account (one per account), so it is only read here.
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

    # Only main (apply) and PRs (plan) of this repo. No other repo or branch can assume the role.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # Two sub formats: the immutable one (with numeric IDs, used when the repo has
      # use_immutable_subject = true) and the classic one (names only). The immutable one
      # cannot be fooled by a repo/org recreated with the same name.
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
    resources = [
      for prefix in var.ssm_prefixes : "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter${prefix}/*"
    ]
  }

  statement {
    sid       = "SsmDescribe"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  # AWS provider 6.x reads the reverse DNS attribute of every EIP; AmazonVPCFullAccess does not cover it.
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

# ecs stack: cluster, load balancers, Cloud Map, private zone and API Gateway VPC Link.
data "aws_iam_policy_document" "ecs" {
  statement {
    sid = "EcsCluster"
    actions = [
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:DescribeClusters",
      "ecs:UpdateCluster",
      "ecs:UpdateClusterSettings",
      "ecs:PutClusterCapacityProviders",
      "ecs:TagResource",
      "ecs:UntagResource",
      "ecs:ListTagsForResource",
    ]
    resources = ["*"]
  }

  statement {
    sid = "LoadBalancers"
    actions = [
      "elasticloadbalancing:Create*",
      "elasticloadbalancing:Delete*",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:Modify*",
      "elasticloadbalancing:Set*",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
    ]
    resources = ["*"]
  }

  statement {
    sid = "CloudMap"
    actions = [
      "servicediscovery:CreatePrivateDnsNamespace",
      "servicediscovery:UpdatePrivateDnsNamespace",
      "servicediscovery:DeleteNamespace",
      "servicediscovery:GetNamespace",
      "servicediscovery:ListNamespaces",
      "servicediscovery:GetOperation",
      "servicediscovery:ListOperations",
      "servicediscovery:TagResource",
      "servicediscovery:UntagResource",
      "servicediscovery:ListTagsForResource",
    ]
    resources = ["*"]
  }

  # The stack's own private zone and the zones Cloud Map creates behind its namespaces.
  statement {
    sid = "Route53PrivateZones"
    actions = [
      "route53:CreateHostedZone",
      "route53:DeleteHostedZone",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:UpdateHostedZoneComment",
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:GetChange",
      "route53:AssociateVPCWithHostedZone",
      "route53:DisassociateVPCFromHostedZone",
      "route53:ChangeTagsForResource",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "ApiGatewayVpcLinks"
    actions = ["apigateway:GET", "apigateway:POST", "apigateway:PATCH", "apigateway:DELETE", "apigateway:PUT"]
    resources = [
      "arn:aws:apigateway:*::/vpclinks",
      "arn:aws:apigateway:*::/vpclinks/*",
      "arn:aws:apigateway:*::/tags/*",
    ]
  }

  # The first time in each account, ECS, ELB and API Gateway create their own service-linked role.
  statement {
    sid       = "ServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "ecs.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "ops.apigateway.amazonaws.com",
      ]
    }
  }
}

# routing stack: Global Accelerator in front of both regions (Route 53 records are covered above).
data "aws_iam_policy_document" "routing" {
  statement {
    sid = "GlobalAccelerator"
    actions = [
      "globalaccelerator:Create*",
      "globalaccelerator:Update*",
      "globalaccelerator:Delete*",
      "globalaccelerator:Describe*",
      "globalaccelerator:List*",
      "globalaccelerator:AddEndpoints",
      "globalaccelerator:RemoveEndpoints",
      "globalaccelerator:TagResource",
      "globalaccelerator:UntagResource",
    ]
    resources = ["*"]
  }

  # The first accelerator in the account creates Global Accelerator's service-linked role.
  statement {
    sid       = "GlobalAcceleratorServiceLinkedRole"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["globalaccelerator.amazonaws.com"]
    }
  }
}
