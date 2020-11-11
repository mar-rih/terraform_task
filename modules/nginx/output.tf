output "nginx_ids" {
  value = aws_instance.prod_web.*.id
}