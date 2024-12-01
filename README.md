# CS 483 - Cloud Development Project
# PSX Data Portal

## By Group - 02
| Name                 | Roll Number |
| -------------------- | ----------- |
| Hassan Ali           |   25100037  |
| Muhammad Affan Naved |   25100283  |
| Abdullah Hashmat     |   25100148  |
| Hassan Asim          |   25100100  |
| Shahrez Aezad        |   25100212  |


## Table of Contents

### 1. [Setup Instructions](#setup-instructions)
### 2. [Deploying Fast API Server](#1-deploying-fast-api-server)
### 3. [Deploying Lambda Function + API Gateway](#2-deploying-lambda-function--api-gateway)
### 4. [Running the React App](#3-running-the-react-app)

<br>

### Setup Instructions

In order to deploy and run the project there are several steps that need to be followed.

There are 3 Terraform configurations that need to be run in order for the deployed application to work.

These configurations are in the following subfolders:

1. `TerraformDeployment/Main` ----> Contains all .tf files to deploy the FastAPI server.
2. `LambdaDeployment` ----> Contains files to deploy Lambda function.
3. `reactwebapp` ----> Contains files to host the react application.

<br>

### **<u>1. Deploying Fast API Server</u>**

Firstly, login to your AWS console and create an ECR repository. Name it `fastapiserver`. From there you can view its push commands to build the docker image and push it to the repo. For completeness the commands are also given below.

Make sure you have docker installed and ready to run. Then proceed to navigate to the `FastAPIServer` directory, where the `Dockerfile` is located.

In you terminal run these commands:

```shell

$ cd FastAPIServer

# 1
$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com

# 2
$ docker build -t fastapiserver .

# 3
$ docker tag fastapiserver:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/fastapiserver:latest

# 4
$ docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/fastapiserver:latest


```


Once these commands have run successfuly you should be able to see the image uploaded on your ECR repository. From there copy the Image URI of the latest image.

Navigate to the `TerraformDeployment/Main` directory in the root of the project.

Open the `variables.tf` file, where you will find the definitons of 2 variables: 
1. `fastapi_image`
2. `sns_email`.

Paste your Image URI you copied in the `fastapi_image` default line and provide an email in the default line of `sns_email` to specify where you would like to receive the emails in case of any alarm in the server.

```json

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

```

Once the variables have been added run the following commands to provision the AWS services.

```shell
$ terraform init
$ terraform validate
$ terraform plan
$ terraform apply --auto-approve


# Use this command one you are done testing the deployed server
$ terraform destroy --auto-approve
```

Running the first 4 commands should successfully provision the FastAPI ECS service and DNS name provided by the load balancer should be output on your terminal. You can copy and paste this into your browser and expect to see this:

```json
{
  "message": "Server is healthy"
}
```

These are the endpoints supported by our API:
1. `/` This is the root.
2. `/health` Serves as a health check.
3. `/getData` Gets data stored in NeonDB.
4. `/upload` Takes a PDF file, parses it and stores data in NeonDB.

To use this API URL in the react web app, you will need to navigate to `reactwebapp` in the root directory of the project.

Then create a `.env` file as shown below in root of the `reactwebapp` directory.

```
REACT_APP_LAMBDA_API="<paste your LAMBDA API URL (instructions below) here>"

REACT_APP_FASTAPI="<paste your API URL (Load Balancer DNS name here)>"
```

Once this is done you will need to provision the AWS Lambda Function and paste its API URL in the `.env` file shown for the web app to work properly.

<br>

### **<u>2. Deploying Lambda Function + API Gateway</u>**

To deploy the Lambda function, simply navigate to the `LambdaDeployment` directory in the root of the project and run these commands.

```shell
$ cd LambdaDeployment

$ terraform init
$ terraform validate
$ terraform plan
$ terraform apply --auto-approve



# Use this command one you are done testing the deployed function
$ terraform destroy --auto-approve
```

The terminal will output the API URL needed to access the Lambda function. Copy and paste this url in the `.env` file in `reactwebapp` directory as shown above. With these 2 URLs added you will now be able to run the react app.

<br>


### **<u>3. Running the React App</u>**

To run the react app, simply navigate to the `reactwebapp` directory and run

`npm run start` in the terminal.

You can also deploy the website by first running `npm run build` in the terminal (make sure you are in the correct directory and that `.env` is properly set to the appropriate API URLs). Then run the same commands:

```shell
$ cd reactwebapp

$ terraform init
$ terraform validate
$ terraform plan
$ terraform apply --auto-approve



# Use this command one you are done testing the deployed website
$ terraform destroy --auto-approve
```
The command will output the URL for the webite which you can use to access it via your browser.