data "template_file" "wordpress" {
	template = "${file("${path.module}/templates/wordpress_install.tpl")}"
	vars {
		rds_address = "${aws_db_instance.groowpdatabase.address}"
		alb_dns = "${aws_alb.groo-ALB.dns_name}"
		memcached_endpoint = "${aws_elasticache_cluster.groo-Memcached.configuration_endpoint}"
		dataabase_server_name ="${aws_db_instance.groowpdatabase.address}"
	}	
#	lifecycle {
#		create_before_destroy = true
#	}
}

provider "aws" {
	region = "us-east-1"

}
