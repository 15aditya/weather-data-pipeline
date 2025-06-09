output "ingestion_function_arn" {
  value = aws_lambda_function.ingestion_job.arn
}

output "normalisation_function_arn" {
  value = aws_lambda_function.normalisation_job.arn
}
