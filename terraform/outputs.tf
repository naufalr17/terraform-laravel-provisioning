output "public_ip" {
  description = "Public IPv4 address of the Linode"
  value       = linode_instance.web.ip_address
}

output "ssh_username" {
  value       = "deploy"
  description = "SSH username to use"
}

output "ssh_private_key_hint" {
  value       = "Use the private key that matches var.authorized_ssh_key"
  description = "Which private key to use for SSH"
}

output "mysql_host" {
  value       = "127.0.0.1"
  description = "MySQL host (inside server)"
}

output "mysql_root_password" {
  value       = random_password.mysql_root_password.result
  description = "MySQL root password"
  sensitive   = true
}

output "mysql_app_password" {
  value       = random_password.mysql_app_password.result
  description = "MySQL application user password"
  sensitive   = true
}

output "http_url" {
  value       = "http://${linode_instance.web.ip_address}"
  description = "URL to access Laravel (HTTP)"
}
