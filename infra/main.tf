# Local values
locals {
  cluster_name = var.cluster_name
  
  # Common tags
  common_tags = merge(var.tags, {
    Project     = "HealthMetrics"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Cluster     = local.cluster_name
  })
}

# SQS Queue for async processing
resource "aws_sqs_queue" "main_queue" {
  name                      = "${local.cluster_name}-messages"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 864000 # 10 days
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.main_queue_dlq.arn
    maxReceiveCount     = 3
  })

  tags = local.common_tags
}

# Dead Letter Queue
resource "aws_sqs_queue" "main_queue_dlq" {
  name                      = "${local.cluster_name}-messages-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = local.common_tags
}
