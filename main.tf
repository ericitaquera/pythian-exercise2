resource "template_file" "wordpress" {
	template = "${file("wordpress_install.tpl")}"
	vars {
		rds_address = "${aws_db_instance.groowpdatabase.address}"
		alb_dns = "${aws_alb.groo-ALB.dns_name}"
		memcached_endpoint = "${aws_elasticache_cluster.groo-Memcached.configuration_endpoint}"
	}	
	lifecycle {
		create_before_destroy = true
	}
}

provider "aws" {
	access_key = "${var.access_key}"
	secret_key = "${var.secret_key}"
	region = "us-east-2"

}

resource "aws_instance" "wordpress" {
	count = "3"	
	ami = "${lookup(var.wp_ami,var.region.["primary"])}"
	instance_type = "${var.wp_type}"
	subnet_id = "${element(module.vpc.private_subnets, count.index)}"
	vpc_security_group_ids = ["${aws_security_group.groo-sg-RDS.id}"]
	key_name = "${var.keypair}"
	#user_data = "${file("user_data.sh")}"
	user_data = "${template_file.wordpress.rendered}"
	tags {
		Name = "${var.instance_name}-${count.index +1}"
	}
}

resource "aws_instance" "bastion" {
	ami = "${lookup(var.wp_ami,var.region.["primary"])}"
        instance_type = "${var.wp_type}"
        subnet_id = "${element(module.vpc.public_subnets,0)}"
	vpc_security_group_ids = ["${aws_security_group.groo-sg-Web.id}"]
	key_name = "${var.keypair}"
        tags {
                Name = "groo-Bastion"
        }
}

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

resource "aws_elasticache_subnet_group" "groo-elasticache-SNG" {
  name       = "groo-elasticache-sng"
  subnet_ids = ["${module.vpc.private_subnets}"]
}

resource "aws_security_group" "groo-sg-Web" {
  name        = "groo-sg-Web"
  description = "Inbound SSH/HTTP"
  vpc_id = "${module.vpc.vpc_id}"
  tags {
    Name = "groo-sg-Web"
  }
}

resource "aws_security_group_rule" "HTTP" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.groo-sg-Web.id}"
}

resource "aws_security_group_rule" "SSH" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.groo-sg-Web.id}"
}

resource "aws_security_group_rule" "allow_all" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.groo-sg-Web.id}"
}

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

resource "aws_alb" "groo-ALB" {
  name            = "groo-ALB"
  internal        = false
  security_groups = ["${aws_security_group.groo-sg-Web.id}"]
  subnets         = ["${module.vpc.public_subnets}"]

  enable_deletion_protection = false

#  access_logs {
#    bucket = "${aws_s3_bucket.alb_logs.bucket}"
#    prefix = "test-alb"
# }

  tags {
    Environment = "production"
	Name = "groo-ALB"
  }
}

resource "aws_alb_target_group" "groo-ALB-TG" {
  name     = "groo-ALB-TG"
  port     = "80"
  protocol = "HTTP"
  vpc_id = "${module.vpc.vpc_id}"
 
health_check {
	healthy_threshold = "5"
	interval = "30"
	matcher = "200"
	path = "/"
	port = "80"
	protocol = "HTTP"
	timeout = "5"
	unhealthy_threshold = "2"
}
tags {
	Name = "groo-ALB-TG"
}	
}

resource "aws_alb_listener" "groo-Listener"{
  load_balancer_arn = "${aws_alb.groo-ALB.arn}"
  port = "80"
  protocol = "HTTP"
  
default_action {
    target_group_arn = "${aws_alb_target_group.groo-ALB-TG.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "groo-ALB-TG-Target" {
	count = "3"
	target_group_arn = "${aws_alb_target_group.groo-ALB-TG.arn}"
	target_id        = "${element(aws_instance.wordpress.*.id,count.index)}"
	port             = 80
}
	
resource "aws_db_instance" "groowpdatabase" {	
	#address = "groowpdatabase.cane12mklj8m.us-east-2.rds.amazonaws.com"
	allocated_storage = "5"
	#arn = "arn:aws:rds:us-east-2:603592623618:db:groowpdatabase"
	auto_minor_version_upgrade = "true"
	availability_zone = "us-east-2b"
	backup_retention_period = "7"
	backup_window = "04:57-05:27"
	#ca_cert_identifier = "rds-ca-2015"
	copy_tags_to_snapshot = "false"
	db_subnet_group_name = "${aws_db_subnet_group.groo-DB-SNG.id}"
	#endpoint = "groowpdatabase.cane12mklj8m.us-east-2.rds.amazonaws.com:3306"
	engine = "mysql"
	engine_version = "5.7.17"
	#hosted_zone_id = "Z2XHWR1WZ565X2"
	iam_database_authentication_enabled = "false"
	#id = "groowpdatabase"
	identifier = "groowpdatabase"
	instance_class = "db.t2.micro"
	iops = "0"
	kms_key_id = ""
	license_model = "general-public-license"
	maintenance_window = "wed:08:56-wed:09:26"
	monitoring_interval = "0"
	multi_az = "false"
	name = ""
	vpc_security_group_ids =["${aws_security_group.groo-sg-RDS.id}"]
	option_group_name = "default:mysql-5-7"
	parameter_group_name = "default.mysql5.7"
	port = "3306"
	publicly_accessible = "false"
	#resource_id = "db-OMAVPVXTTGA2CGFF3T45XOULT4"
	skip_final_snapshot = "true"
	#status = "available"
	storage_encrypted = "false"
	storage_type = "gp2"
	username = "groo"
	password = "nhanhanhanha"
	tags{
		workload-type = "other"
	}
}

resource "aws_elasticache_cluster" "groo-Memcached" {
	cluster_id = "groo-memcached"
	availability_zone = "us-east-2a"
	engine = "memcached"
	node_type = "cache.t2.micro"
	engine_version = "1.4.34"
	port = "11211"
	parameter_group_name = "default.memcached1.4"
	num_cache_nodes = "3"
	subnet_group_name = "${aws_elasticache_subnet_group.groo-elasticache-SNG.id}"
	security_group_ids = ["${aws_security_group.groo-sg-RDS.id}"]
#	cache_nodes {
#		availability_zones = ["${split(",", lookup(var.availability_zones, var.region["primary"]))}"]
#	}		

}
