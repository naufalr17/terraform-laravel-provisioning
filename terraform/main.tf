terraform {
  required_version = ">= 1.13.4"

  required_providers {
    linode = {
      source  = "linode/linode"
      version = "3.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
  }
}

provider "linode" {
  token = var.linode_token

}

resource "random_password" "root_password" {
  length  = 20
  special = false
}

resource "random_password" "mysql_root_password" {
  length  = 24
  special = false
}

resource "random_password" "mysql_app_password" {
  length  = 20
  special = false
}

# Linode Cloud Firewall: allow SSH(22), HTTP(80), HTTPS(443), deny rest
resource "linode_firewall" "web" {
  label           = "web-allow-http-https-ssh"
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }
  inbound {
    label    = "allow-http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-mysql"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "3306"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-icmp"
    action   = "ACCEPT"
    protocol = "ICMP"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }
  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }
  outbound {
    label    = "allow-ssh-out"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  outbound {
    label    = "allow-http-out"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  outbound {
    label    = "allow-https-out"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }


  outbound {
    label    = "allow-icmp"
    action   = "ACCEPT"
    protocol = "ICMP"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  outbound {
    label    = "allow-mysql"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "3306"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  tags = var.tags
  linodes = [linode_instance.web.id]
}

# Render cloud-init with secrets & config
locals {
  cloud_init = base64encode(templatefile("${path.module}/cloud-init.yaml.tftpl", {
    authorized_ssh_key     = var.authorized_ssh_key
    root_password          = random_password.root_password.result
    mysql_root_password    = random_password.mysql_root_password.result
    mysql_app_password     = random_password.mysql_app_password.result
    mysql_db_name          = var.mysql_db_name
    mysql_app_user         = var.mysql_app_user
    app_name               = var.app_name
  }))
}

resource "linode_instance" "web" {
  label           = var.label
  image           = "linode/ubuntu24.04"
  region          = var.region
  type            = var.instance_type
  root_pass       = random_password.root_password.result
  authorized_keys = [var.authorized_ssh_key]
  tags            = var.tags

  # cloud-init user data
  metadata {
    user_data = local.cloud_init
  }
  
}
