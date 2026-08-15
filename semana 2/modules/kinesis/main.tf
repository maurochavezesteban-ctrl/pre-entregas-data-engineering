resource "aws_kinesis_stream" "main" {
  name             = var.stream_name
  shard_count      = var.shard_count
  retention_period = 24
}

resource "aws_iam_role" "firehose" {
  name = "firehose-kinesis-dev"
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"firehose.amazonaws.com\"}}]}"
}

resource "aws_iam_role_policy" "firehose" {
  name = "firehose-kinesis-policy"
  role = aws_iam_role.firehose.id
  policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"kinesis:DescribeStream\",\"kinesis:GetShardIterator\",\"kinesis:GetRecords\"],\"Resource\":\"*\"},{\"Effect\":\"Allow\",\"Action\":[\"s3:PutObject\",\"s3:GetBucketLocation\",\"s3:ListBucket\",\"s3:AbortMultipartUpload\"],\"Resource\":\"*\"}]}"
}

resource "aws_kinesis_firehose_delivery_stream" "main" {
  name        = "ingesta-clicks-ecommerce-dev"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.main.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose.arn
    bucket_arn         = "arn:aws:s3:::coderhouse-datalake-algo"
    prefix             = "ingesta/"
    error_output_prefix = "errors/"
    
    # Nombres nativos corregidos para el proveedor de AWS
    buffering_size     = var.buffer_size_mb
    buffering_interval = var.buffer_interval_sec
    
    compression_format = "GZIP"
  }
}

resource "aws_cloudwatch_metric_alarm" "read_throttle" {
  alarm_name          = "kinesis-read-throttled-dev"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReadProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  dimensions = { StreamName = "clicks-ecommerce-dev" }
}

resource "aws_cloudwatch_metric_alarm" "write_throttle" {
  alarm_name          = "kinesis-write-throttled-dev"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  dimensions = { StreamName = "clicks-ecommerce-dev" }
}
