output "bastion_public" {
        value = "${aws_instance.bastion.public_ip}"
}

output "alb_dns" {
	value = "${aws_alb.groo-ALB.dns_name}"
}
