
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


