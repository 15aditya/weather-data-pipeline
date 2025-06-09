terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}
provider "aws" {
  region="eu-central-1"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "data-weather-pipeline-lambda-exec-rule"


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM policy for logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec_role.name
}

resource "aws_lambda_function" "ingestion_job" {
  function_name = "data-weather-pipeline-ingestion-job"
  package_type = "Image"
  image_uri = "${var.runtime_account_id}.dkr.ecr.eu-central-1.amazonaws.com/ingestion_lambda:latest"
  role          = aws_iam_role.lambda_exec_role.arn
  timeout = 60
}

resource "aws_lambda_function" "normalisation_job" {
  function_name = "data-weather-pipeline-normalisation-job"
  package_type = "Image"
  image_uri =  "${var.runtime_account_id}.dkr.ecr.eu-central-1.amazonaws.com/normalisation_lambda:latest"
  role          = aws_iam_role.lambda_exec_role.arn
  timeout = 60
}

# EventBridge Rule (runs every 5min)
resource "aws_cloudwatch_event_rule" "trigger_weather_data_pipeline" {
  name = "trigger-weather-data-pipeline"
  schedule_expression = "rate(5 minutes)"
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "weather_data_pipeline_event_target" {
  arn  = aws_lambda_function.ingestion_job.arn
  target_id = "lambda-target"
  rule = aws_cloudwatch_event_rule.trigger_weather_data_pipeline.name
}

# Eventbridge access to invoke lambda
resource "aws_lambda_permission" "allow_eventbridge_invoke_lambda" {
  statement_id = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion_job.function_name
  principal     = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.trigger_weather_data_pipeline.arn
}

# Athena Table
resource "aws_glue_catalog_database" "analytics" {
  name = "analytics_db"
}

resource "aws_glue_catalog_table" "weather_core" {
  name          = "weather_core"
  database_name = aws_glue_catalog_database.analytics.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "parquet"
    "compressionType" = "snappy"
    "typeOfData" = "file"
  }

  storage_descriptor {
    location      = "s3://blueprints-academy-data-lake-dev/processed/weather/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    compressed    = true

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "timestamp"
      type = "timestamp"
    }

    columns {
      name = "temperature_c"
      type = "integer"
    }

    columns {
      name = "humidity"
      type = "integer"
    }

    columns {
      name = "wind_speed"
      type = "integer"
    }

    columns {
      name = "weather_description"
      type = "string"
    }

    columns {
      name = "city"
      type = "string"
    }

    columns {
      name = "country"
      type = "string"
    }
  }

  # Partition definition
  partition_keys {
    name = "hour"
    type = "string"
  }
}
