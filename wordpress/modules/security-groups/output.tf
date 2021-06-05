output "wordpress_public" {
  value = aws_security_group.wordpress.id
}

output "wordpress_load_balancer" {
  value = aws_security_group.load_balancer.id
}

output "database" {
  value = aws_security_group.database.id
}