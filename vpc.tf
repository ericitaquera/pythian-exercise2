module "vpc" {
  source = "github.com/terraform-community-modules/tf_aws_vpc"

  name = "${var.vpc_name}"

  cidr = "${var.cidr}"
  public_subnets = "${var.public_subnets}"

  private_subnets = "${var.private_subnets}"
  enable_dns_support = "${var.enable_dns_support}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_nat_gateway = "${var.enable_nat_gateway}"

  azs      = ["${split(",", lookup(var.availability_zones, var.region["primary"]))}"]

}

resource "aws_db_subnet_group" "groo-DB-SNG" {
  name       = "groo-db-sng"
  subnet_ids = ["${module.vpc.private_subnets}"]

  tags {
    Name = "groo-DB-SubnetGroup"
  }
}

resource "aws_security_group" "trusted-ingress-SSH" {
	name = "trusted-ingress-SSH"
	description = "Trusted Ingress SSH"
	vpc_id = "${module.vpc.vpc_id}"
	ingress {
		from_port   = 22
		to_port     = 22
		protocol    = "TCP"
		cidr_blocks = "${var.trusted_ips}"
	}
	tags {
		Name = "trusted-ingress-SSH"
	}
}

resource "aws_security_group" "trusted-egress-SSH" {
	name = "trusted-egress-SSH"
	description = "Trusted Egress SSH"
	vpc_id = "${module.vpc.vpc_id}"
	egress {
		from_port   = 0
		to_port     = 65535
		protocol    = "TCP"
		cidr_blocks = "${var.trusted_ips}"
	}
	tags {
		Name = "trusted-egress-SSH"
	}
}

resource "aws_security_group" "internet-ingress-HTTP" {
        name = "internet-ingress-HTTP"
        description = "Internet Ingress HTTP"
        vpc_id = "${module.vpc.vpc_id}"
        ingress {
                from_port   = 80
                to_port     = 80
                protocol    = "TCP"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags {
                Name = "internet-ingress-HTTP"
        }
}

resource "aws_security_group" "internet-egress-HTTP" {
        name = "internet-egress-HTTP"
        description = "Internet Egress HTTP"
        vpc_id = "${module.vpc.vpc_id}"
        egress {
                from_port   = 80
                to_port     = 80
                protocol    = "TCP"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags {
                Name = "internet-egress-HTTP"
        }
}

resource "aws_security_group" "internet-egress-HTTPS" {
        name = "internet-egress-HTTPS"
        description = "Internet Egress HTTPS"
        vpc_id = "${module.vpc.vpc_id}"
        egress {
                from_port   = 443
                to_port     = 443
                protocol    = "TCP"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags {
                Name = "internet-egress-HTTPS"
        }
}

resource "aws_security_group" "internal-ingress-MySQL" {
        name = "internal-ingress-MySQL"
        description = "Internal Ingress MySQL"
        vpc_id = "${module.vpc.vpc_id}"
        ingress {
                from_port   = 3306
                to_port     = 3306
                protocol    = "TCP"
                cidr_blocks = ["10.0.16.0/20"]
        }
        tags {
                Name = "internal-ingress-MySQL"
        }
}

resource "aws_security_group" "internal-egress-MySQL" {
        name = "internal-egress-MySQL"
        description = "Internal Egress MySQL"
        vpc_id = "${module.vpc.vpc_id}"
        egress {
                from_port   = 3306
                to_port     = 3306
                protocol    = "TCP"
                cidr_blocks = ["10.0.16.0/20"]
        }
        tags {
                Name = "Internal-egress-MySQL"
        }
}

resource "aws_security_group" "internal-ALL" {
        name = "internal-ALL"
        description = "Internal allow ALL"
        vpc_id = "${module.vpc.vpc_id}"
        ingress {
                from_port   = 0
                to_port     = 65535
                protocol    = "TCP"
                cidr_blocks = ["10.0.16.0/20"]
        }
		egress {
                from_port   = 0
                to_port     = 65535
                protocol    = "TCP"
                cidr_blocks = ["10.0.16.0/20"]
        }
        tags {
                Name = "internal-ALL"
        }
}

#resource "aws_security_group" "groo-sg-Web" {
#  name        = "groo-sg-Web"
#  description = "Inbound SSH/HTTP"
#  vpc_id = "${module.vpc.vpc_id}"
#  tags {
#    Name = "groo-sg-Web"
#  }
#}

#resource "aws_security_group_rule" "HTTP" {
#  type            = "ingress"
#  from_port       = 80
#  to_port         = 80
#  protocol        = "tcp"
#  cidr_blocks     = ["0.0.0.0/0"]
#  security_group_id = "${aws_security_group.groo-sg-Web.id}"
#}

#resource "aws_security_group_rule" "SSH" {
#  type            = "ingress"
#  from_port       = 22
#  to_port         = 22
#  protocol        = "tcp"
#  cidr_blocks     = ["0.0.0.0/0"]
#  security_group_id = "${aws_security_group.groo-sg-Web.id}"
#}

#resource "aws_security_group_rule" "allow_all" {
#  type            = "egress"
#  from_port       = 0
#  to_port         = 65535
#  protocol        = "tcp"
#  cidr_blocks     = ["0.0.0.0/0"]
#  security_group_id = "${aws_security_group.groo-sg-Web.id}"
#}

resource "aws_security_group" "groo-sg-RDS" {
  name        = "groo-sg-RDS"
  description = "Internal Traffic"
  vpc_id = "${module.vpc.vpc_id}"
  tags {
    Name = "groo-sg-RDS"
  }
}

resource "aws_security_group_rule" "MySQL" {
  type            = "ingress"
  from_port       = 3306
  to_port         = 3306
  protocol        = "tcp"
  security_group_id = "${aws_security_group.groo-sg-RDS.id}"
  source_security_group_id = "${aws_security_group.groo-sg-RDS.id}"
}

resource "aws_security_group_rule" "Internal" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["${var.cidr}"]
  security_group_id = "${aws_security_group.groo-sg-RDS.id}"
}

resource "aws_security_group_rule" "Outbound" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.groo-sg-RDS.id}"
}
