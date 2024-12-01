# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_log" {
  name              = "ApiGateway-logGroup-PSX-DataPortal-CloudDev-Project-Group02"
  retention_in_days = 14
}
