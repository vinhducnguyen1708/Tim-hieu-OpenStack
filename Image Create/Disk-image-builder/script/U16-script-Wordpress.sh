#!/usr/bin/env bash
echo "$(tput setaf 2)##### setup upgrade #####$(tput sgr0)"
sleep 3
apt-get upgrade
echo "$(tput setaf 2)##### setup apache2 #####$(tput sgr0)"
apt-get install -qq apache2 apache2-utils

echo "$(tput setaf 2)##### setupMYSQL #####$(tput sgr0)"
apt-get update    
# Install MySQL without password prompt
# Set username and password to 'root'
debconf-set-selections <<< "mysql-server mysql-server/root_password password 123"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password 123"
# Install MySQL Server
# -qq implies -y --force-yes
apt-get install -qq   mysql-server
# Make MySQL connectable from outside world without SSH tunnel
sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Install PHP7.0
echo "$(tput setaf 2)##### setup PHP #####$(tput sgr0)"
apt-get install -qq php7.0 php7.0-mysql libapache2-mod-php7.0 php7.0-cli php7.0-cgi php7.0-gd  

cat <<EOF > /var/www/html/info.php
<?php 
phpinfo();
?>
EOF
echo "$(tput setaf 2)##### Download-Wordpress #####$(tput sgr0)"
wget -c http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
rsync -av wordpress/* /var/www/html/
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/


