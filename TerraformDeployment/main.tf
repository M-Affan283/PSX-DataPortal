resource "aws_lambda_function" "fastapi_lambda" {
  filename         = "lambda_function.zip"  # Zip and upload lambda_function.py
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.8"
  timeout          = 15

  environment {
    variables = {
      PYTHONPATH = "/var/task"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_policy_attachment]
}

resource "aws_apigatewayv2_api" "fastapi_api" {
  name          = var.api_gateway_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "fastapi_integration" {
  api_id           = aws_apigatewayv2_api.fastapi_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.fastapi_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "fastapi_route" {
  api_id    = aws_apigatewayv2_api.fastapi_api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.fastapi_integration.id}"
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fastapi_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.fastapi_api.execution_arn}/*/*"
}
