This file contains the lambda function code and terraform scripts to deploy it on aws.

The lambda function was intended to store files in s3 and also parse and put data into DB. however, python had good parsing libraries, but lambda functions dont allow async operations for python runtimes as per [6], so i decided to make it in node, but node didnt have good pdf parsers, so this lambda is just restricted to putting files into AWS s3 buckets. 

The challenges i also faced while creating the api gateway were related to cross origin requests from browsers, first i got the CORS error, then i set origin to * and then there was this OPTIONS req being sent to the api gateway which recieved no response from the lambda function and thus i was getting a network error, then i looked at the networks tab, saw the options req, looked it up, realized it was a preflight request that browser sends?? [7] and then accomodated that in the lambda function.


References:
[1] https://medium.com/@tech-add/aws-lambda-resource-created-through-terraform-a27a75794667
[2] https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api
[3] https://medium.com/onfido-tech/aws-api-gateway-with-terraform-7a2bebe8b68f
[4] https://haque-zubair.medium.com/aws-lambda-api-gateway-with-terraform-bd143b1c56bb
[5] any missing pieces and runtime challenges to completly run the deployment were filled with the help of ChatGPT. (https://chatgpt.com/)
[6] https://stackoverflow.com/questions/60455830/can-you-have-an-async-handler-in-lambda-python-3-6
[7] https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
