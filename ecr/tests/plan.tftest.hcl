# Plans the component against each account tfvars with mocked providers (no credentials):
#   for f in $(find env -name "*.tfvars"); do terraform test -var-file="$f"; done

mock_provider "aws" {
  mock_data "aws_organizations_organization" {
    defaults = { id = "o-test123456" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}

run "plan" {
  command = plan

  assert {
    condition     = alltrue([for r in aws_ecr_repository.app : r.image_tag_mutability == "IMMUTABLE" && r.image_scanning_configuration[0].scan_on_push])
    error_message = "App repositories have immutable tags and scan on push."
  }

  assert {
    condition     = length(aws_ecr_repository_policy.app) == length(var.repositories)
    error_message = "Every repository can be pulled by the organization."
  }

  assert {
    condition     = length(aws_ecr_replication_configuration.main) == (length(var.replica_regions) > 0 ? 1 : 0)
    error_message = "Replicas only when replica_regions is set."
  }

  assert {
    condition = (
      length(aws_ecr_repository.replica) == length(var.repositories) * length(var.replica_regions) &&
      length(aws_ecr_repository_policy.replica) == length(aws_ecr_repository.replica) &&
      alltrue([for r in aws_ecr_repository.replica : r.image_tag_mutability == "IMMUTABLE"])
    )
    error_message = "Every replica repository exists up front, immutable and pullable by the organization."
  }
}
