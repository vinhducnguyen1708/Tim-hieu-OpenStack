#!/usr/bin/env bash

#Upgrade
echo "$(tput setaf 2)##### Update #####$(tput sgr0)"
sleep 3
apt-get upgrade

#InstallMysql
echo "$(tput setaf 2)##### setupMYSQL #####$(tput sgr0)"
sleep 3

apt-get update    
# Install MySQL without password prompt
# Set username and password to 'root'
debconf-set-selections <<< "mysql-server mysql-server/root_password password 123"

debconf-set-selections <<< "mysql-server mysql-server/root_password_again password 123"

# Install MySQL Server
# -qq implies -y --force-yes
apt-get install -qq mysql-client mysql-server -y
# Make MySQL connectable from outside world without SSH tunnel
 sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

#installApache2
echo "$(tput setaf 2)##### installApache2 #####$(tput sgr0)"
sleep 3
apt-get install apache2 apache2-utils -y
sudo systemctl enable apache2
sudo systemctl start apache2
sudo sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/" /etc/apache2/apache2.conf

#InstallPHP7.1
echo "$(tput setaf 2)##### InstallPHP7 #####$(tput sgr0)"
sleep 3
apt-get install software-properties-common 
#Add key
 apt-key adv --keyserver keyserver.ubuntu.com --recv-keys  4F4EA0AAE5267A6C
#Install PHP 7.1 
 add-apt-repository ppa:ondrej/php -y
 apt-get update
 apt install php7.1 libapache2-mod-php7.1 libapache2-mod-php7.1 php7.1-common php7.1-mbstring php7.1-xmlrpc php7.1-soap php7.1-gd php7.1-xml php7.1-intl php7.1-mysql php7.1-cli php7.1-mcrypt php7.1-ldap php7.1-zip php7.1-curl php7.1-bcmath -y

#setupMagento
echo "$(tput setaf 2)##### setupMagento #####$(tput sgr0)"
sleep 3
mkdir /var/www/html/magento/

curl   https://transfer.sh/xr89H/Magento-CE-2.3.3-2019-09-26-03-55-22.tar.bz2 -o /var/www/html/magento/Magento-CE-2.3.3-2019-09-26-03-55-22.tar.bz2  --create-dirs
tar -xjf /var/www/html/magento/Magento-CE-2.3.3-2019-09-26-03-55-22.tar.bz2 -C /var/www/html/magento/
sudo chown -R www-data:www-data /var/www/html/magento
sudo chmod -R 755 /var/www/html/magento

cat <<EOF > /etc/apache2/sites-available/magento.conf
<VirtualHost *:80>
	ServerAdmin admin@example.com
	DocumentRoot /var/www/html/magento/
	ServerName example.com
	ServerAlias www.example.com
	<Directory /var/www/html/magento/>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
		Order allow,deny
		allow from all
	</Directory>
		ErrorLog ${APACHE_LOG_DIR}/error.log
		CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
echo "$(tput setaf 2)##### Restart service #####$(tput sgr0)"
sleep 3
sudo a2ensite magento.conf
sudo a2enmod rewrite
sudo systemctl restart apache2.service
# Create directoty to run script after boot VM
echo "$(tput setaf 2)##### Create directoty to run script after boot Vm #####$(tput sgr0)"

