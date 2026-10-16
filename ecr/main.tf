# App images, in shared-services only: built once on main (github-actions-ecr-push) and promoted
# to every account and region. Any account of the organization pulls (aws:PrincipalOrgID); only the
# push role writes. Replicated to the other regions, so a region pulls from its own copy (DR).
# A new app = its repository name here (the platform owns the registry, ADR-004).

data "aws_organizations_organization" "current" {}

data "aws_caller_identity" "current" {}

locals {
  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last ${var.keep_images} images"
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = var.keep_images }
      action       = { type = "expire" }
    }]
  })
}

data "aws_iam_policy_document" "pull_from_org" {
  statement {
    sid = "PullFromTheOrganization"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.current.id]
    }
  }
}

# Immutable tags: a tag (the git SHA) always means the same image. Scanned on push.
# AES256: a customer managed key costs per key and adds nothing here (images hold no secrets).
#trivy:ignore:AVD-AWS-0033
resource "aws_ecr_repository" "app" {
  for_each = toset(var.repositories)

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_repository_policy" "app" {
  for_each = aws_ecr_repository.app

  repository = each.value.name
  policy     = data.aws_iam_policy_document.pull_from_org.json
}

resource "aws_ecr_lifecycle_policy" "app" {
  for_each = aws_ecr_repository.app

  repository = each.value.name
  policy     = local.lifecycle_policy
}

# ---------------------------------------------------------------- replicas
resource "aws_ecr_replication_configuration" "main" {
  count = length(var.replica_regions) > 0 ? 1 : 0

  replication_configuration {
    rule {
      dynamic "destination" {
        for_each = var.replica_regions

        content {
          region      = destination.value
          registry_id = data.aws_caller_identity.current.account_id
        }
      }
    }
  }
}

# Repositories created by replication get the same pull policy, tag immutability and lifecycle.
#trivy:ignore:AVD-AWS-0033
resource "aws_ecr_repository_creation_template" "replicas" {
  count = length(var.replica_regions) > 0 ? 1 : 0

  prefix               = "ROOT"
  description          = "Replicas of the app repositories (managed by Terraform)"
  applied_for          = ["REPLICATION"]
  image_tag_mutability = "IMMUTABLE"
  repository_policy    = data.aws_iam_policy_document.pull_from_org.json
  lifecycle_policy     = local.lifecycle_policy

  encryption_configuration {
    encryption_type = "AES256"
  }
}
