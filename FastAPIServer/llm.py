import boto3
import json

aws_access_key_id = your key
aws_secret_access_key = your key
region_name = 'us-east-1' 

session = boto3.Session(
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    region_name=region_name
)
client = session.client('bedrock-runtime')

# api custom request body
def get_stock_market_response(user_prompt):
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 200,
        "temperature": 1,
        "top_p": 0.999,
        "messages": [
            {
                "role": "user",
                "content": (
                    "You are a chatbot specialized in the stock market. "
                    "You can predict stock trends, analyze the performance of stocks, and answer general questions about the stock market. "
                    "You are knowledgeable about market patterns, financial analysis, and trading strategies. "
                    "Your goal is to assist users with stock-related inquiries and provide insights. "
                    "You must keep your responses consize and to the point."
                    f"Here is a user's question: {user_prompt}"
                )
            }
        ]
    }

    #bedrock api call
    response = client.invoke_model(
        modelId="us.anthropic.claude-3-5-haiku-20241022-v1:0",  #model id
        body=json.dumps(request_body)
    )

    response_body = json.loads(response['body'].read())
    generated_text = response_body['content'][0]['text']

    return generated_text

# example promtt
# user_prompt = "What are the top-performing stocks in the tech sector this month?"
# response = get_stock_market_response(user_prompt)
# print("Stock Market Response:", response)
