#!/bin/sh

apt-get update
apt-get install wordpress -y

cd /etc/apache2/sites-available/
wget https://s3.us-east-2.amazonaws.com/groo-wordpress-files/wordpress.conf

a2ensite wordpress

cd /etc/wordpress/

wget https://s3.us-east-2.amazonaws.com/groo-wordpress-files/config.php

sed -i 's/DB_HOST_VARIABLE/${rds_address}/' config.php

mv config.php config-$(echo ${alb_dns}.php | tr [:upper:] [:lower:])

cd /tmp

wget https://s3.us-east-2.amazonaws.com/groo-wordpress-files/wordpress.sql

mysql -u groo -pnhanhanhanha -h groowpdatabase.cane12mklj8m.us-east-2.rds.amazonaws.com < wordpress.sql

cd /var/www/html/

wget https://s3.us-east-2.amazonaws.com/groo-wordpress-files/phpinfo.php

sed -i 's/^session.save_handler.*/session.save_handler\ =\ memcache/' /etc/php/7.0/apache2/php.ini
sed -i 's/^\;session.save_path.*/session.save_path\ =\ \"tcp\:\/\/${memcached_endpoint}\"/' /etc/php/7.0/apache2/php.ini

systemctl reload apache2.service

