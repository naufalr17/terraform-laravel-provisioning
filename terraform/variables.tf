variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Linode region"
  type        = string
  default     = "ap-south" 
}

variable "instance_type" {
  description = "Linode instance type (plan)"
  type        = string
  default     = "g6-standard-2" # 2 vCPU, 4GB
}

variable "label" {
  description = "VM label (Linode name). Use format <nama>_test_cloudops_yyyy-dd-mm"
  type        = string
}

variable "authorized_ssh_key" {
  description = "Your SSH public key content (e.g., from ~/.ssh/id_rsa.pub)"
  type        = string
}

variable "app_name" {
  description = "Laravel app directory name"
  type        = string
  default     = "laravel"
}

variable "mysql_db_name" {
  description = "MySQL database name for Laravel"
  type        = string
  default     = "laravel_app"
}

variable "mysql_app_user" {
  description = "MySQL app username"
  type        = string
  default     = "laravel_user"
}

variable "tags" {
  description = "Linode tags"
  type        = list(string)
  default     = ["test-cloudops", "terraform", "laravel"]
}
