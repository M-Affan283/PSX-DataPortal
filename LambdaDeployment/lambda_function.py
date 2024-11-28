import boto3
import base64
import json
import os

s3 = boto3.client('s3')

def lambda_handler(event, context):
    http_method = event.get("httpMethod")

    # Handle preflight requests
    if http_method == "OPTIONS":
        print("[LAMBDA LOGS], options http triggered")
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            },
        }

    # Handle POST requests
    if http_method == "POST":
        try:
            print("[LAMBDA LOGS] event received: ", event)
            bucket_name = os.environ['BUCKET_NAME']
            body = event.get('body')
            print("[LAMBDA LOGS] bucket_name from env: ", bucket_name)
            print("[LAMBDA LOGS] body received: ", body)
            
            if not body:
                return generate_response(400, "Missing request body")
            
            body = json.loads(body)
            file_name = body.get('file_name')
            print("[LAMBDA LOGS] file name received: ", file_name)
            file_content_base64 = body.get('file_content')
            

            if not file_name or not file_content_base64:
                return generate_response(400, "Missing file_name or file_content")

            file_content = base64.b64decode(file_content_base64)
            print("[LAMBDA LOGS] file content received: ", file_content)

            s3.put_object(Bucket=bucket_name, Key=file_name, Body=file_content)

            return generate_response(200, f"File '{file_name}' uploaded successfully.")
        except Exception as e:
            print("[LAMBDA LOGS] error occured: ", str(e))
            return generate_response(500, str(e))

def generate_response(status_code, message):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
        "body": json.dumps({"message": message})
    }
