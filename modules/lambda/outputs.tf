output "lambda_name" {
  value = aws_lambda_function.lambdas.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.lambdas.arn
}
