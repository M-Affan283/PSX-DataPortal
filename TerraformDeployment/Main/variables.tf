//variables.tf file


variable "fastapi_image" {
    description = "FastAPI Docker image"
    type = string
    default = "<your-fastapi-image>"
}

variable "sns_email" {
    description = "Email to send SNS notifications"
    type = string
    default = "<your-email>"
}