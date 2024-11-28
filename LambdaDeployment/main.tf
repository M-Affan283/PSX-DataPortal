# Provider Configuration
provider "aws" {
  region = "us-east-1"
}

# S3 Bucket
resource "aws_s3_bucket" "pdf_bucket" {
  bucket = "s3bucket-psx-dataportal-clouddev-project-group02"
  force_destroy = true
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Lambda to Access S3
resource "aws_iam_policy" "lambda_s3_policy" {
  name   = "lambda_s3_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "s3:PutObject",
      Resource = "arn:aws:s3:::${aws_s3_bucket.pdf_bucket.id}/*"
    }]
  })
}

# CloudWatch Logs Policy for Lambda
resource "aws_iam_policy" "lambda_cloudwatch_policy" {
  name   = "lambda_cloudwatch_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}


# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# Attach CloudWatch Policy to Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_policy.arn
}


# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_log" {
  name              = "ApiGateway-logGroup-PSX-DataPortal-CloudDev-Project-Group02"
  retention_in_days = 14
}


# CORS Headers in Lambda Function
resource "aws_lambda_function" "PDF_To_S3_LambdaFunction" {
  function_name    = "LambdaFunction-PSX-DataPortal-CloudDev-Project-Group02"
  runtime          = "python3.9"
  handler          = "lambda_function.lambda_handler"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.pdf_bucket.id
    }
  }

  # Add CloudWatch Logging
  depends_on = [
    aws_iam_role_policy_attachment.lambda_cloudwatch_attach
  ]
}


# API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = "ApiGateway-PSX-DataPortal-CloudDev-Project-Group02"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"] # IMPORTANT: ADD FRONTEND LINK HERE 
    allow_methods = ["OPTIONS", "POST"]
    allow_headers = ["Content-Type"]
  }
}


# API Integration with Lambda
resource "aws_apigatewayv2_integration" "api_lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.PDF_To_S3_LambdaFunction.invoke_arn
}

# API Route
resource "aws_apigatewayv2_route" "post_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /"
  target    = "integrations/${aws_apigatewayv2_integration.api_lambda_integration.id}"
}

#preflight route
resource "aws_apigatewayv2_route" "options_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "OPTIONS /"
  target    = "integrations/${aws_apigatewayv2_integration.api_lambda_integration.id}"
}

# API Stage
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  # CORS configuration
  default_route_settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 1000
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_log.arn
    format          = jsonencode({
      requestId       = "$context.requestId",
      sourceIp        = "$context.identity.sourceIp",
      requestTime     = "$context.requestTime",
      httpMethod      = "$context.httpMethod",
      resourcePath    = "$context.resourcePath",
      status          = "$context.status",
      responseLength  = "$context.responseLength"
    })
  }
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.PDF_To_S3_LambdaFunction.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

output "api_url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

