variable "access_key" {}
variable "secret_key" {}

variable "instance_name"{
	default = "grooWP"
}

variable region {
  type = "map"

  default = {
    "primary" = "us-east-2"
    "backup"  = "us-east-1"
  }
}

variable keypair {
  type = "string"
  default = "groo-us-east-2"
}

variable wp_ami {
  type = "map"

  default = {
    "us-east-1" = "ami-cd0f5cb6"
    "us-east-2" = "ami-10547475"
  }
}

variable wp_type {
	default = "t2.micro"
}

variable availability_zones {
  type = "map"

  default = {
    "us-east-1" = "us-east-1a,us-east-1b,us-east-1c"
    "us-east-2" = "us-east-2a,us-east-2b,us-east-2c"
  }
}

variable vpc_name {
  default = "groo-VPC"
}

variable cidr {
  default = "10.0.16.0/20"
}

variable public_subnets {
  default = ["10.0.17.0/24", "10.0.19.0/24", "10.0.21.0/24"]
}

variable private_subnets {
  default = ["10.0.18.0/24", "10.0.20.0/24", "10.0.22.0/24"]
}

variable enable_dns_support {
  default = "true"
}

variable map_public_ip_on_launch {
  default = "true"
}

variable enable_dns_hostnames {
  default = "true"
}

variable enable_nat_gateway {
  default = "true"
}
