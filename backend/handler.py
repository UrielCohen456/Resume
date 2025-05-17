import os
import logging

import boto3

# Requires having the TABLE_NAME env var set

dynamodb_client = boto3.resource("dynamodb")
logger = logging.getLogger()
logger.setLevel("INFO")

def lambda_handler(event, context):
    try:
        # Initializing the table client
        table_name = os.environ["TABLE_NAME"]
        if not table_name:
            raise ValueError("Missing required environment variable TABLE_NAME")
        table = dynamodb_client.Table(table_name)

        response = table.update_item(
                Key={'id': 'counter'},
                UpdateExpression='ADD #count :inc',
                ExpressionAttributeNames={'#count': 'count'},
                ExpressionAttributeValues={':inc': 1},
                ReturnValues='UPDATED_NEW'
            )

        logger.info(f"Successfully processed request")

        return {
            'statusCode': 200,
            'body': str(response['Attributes']['count'])
        }

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        raise 