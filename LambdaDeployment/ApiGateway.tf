# API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = "ApiGateway-PSX-DataPortal-CloudDev-Project-Group02"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"] # for now, it is all origins as we dont have a domain, but this is where we will add frontend link domain if we had one
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

# API post route for uploading files. 
resource "aws_apigatewayv2_route" "post_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /"
  target    = "integrations/${aws_apigatewayv2_integration.api_lambda_integration.id}"
}

#preflight route (apparently its a thing in browsers)
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

# Lambda Permission for API Gateway to invoke 
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.PDF_To_S3_LambdaFunction.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}