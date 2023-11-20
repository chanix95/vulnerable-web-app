terraform {
  backend "s3" {}
}



data "aws_caller_identity" "current" {}

locals {
  service_name = "luciano-lionello"
  tags         = { "scope" = "eko" }
  image        = "public.ecr.aws/aws-containers/hello-app-runner:latest"
  port         = 8000

}

resource "aws_apprunner_auto_scaling_configuration_version" "autoscaling_configuration" {
  auto_scaling_configuration_name = "${local.service_name}-asc-conf"

  max_concurrency = 100
  max_size        = 2
  min_size        = 1

  tags = local.tags

}

resource "aws_apprunner_service" "service" {

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.autoscaling_configuration.arn
  service_name                   = local.service_name

  health_check_configuration {
    healthy_threshold   = 1
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 5
  }

  instance_configuration {
    cpu    = "256"
    memory = "512"
  }

  source_configuration {

    # Must be false when using public images or cross account images
    auto_deployments_enabled = false

    image_repository {
      image_configuration {
        port = local.port
      }

      image_identifier      = local.image
      image_repository_type = "ECR_PUBLIC"
    }
  }

  tags = local.tags

}

resource "aws_ecr_repository" "application_registry" {
  name                 = "vulnerable-web-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.tags

}


data "aws_iam_policy_document" "ecr_policy" {
  statement {
    sid    = "new policy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}

resource "aws_ecr_repository_policy" "ecr_policy" {
  repository = aws_ecr_repository.application_registry.name
  policy     = data.aws_iam_policy_document.ecr_policy.json
}

