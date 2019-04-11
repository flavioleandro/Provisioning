import boto3
import json
import logging
import os

from base64 import b64decode
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

logger = logging.getLogger()
logger.setLevel(logging.ERROR)
logger.info('Logging initialized')

# get slack url from env, decrypt with kms
HOOK_URL = (
    "https://",
    boto3.client('kms').decrypt(
        CiphertextBlob=b64decode(os.environ['SLACK_HOOK_URL'])
    )['Plaintext'].decode('utf-8')
)


def handleCodePipeline(event):
    details = event['detail']
    color = slackColor(details['state'])

    # https://docs.aws.amazon.com/codepipeline/latest/userguide/detect-state-changes-cloudwatch-events.html
    if event['detail-type'] == "CodePipeline Action Execution State Change":
        """
        {
            "version": "0",
            "id": event_Id,
            "detail-type": "CodePipeline Action Execution State Change",
            "source": "aws.codepipeline",
            "account": Pipeline_Account,
            "time": TimeStamp,
            "region": "us-east-1",
            "resources": [
                "arn:aws:codepipeline:us-east-1:account_ID:myPipeline"
            ],
            "detail": {
                "pipeline": "myPipeline",
                "version": "1",
                "execution-id": execution_Id,
                "stage": "Prod",
                "action": "myAction",
                "state": "STARTED",
                "type": {
                    "owner": "AWS",
                    "category": "Deploy",
                    "provider": "CodeDeploy",
                    "version": 1
                }
            }
        }
        """
        slack_message = {
            "attachments": [
                {
                    "fallback": "{p} {sg} {a} (CodePipeline ID: {e_id}) {s}".format(
                        s=details['state'],
                        p=details['pipeline'],
                        e_id=details['execution-id'],
                        sg=details['stage'],
                        a=details['action']
                    ),
                    "color": "{color}".format(color=color),
                    "text": "*{project}* {stage} {action} _{state}_".format(
                        project=details['pipeline'],
                        stage=details['stage'],
                        state=details['state'],
                        action=details['action']
                    ),
                    "footer": "CodePipeline ID: {execution_id}".format(
                        execution_id=details['execution-id'],
                    ),
                }
            ]
        }
        sendslack(slack_message)

    if event['detail-type'] == "CodePipeline Stage Execution State Change":
        """
        {
            "version": "0",
            "id": event_Id,
            "detail-type": "CodePipeline Stage Execution State Change",
            "source": "aws.codepipeline",
            "account": Pipeline_Account,
            "time": TimeStamp,
            "region": "us-east-1",
            "resources": [
                "arn:aws:codepipeline:us-east-1:account_ID:myPipeline"
            ],
            "detail": {
                "pipeline": "myPipeline",
                "version": "1",
                "execution-id": execution_Id,
                "stage": "Prod",
                "state": "STARTED"
            }
        }
        """
        slack_message = {
            "attachments": [
                {
                    "fallback": "{p} {stage} (CodePipeline ID: {e_id}) {state}".format(
                        p=details['pipeline'],
                        e_id=details['execution-id'],
                        stage=details['stage'],
                        state=details['state']
                    ),
                    "color": "{color}".format(color=color),
                    "text": "*{project}* {stage} _{state}_".format(
                        project=details['pipeline'],
                        execution_id=details['execution-id'],
                        stage=details['stage'],
                        state=details['state']
                    ),
                    "footer": "CodePipeline ID: {execution_id}".format(
                        execution_id=details['execution-id'],
                    ),
                }
            ]
        }
        sendslack(slack_message)

    if event['detail-type'] == "CodePipeline Pipeline Execution State Change":
        """
        {
            "version": "0",
            "id": event_Id,
            "detail-type": "CodePipeline Pipeline Execution State Change",
            "source": "aws.codepipeline",
            "account": Pipeline_Account,
            "time": TimeStamp,
            "region": "us-east-1",
            "resources": [
                "arn:aws:codepipeline:us-east-1:account_ID:myPipeline"
            ],
            "detail": {
                "pipeline": "myPipeline",
                "version": "1",
                "state": "STARTED",
                "execution-id": execution_Id
            }
        }
        """
        slack_message = {
            "attachments": [
                {
                    "fallback": "{p} (CodePipeline ID: {e_id}) {s}".format(
                        p=details['pipeline'],
                        s=details['state'],
                        e_id=details['execution-id']
                    ),
                    "color": "{color}".format(color=color),
                    "text": "*{project}* _{state}_".format(
                        project=details['pipeline'],
                        execution_id=details['execution-id'],
                        state=details['state']
                    ),
                    "footer": "CodePipeline ID: {execution_id}".format(
                        execution_id=details['execution-id'],
                    ),
                }
            ]
        }
        sendslack(slack_message)


def handleCodeBuild(event):
    """
    https://docs.aws.amazon.com/codebuild/latest/userguide/sample-build-notifications.html#sample-build-notifications-ref
    """
    details = event['detail']
    build_status = details['build-status']
    project_name = details['project-name']
    build_id = details['build-id'].split("/")[1]
    build_id = build_id.split(":")[1]

    build_stop_ts = datetime.strptime(
        event['time'],
        '%Y-%m-%dT%H:%M:%SZ'
    )
    build_start_ts = datetime.strptime(
        event['detail']['additional-information']['build-start-time'],
        '%b %d, %Y %I:%M:%S %p'
    )
    build_timedelta = build_stop_ts - build_start_ts

    color = slackColor(build_status)
    buildlog_url_prefix = "https://eu-west-1.console.aws.amazon.com/" + \
        "cloudwatch/home?region=eu-west-1#logEventViewer:group=/aws/codebuild/"
    buildlog_url = "{prefix}{project};stream={id}".format(
        prefix=buildlog_url_prefix,
        project=project_name,
        id=build_id,
    )
    if build_status == "IN_PROGRESS":
        help_text = "(-f is to tail the log)"
        build_msg = "Check the buildlogs with: \n`sgn-buildlog {p}:{id} -f`\n{h}".format(
            p=project_name,
            id=build_id,
            h=help_text
        )
        slack_message = {
            "attachments": [
                {
                    "fallback": "Build of sgn-{p} (CodeBuild ID: {b_id}) {s}".format(
                        s=build_status,
                        p=project_name,
                        b_id=build_id
                    ),
                    "color": "{color}".format(color=color),
                    "text": "*sgn-{p}* Build _{status}_\n{msg}".format(
                        p=project_name,
                        status=build_status,
                        msg=build_msg
                    ),
                    "actions": [
                        {
                            "type": "button",
                            "name": "buildlog",
                            "text": "Buildlog",
                            "url": buildlog_url
                        }
                    ],
                    "footer": "CodeBuild ID: {build_id}".format(
                        build_id=build_id
                    ),
                }
            ]
        }
    else:
        slack_message = {
            "attachments": [
                {
                    "fallback": "Build of sgn-{p} (CodeBuild ID: {b_id}) {s}".format(
                        s=build_status,
                        p=project_name,
                        b_id=build_id
                    ),
                    "color": "{color}".format(color=color),
                    "text": "*sgn-{project}* Build _{status}_ time spent {time}s".format(
                        project=project_name,
                        status=build_status,
                        time=build_timedelta.total_seconds()
                    ),
                    "footer": "CodeBuild ID: {build_id}".format(
                        build_id=build_id
                    ),
                }
            ]
        }
    sendslack(slack_message)


def slackColor(status):
    # define a default color
    color = "#439FE0"  # blue

    bad_status = ["CANCELED", "FAILED", "STOPPED"]
    warning_status = ["RESUMED", "IN_PROGRESS", "SUPERSEDED"]
    good_status = ["SUCCEEDED"]

    if any(x in status for x in bad_status):
        color = 'danger'
    if any(x in status for x in warning_status):
        color = 'warning'
    if any(x in status for x in good_status):
        color = 'good'

    return color


def sendslack(slack_message):
    req = Request(
        ''.join(HOOK_URL),
        json.dumps(slack_message).encode('utf-8')
    )
    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted to Slack")
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)


def message(event, context):
    logger.info("Event: " + str(event))

    if event['source'] == "aws.codebuild":
        handleCodeBuild(event)

    if event['source'] == "aws.codepipeline":
        handleCodePipeline(event)