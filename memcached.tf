resource "aws_elasticache_cluster" "groo-Memcached" {
        cluster_id = "groo-memcached"
        availability_zone = "${element(split(",",lookup(var.availability_zones, var.region["primary"])), 0)}"
        engine = "memcached"
        node_type = "cache.t2.micro"
        engine_version = "1.4.34"
        port = "11211"
        parameter_group_name = "default.memcached1.4"
        num_cache_nodes = "1"
        subnet_group_name = "${aws_elasticache_subnet_group.groo-elasticache-SNG.id}"
        security_group_ids = ["${aws_security_group.internal-ALL.id}"]
}

resource "aws_elasticache_subnet_group" "groo-elasticache-SNG" {
  name       = "groo-elasticache-sng"
  subnet_ids = ["${module.vpc.private_subnets}"]
}
