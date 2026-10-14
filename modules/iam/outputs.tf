output "execution_role_arn" {
  description = "ARN du rôle d'exécution des tâches ECS."
  value       = aws_iam_role.execution.arn

  # Les permissions doivent exister avant qu'une task definition utilise le rôle.
  depends_on = [aws_iam_role_policy.execution]
}

output "execution_role_name" {
  description = "Nom du rôle d'exécution des tâches ECS."
  value       = aws_iam_role.execution.name
}

output "task_role_arn" {
  description = "ARN du rôle de tâche ECS (permissions applicatives)."
  value       = aws_iam_role.task.arn

  depends_on = [aws_iam_role_policy.task]
}

output "task_role_name" {
  description = "Nom du rôle de tâche ECS."
  value       = aws_iam_role.task.name
}
