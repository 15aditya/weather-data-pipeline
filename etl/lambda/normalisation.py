import json
import boto3
import pyarrow as pa
import pyarrow.parquet as pq
from io import BytesIO
from datetime import datetime
import pandas as pd

from etl.logging.logger import get_logger
from etl.utils.helper import transform

logger = get_logger(__name__)
s3 = boto3.client('s3')

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    bucket = event['s3_bucket']
    key = event['s3_key']

    try:
        logger.info(f"Processing {bucket}/{key}")
        response = s3.get_object(Bucket=bucket, Key=key)
        raw_data = json.loads(response['Body'].read())

        # let's do some transformation
        df = transform(raw_data)

        table = pa.Table.from_pandas(df)
        parquet_builder = BytesIO()
        pq.write_table(table, parquet_builder, compression='snappy')

        if pd.isna(df.iloc[0]['hour']):
            raise ValueError("You need to have an hour with a valid value to go ahead !!")

        partition_key = f"processed/weather/hour={df.iloc[0]['hour']}/data_{datetime.utcnow().strftime('%Y%m%dT%H%M%S')}.parquet"

        s3.put_object(
            Bucket=bucket,
            Key=partition_key,
            Body=parquet_builder.getvalue(),
            ContentType='application/octet-stream',
        )

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Data successfully processed!',
                'partition_key': partition_key
            })
        }

    except Exception as e:
        logger.error(f"Error processing {bucket}/{key}: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f"Error processing {bucket}/{key}: {e}"
            })
        }
