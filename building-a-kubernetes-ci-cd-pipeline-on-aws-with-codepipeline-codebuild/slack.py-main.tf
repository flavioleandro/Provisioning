provider "aws" {
  region  = "eu-west-1"
  version = "1.14"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

variable "kms_id" {
  description = "The KMS key to decrypt env variables"
  type        = "string"
}

variable "slack_hook_url" {
  description = "Slack hook url"
  type        = "string"
}

data "archive_file" "lambda_func" {
  type        = "zip"
  source_file = "./slack.py"
  output_path = "./function_payload.zip"
}

data "aws_iam_policy_document" "kms" {
  statement {
    actions = ["kms:Decrypt"]
    effect  = "Allow"

    resources = [
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${var.kms_id}",
    ]
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "kms" {
  name        = "kms_decrypt_build_lambda"
  description = "KMS Decrypt"
  policy      = "${data.aws_iam_policy_document.kms.json}"
}

resource "aws_iam_role" "lambda" {
  name               = "lambda_slack_notify_build"
  assume_role_policy = "${data.aws_iam_policy_document.lambda.json}"
}

resource "aws_iam_policy_attachment" "kms_attach_instance_role" {
  name       = "allow lambda instance role to decrypt kms"
  roles      = ["${aws_iam_role.lambda.name}"]
  policy_arn = "${aws_iam_policy.kms.arn}"
}

resource "aws_iam_role_policy_attachment" "basic_lambda_execution" {
  role       = "${aws_iam_role.lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_kms_ciphertext" "slack_url" {
  key_id    = "${var.kms_id}"
  plaintext = "${var.slack_hook_url}"
}

resource "aws_cloudwatch_event_rule" "codebuild_state" {
  name        = "codebuild-build-state-change"
  description = "CodeBuild Build State Change"

  event_pattern = <<PATTERN
{
  "source": [ 
    "aws.codebuild"
  ], 
  "detail-type": [
    "CodeBuild Build State Change"
  ],
  "detail": {
    "build-status": [
      "IN_PROGRESS",
      "SUCCEEDED", 
      "FAILED",
      "STOPPED" 
    ]
  }  
}
PATTERN
}

resource "aws_cloudwatch_event_rule" "codepipeline_execution_state" {
  name        = "codepipeline-execution-state-change"
  description = "CodePipeline Execution State Change"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.codepipeline"
  ],
  "detail-type": [
    "CodePipeline Pipeline Execution State Change"
  ],
  "detail": {
    "state": [
      "CANCELED",
      "FAILED",
      "RESUMED",
      "STARTED",
      "SUCCEEDED",
      "SUPERSEDED"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_rule" "codepipeline_stage_execution_state" {
  name        = "codepipeline-stage-execution-state-change"
  description = "CodePipeline Stage Execution State Change"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.codepipeline"
  ],
  "detail-type": [
    "CodePipeline Stage Execution State Change"
  ],
  "detail": {
    "state": [
      "CANCELED",
      "FAILED",
      "RESUMED",
      "STARTED",
      "SUCCEEDED"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "codebuild_state" {
  rule      = "${aws_cloudwatch_event_rule.codebuild_state.name}"
  target_id = "SendToLambda"
  arn       = "${aws_lambda_function.build_slack.arn}"
}

resource "aws_cloudwatch_event_target" "codepipeline_stage_execution_state" {
  rule      = "${aws_cloudwatch_event_rule.codepipeline_stage_execution_state.name}"
  target_id = "SendToLambda"
  arn       = "${aws_lambda_function.build_slack.arn}"
}

resource "aws_lambda_function" "build_slack" {
  filename         = "${data.archive_file.lambda_func.output_path}"
  function_name    = "notify_slack_build"
  handler          = "slack.message"
  role             = "${aws_iam_role.lambda.arn}"
  source_code_hash = "${data.archive_file.lambda_func.output_base64sha256}"
  runtime          = "python3.6"
  kms_key_arn      = "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${var.kms_id}"

  environment {
    variables = {
      SLACK_HOOK_URL = "${data.aws_kms_ciphertext.slack_url.ciphertext_blob}"
    }
  }
}

resource "aws_lambda_permission" "codebuild_state" {
  statement_id  = "codebuild-build-state-change"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.build_slack.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.codebuild_state.arn}"
}

resource "aws_lambda_permission" "codepipeline_stage_execution_state" {
  statement_id  = "codepipeline-stage-execution-state-change"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.build_slack.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.codepipeline_stage_execution_state.arn}"
}