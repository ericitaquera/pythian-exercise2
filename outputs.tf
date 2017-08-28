output "bastion_public_ip" {
        value = "${aws_instance.bastion.public_ip}"
}

output "bastion_user" {
	value = "ubuntu"
}	

data "template_file" "wordpress_url" {
	template = "$${protocol}$${alb_dns}$${blog}"
	vars {
		protocol = "http://"
		alb_dns = "${aws_alb.groo-ALB.dns_name}"
		blog = "/blog"
	}
}

output "wordpress_url" {
	value = "${data.template_file.wordpress_url.rendered}"
}



