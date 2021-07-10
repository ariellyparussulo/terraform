
resource "aws_s3_bucket" "config" {
  bucket_prefix = var.bucket_prefix
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  lifecycle_rule {
    enabled = true
    prefix  = "${var.bucket_prefix}/"

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      days = 365
    }
  }
}


resource "aws_iam_role" "config" {
  name = "config-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "config-policy" {
  name = "config-manager-permissions"
  role = aws_iam_role.config.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.config.arn}",
        "${aws_s3_bucket.config.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_config_configuration_recorder" "config" {
  name     = "config"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_s3_bucket.config]
}

resource "aws_sns_topic" "operations_sns_topic" {
  name = "operations-sns-topic"
}

resource "aws_config_delivery_channel" "config" {
  name           = "account-config"
  s3_bucket_name = aws_s3_bucket.config.bucket
  s3_key_prefix  = var.bucket_prefix
  sns_topic_arn  = aws_sns_topic.operations_sns_topic.arn

  snapshot_delivery_properties {
    delivery_frequency = "Three_Hours"
  }

  depends_on = [aws_config_configuration_recorder.config]
}

resource "aws_config_config_rule" "required_tags_config_rule" {
  name        = "required_tags_rule"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode(var.required_tags)

  depends_on = [aws_config_delivery_channel.config]
}

resource "aws_config_config_rule" "root_account_mfa_enabled_config_rule" {
  name        = "root_account_mfa_enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [aws_config_delivery_channel.config]
}

resource "aws_config_config_rule" "iam_password_policy_config_rule" {
  name        = "iam_password_policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode(var.iam_password_policy)
  depends_on = [aws_config_delivery_channel.config]
}

resource "aws_config_config_rule" "approved_amis_by_id_config_rule" {
  name        = "approved_amis_by_id"

  source {
    owner             = "AWS"
    source_identifier = "APPROVED_AMIS_BY_ID"
  }

  input_parameters = jsonencode(var.allowed_amis)
  depends_on = [aws_config_delivery_channel.config]
}
