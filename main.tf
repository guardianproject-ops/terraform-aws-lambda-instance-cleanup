terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws     = "~> 2.0"
    archive = "~> 1.3.0"
  }
}

data "aws_caller_identity" "current" {}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/artifacts/lambda.zip"
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name               = module.label.id
  assume_role_policy = data.aws_iam_policy_document.assume.json
}


data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
  statement {
    effect  = "Allow"
    actions = ["ec2:TerminateInstances"]
    resources = [
      "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
    ]
    #condition {
    #  test     = "StringEquals"
    #  variable = "aws:RequestTag/${var.limit_tag}"
    #  values   = var.limit_tag_values
    #}
    dynamic "condition" {
      for_each = var.limit_tags
      content {
        test     = "StringEquals"
        variable = "ec2:ResourceTag/${condition.key}"
        values   = condition.value
      }
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda" {
  name        = module.label.id
  description = "Allow put logs, and ec2 describe and terminate"
  policy      = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_lambda_function" "default" {
  function_name    = module.label.id
  filename         = "${path.module}/artifacts/lambda.zip"
  handler          = "index.handler"
  role             = aws_iam_role.lambda.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs12.x"
}

resource "aws_lambda_alias" "default" {
  name             = "default"
  description      = "Use latest version as default"
  function_name    = aws_lambda_function.default.function_name
  function_version = "$LATEST"
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = module.label.id
  description         = module.label.id
  schedule_expression = var.schedule
}

resource "aws_cloudwatch_event_target" "schedule" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = module.label.id
  arn       = aws_lambda_function.default.arn
  input = jsonencode({
    "regions" : var.regions,
    "max_age_minutes" : var.max_age_minutes,
    "tags" : var.limit_tags
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.default.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
