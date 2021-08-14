// Region
tf-region = "eastus"

// Networking Setup
networking = {
  primary_cidr = "10.91.0.0/16"
  primary_cidr_name = "Cloud-Homelab"
  firewall_subnet = "10.91.254.0/24"
  public_subnets = {
    "public1" = "10.91.0.0/24"
  }
  private_subnets = {
    "private1" = "10.91.128.0/24"
  }
}

// SSH Information
ssh_information = {
  username = "danmanners"
  pubkey   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqOmALCT7gw6C0xhW8ig/WqiTCfUckw7tCnFxLl+Uf0jz2MsDz6/QAQ6MWCcl486vtt2lwF5m4GDlWY2u37f259JlWKHtIyaMAAUoGsHdE1SxVZrD9D00j73WPoHoTfV6v4cTNKDr6nmcxlO5wmA4ph6zUoOZyyuhW/MtDgdT+36d8AVjWSCuWA1NiD+o2FekUBbVWvIQ52Q+GM1w67CrqIk3DGl/CVuu/VSAZnQQ971zI8IiQD+Hxj2Et6aOhGhWRBGL45YGUya9c7ZkRn4173YjJC/TQJjORMkzd3o47EcDWK9i8rNm1YfL/EkAa+5N7sV+nMHonNZfBsSfV8l69EVMRTASvp22AArIxpDyMpgHk14IjjrZ2mBi1fATVGqZEYQYv2qMqGx32qPrvGLFwZ6jzumzPvpQIlJEoKE5gF+4KIXGs0OPW0FhWtn22R2hNg+PfD0i86p7iDSE0Fa7bdksvN1Ah9X4gqb0A8EXgvzQ4N/1bfbd2zi9yBKflCi+tW5/6zghO7oFM0aKHR7G6BDPYu8j/dSfprPejOLVSaO3folxerXMvTWc7PXptwNoA54oAze1zNuF3Nu/oeBps2EOXXugCiw/XgKsdWQ5M70EGWEY+NB1IpePX+AwbW+OIx2QC3vi/Pt3tknkmiubFRs9OignhX/V+xyYJQCEOrw== dan@RyzenPC"
}

// Virtual Machine Setup
k3s-vm = {
  name = "k3s-host"
  size = "Standard_B2s"
  disk_size = "32"

  eni = {
    name = "k3s-host-eni"
    subnet = "public1"
  }

  image_references = {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

// Firewalling
k3s-firewall = {
  name = "k3s-ingress"
  ingress_rules = {
    source_addresses = [ "*" ]
    destination_ports = [ "22", "80", "443" ]
    protocols = [ "TCP" ]
  }
}

// Tag References
tags = {
  "project-name" = "homelab-learning"
}

// Global Tags
global-tags = {
  "project" = "Homelab"
  "purpose" = "Learning"
}