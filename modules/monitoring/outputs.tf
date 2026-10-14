output "sns_topic_arn" {
  description = "ARN du topic SNS qui reçoit les alarmes."
  value       = aws_sns_topic.alarms.arn
}

output "alarm_names" {
  description = "Noms des alarmes CloudWatch."
  value       = [for alarm in aws_cloudwatch_metric_alarm.this : alarm.alarm_name]
}

output "dashboard_name" {
  description = "Nom du dashboard CloudWatch."
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}

output "dashboard_url" {
  description = "URL console du dashboard CloudWatch."
  value       = "https://${local.region}.console.aws.amazon.com/cloudwatch/home?region=${local.region}#dashboards/dashboard/${aws_cloudwatch_dashboard.this.dashboard_name}"
}
