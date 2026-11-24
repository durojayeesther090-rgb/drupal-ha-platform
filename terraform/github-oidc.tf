# Lets GitHub Actions deploy to AWS WITHOUT stored access keys.
# GitHub proves who it is with a short-lived token (OIDC) and receives a
# temporary role that may only roll the Auto Scaling groups.
# Switched on with: enable_github_actions_role = true

data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  count          = var.enable_github_actions_role && !var.github_oidc_provider_exists ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.enable_github_actions_role && var.github_oidc_provider_exists ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  github_oidc_arn = try(
    aws_iam_openid_connect_provider.github[0].arn,
    data.aws_iam_openid_connect_provider.github[0].arn,
    null
  )
}

resource "aws_iam_role" "github_actions" {
  count = var.enable_github_actions_role ? 1 : 0
  name  = "${var.project}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = local.github_oidc_arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_repo}:environment:staging",
            "repo:${var.github_repo}:environment:production",
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions" {
  count = var.enable_github_actions_role ? 1 : 0
  name  = "deploy-auto-scaling-groups"
  role  = aws_iam_role.github_actions[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeInstanceRefreshes",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:StartInstanceRefresh",
          "autoscaling:CancelInstanceRefresh",
        ]
        Resource = "arn:aws:autoscaling:${var.region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${var.project}-*"
      },
    ]
  })
}
