import boto3
import logging
import os
import json

from botocore.vendored import requests
from urllib.error import URLError, HTTPError

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
logger.info('Logging initialized')

# Get katt's url from environment
KATT_URL = os.environ['KATT_URL']
codepipeline_client = boto3.client('codepipeline')


def katt(event, context):
    codepipeline_job_id = event['CodePipeline.job']['id']
    codepipeline_job_data = event['CodePipeline.job']['data']
    logger.info(event)

    try:
        logger.info("Sending HTTP request to {}".format(KATT_URL))
        headers = {'content-type': 'application/json'}
        r = requests.post(KATT_URL, data=json.dumps(event), headers=headers)
        logger.info("Received HTTP response code: {}".format(r.status_code))
        response = r.text
        logger.info(response)
    except HTTPError as e:
        error_text = "Request failed: {} {}".format(e.code, e.reason)
        logger.error(error_text)
        codepipeline_client.put_job_failure_result(
            jobId=codepipeline_job_id,
            failureDetails={"message": error_text, "type": "JobFailed"}
        )
        logger.error(
            "Marked Pipeline job {} as failed!".format(codepipeline_job_id)
        )
    except URLError as e:
        error_text = "Server connection failed: {}".format(e.reason)
        logger.error(error_text)
        codepipeline_client.put_job_failure_result(
            jobId=codepipeline_job_id,
            failureDetails={"message": error_text, "type": "JobFailed"}
        )
        logger.error(
            "Marked Pipeline job {} as failed!".format(codepipeline_job_id)
        )
    except Exception as e:
        error_text = "Unknown error: {}".format(e)
        logger.error(error_text)
        codepipeline_client.put_job_failure_result(
            jobId=codepipeline_job_id,
            failureDetails={"message": error_text, "type": "JobFailed"}
        )
        logger.error(
            "Marked Pipeline job {} as failed!".format(codepipeline_job_id)
        )