import logging
import os
import boto3
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f'Hello World!')
    logger.info(f'## ENVIRONMENT VARIABLES: {os.environ}')
    logger.info(f'## EVENT: {event}')
    logger.info({os.environ['AWS_REGION']})

    return {
        'statusCode': 200,
    }