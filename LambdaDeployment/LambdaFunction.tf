# Lambda Function
resource "aws_lambda_function" "PDF_To_S3_LambdaFunction" {
  function_name    = "LambdaFunction-PSX-DataPortal-CloudDev-Project-Group02"
  runtime          = "python3.9"
  handler          = "lambda_function.lambda_handler"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  # Adding the env variable for code to access.
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
