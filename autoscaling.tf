resource "aws_autoscaling_group" "groo-ASG" {
	launch_configuration = "${aws_launch_configuration.groo-LaunchConfiguration.name}"
	min_size = "3"
	max_size = "3"
	desired_capacity = "3"
	health_check_grace_period = "150"
	health_check_type = "ELB"
	vpc_zone_identifier = ["${module.vpc.private_subnets}"]
	target_group_arns = ["${aws_alb_target_group.groo-ALB-TG.arn}"]
	tags {
		key = "Name"
		propagate_at_launch = "true"
		value = "groo-ASG"
	}
}

resource "aws_launch_configuration" "groo-LaunchConfiguration" {
        image_id = "${lookup(var.wp_ami,var.region.["primary"])}"
        instance_type = "${var.wp_type}"
	name = "groo-LaunchConfiguration"
	key_name = "${var.keypair}"
	enable_monitoring = "false"
	user_data = "${data.template_file.wordpress.rendered}"
	security_groups = ["${aws_security_group.internal-ALL.id}","${aws_security_group.internet-egress-HTTP.id}","${aws_security_group.internet-egress-HTTPS.id}"]
}
