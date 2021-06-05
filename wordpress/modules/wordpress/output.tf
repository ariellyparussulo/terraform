output "wordpress_public_ip" {
  value = aws_instance.instance.public_ip
}

output "instance_id" {
  value = element(aws_instance.instance.*.id, 0)
}