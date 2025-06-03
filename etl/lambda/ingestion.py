import json
import os
from etl.logging.logger import get_logger
from datetime import datetime
import requests
import boto3

logger = get_logger(__name__)
s3 = boto3.client('s3')
lambda_client = boto3.client('lambda')


def lambda_handler(event, context):
    logger.info('Job Started !!')

    timestamp  = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    api_endpoint = "http://api.weatherstack.com/current?access_key=1c6f27fbb6fb825637724a4f7959fa62&query=Berlin"
    s3_bucket = f"blueprints-academy-data-lake-{os.environ['ENVIRONMENT']}"
    s3_key = f"raw/weather/{timestamp}"

    try:
        logger.info("Ingestion started !!")
        response = requests.get(api_endpoint, timeout=5)
        response.raise_for_status()

        data = response.json()

        # push to s3
        s3.put_object(
            Bucket=s3_bucket,
            Key=s3_key,
            Body=json.dumps(data),
            ContentType='application/json',
        )

        # payload = {
        #     "bucket": s3_bucket,
        #     s3_key: s3_key,
        # }
        #
        # logger.info('Invoking normalisation lambda for further processing')
        # # invoke normalisation lambda
        # lambda_client.invoke(
        #     FunctionName="normalisation",
        #     InvocationType="Event", # Async
        #     Payload=json.dumps(payload)
        # )
        # logger.info('Lambda invocation was successful')

        logger.info('Ingestion completed !!')

        return {
            'statusCode': 200,
            'body': "Ingestion completed !!"
        }

    except Exception as e:
        logger.error('Ingestion failed !!')
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
            })
        }


