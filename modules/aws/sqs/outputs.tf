output "termination_queue_arn" {
  value = aws_sqs_queue.node_termination_queue.arn
}
