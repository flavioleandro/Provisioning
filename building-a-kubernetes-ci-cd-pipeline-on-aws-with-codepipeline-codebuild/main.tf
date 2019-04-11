provider "aws" {
  region  = "<your region>"
  version = "1.41"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "./invoke.py"
  output_path = "./function_payload.zip"
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    actions = [
      "codepipeline:PutJobSuccessResult",
      "codepipeline:PutJobFailureResult",
    ]

    effect = "Allow"

    resources = [
      "*",
    ]
  }
}

resource "aws_security_group" "lambda" {
  name        = "lambda-katt_sg"
  description = "lambda to invoke katt security group"
  vpc_id      = "<your vpc id>"

  # Allow all outgoing traffic (through NAT)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "lambda-katt-sg"
  }
}

resource "aws_iam_policy" "cd" {
  name   = "lambda_codepipeline_putjob_katt"
  path   = "/"
  policy = "${data.aws_iam_policy_document.codepipeline.json}"
}

resource "aws_iam_role" "lambda" {
  name               = "lambda-katt"
  assume_role_policy = "${data.aws_iam_policy_document.lambda.json}"
}

resource "aws_iam_role_policy_attachment" "basic_lambda_execution" {
  role       = "${aws_iam_role.lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy_attachment" "cd_attach_instance_role" {
  name       = "allow lambda instance role codepipeline for katt"
  policy_arn = "${aws_iam_policy.cd.arn}"

  roles = [
    "${aws_iam_role.lambda.name}",
  ]
}

resource "aws_lambda_function" "invoke_katt" {
  filename         = "function_payload.zip"
  function_name    = "invoke_katt"
  handler          = "invoke.katt"
  role             = "${aws_iam_role.lambda.arn}"
  source_code_hash = "${data.archive_file.lambda.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = "90"

  environment {
    variables = {
      KATT_URL = "https://katt-endpoint/webhook"
    }
  }

  vpc_config {
    subnet_ids         = ["lambda", "subnets"]
    security_group_ids = ["${aws_security_group.lambda.id}"]
  }
}