//variables.tf file


variable "fastapi_image" {
    description = "FastAPI Docker image"
    type = string
    default = "241533118783.dkr.ecr.us-east-1.amazonaws.com/fastapiserver:latest"
}

variable "sns_email" {
    description = "Email to send SNS notifications"
    type = string
    default = "25100283@lums.edu.pk"
}