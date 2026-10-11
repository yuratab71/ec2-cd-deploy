terraform {
  required_version = ">= 1.15.8"
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "lambdas_role"
  assume_role_policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/${var.function.source_path}"
  output_path = "${path.module}/${var.function.archive_path}"
}

resource "aws_lambda_function" "lambdas" {
  function_name    = var.function.name
  filename         = data.archive_file.lambda.output_path
  role             = aws_iam_role.lambda.arn
  handler          = "cpu-usage-notification.handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs22.x"

  environment {
    variables = var.env
  }

  depends_on = [
  aws_iam_role_policy_attachment.lambda]
}

