resource "aws_instance" "bastion" {
        ami = "${lookup(var.wp_ami,var.region.["primary"])}"
        instance_type = "${var.wp_type}"
        subnet_id = "${element(module.vpc.public_subnets,0)}"
        vpc_security_group_ids = ["${aws_security_group.trusted-ingress-SSH.id}","${aws_security_group.trusted-egress-SSH.id}","${aws_security_group.internet-egress-HTTP.id}"]
        key_name = "${var.keypair}"
        tags {
                Name = "groo-Bastion"
        }
}

resource "aws_alb" "groo-ALB" {
  name            = "groo-ALB"
  internal        = false
  security_groups = ["${aws_security_group.internet-ingress-HTTP.id}","${aws_security_group.internet-egress-HTTP.id}"]
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

