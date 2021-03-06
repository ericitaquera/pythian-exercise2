resource "aws_db_instance" "groowpdatabase" {
        #address = "groowpdatabase.cane12mklj8m.us-east-2.rds.amazonaws.com"
        allocated_storage = "5"
        #arn = "arn:aws:rds:us-east-2:603592623618:db:groowpdatabase"
        auto_minor_version_upgrade = "true"
        availability_zone = "${element(split(",",lookup(var.availability_zones, var.region["primary"])), 0)}"
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
        vpc_security_group_ids =["${aws_security_group.internal-ingress-MySQL.id}","${aws_security_group.internal-egress-MySQL.id}"]
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
