data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "cloud_trail_bucket" {
  bucket = var.bucket
  force_destroy = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.bucket}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.bucket}/${var.bucket_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudtrail" "cloudtrail_monitoring" {
  name                          = "aws-cloudtrail-monitoring"
  s3_bucket_name                = aws_s3_bucket.cloud_trail_bucket.id
  s3_key_prefix                 = var.bucket_prefix
  include_global_service_events = false
  depends_on = [aws_s3_bucket.cloud_trail_bucket]
}
