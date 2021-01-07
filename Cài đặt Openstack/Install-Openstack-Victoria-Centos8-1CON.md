# Cài đặt và cấu hình hệ thống Openstack phiên bản Victoria
# Mục lục
- [1. Yêu cầu](#1)
- [2. Mô hình](#2)
- [3. Cài đặt](#3)
    - [3.1 Cài đặt các yêu cầu cơ bản](#3.1)
    - [3.2 Cài đặt và cấu hình NTP](#3.2)
    - [3.3 Cài đặt repo để cài Openstack Victoria](#3.3)
    - [3.4 Cài đặt SQL](#3.4)
    - [3.5 Cài đặt RabbitMQ](#3.5)
    - [3.6 Cài đặt Memcache](#3.6)
    - [3.7 Cài đặt thành phần Keystone](#3.7)
    - [3.8 Cài đặt thành phần Glance ](#3.8)
    - [3.9 Cài đặt thành phần Placement](#3.9)
    - [3.10 Cài đặt thành phần Nova ](#3.10)
    - [3.11 Cài đặt thành phần Neutron](#3.11)
    - [3.12 Cấu hình Network](#3.12)
    - [3.13 Cài đặt thành phần Horizon](#3.13)
    - [3.14 Cài đặt thành phần Cinder](#3.14)
- [4. Kiểm tra sau khi cài đặt](#4)


## 1. Yêu cầu <a name = '1'></a>
- 1.1 Server controller
    - OS: Centos8
    - Network: 2 NIC
        - 192.168.10.93/24
        - 192.168.20.93/24
    - RAM: 8GIB 
    - vCPUs: 6
    - Disks:
        - 30GIB
        - 50GIB

- 1.2 Server compute
    - OS: Centos8
    - Network: 2 NIC
        - 192.168.10.92/24
        - 192.168.20.92/24
    - RAM: 8GIB 
    - vCPUs: 4
    - Disks:
        - 50GIB



## 2. Mô hình <a name = '2'></a>

![ima](../images/victoria_1con-1.png)


## 3. Cài đặt <a name = '3'></a>

### 3.1 Cài đặt các yêu cầu cơ bản <a name = '3.1'></a>

- Update packages cho OS:
```sh
sudo dnf -y update
```

- Cài đặt gói bổ trợ:
```sh
dnf -y install epel-release
dnf -y --enablerepo=epel update
```

- Cài đặt các tools cần thiết:
```sh
sudo dnf -y install vim wget curl telnet bash-completion dnf-utils
```

- Tắt và disable firewall:
```sh
systemctl disable firewalld
systemctl stop firewalld
```

- Disable Selinux
```sh
sudo setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

- Cài đặt network-scripts để quản lý network dưới dạng file
```sh
dnf install -y network-scripts

systemctl enable network && sudo systemctl start network

touch /etc/sysconfig/disable-deprecation-warnings
```
**Thực hiện trên node controller**

- Cấu hình IP cho các interfaces ( sử dụng Network manager )
```sh
# Setup IP ens3 
nmcli c modify ens3 ipv4.addresses 192.168.10.93/24
nmcli c modify ens3 ipv4.gateway 192.168.10.1
nmcli c modify ens3 ipv4.dns 8.8.8.8
nmcli c modify ens3 ipv4.method manual
nmcli con mod ens3 connection.autoconnect yes


# Setup IP ens4
nmcli c modify ens4 ipv4.addresses 192.168.20.93/24
nmcli c modify ens4 ipv4.method manual
nmcli con mod ens4 connection.autoconnect yes
```

- Đặt hostname:
```sh
hostnamectl set-hostname controller
```

**Thực hiện trên node compute**
- Cấu hình IP cho các interfaces ( sử dụng Network manager )
```sh
# Setup IP ens3 
nmcli c modify ens3 ipv4.addresses 192.168.10.92/24
nmcli c modify ens3 ipv4.gateway 192.168.10.1
nmcli c modify ens3 ipv4.dns 8.8.8.8
nmcli c modify ens3 ipv4.method manual
nmcli con mod ens3 connection.autoconnect yes


# Setup IP ens4
nmcli c modify ens4 ipv4.addresses 192.168.20.92/24
nmcli c modify ens4 ipv4.method manual
nmcli con mod ens4 connection.autoconnect yes
```

- Đặt hostname:
```sh
hostnamectl set-hostname compute1
```


**Thực hiện trên cả 2 node**

- Cập nhật file `/etc/hosts` bằng các dòng sau
```sh
cat >> /etc/hosts << "EOF"
192.168.10.93 controller
192.168.10.92 compute1
EOF
```
- Khởi động lại máy:
```sh
init 6
```
### 3.2 Cài đặt cấu hình NTP <a name = '3.2'></a>

**Thực hiện trên cả 2 node**

- Cài gói chrony
```sh
dnf -y install chrony
```

- Sửa file `/etc/chrony.conf` như sau:
    - Comment dòng sau:
    ```
    #server 0.centos.pool.ntp.org iburst
    #server 1.centos.pool.ntp.org iburst
    #server 2.centos.pool.ntp.org iburst
    #server 3.centos.pool.ntp.org iburst
    ```
    - Thêm các dòng:
    ```
    server 1.vn.poo.ntp.org iburst
    server 0.asia.pool.ntp.org iburst
    server 3.asia.pool.ntp.org iburst

    allow 192.168.10.0/24
    ```
- Enable và khởi động lại dịch vụ
```sh
systemctl enable chronyd.service
systemctl restart chronyd.service
```   

- Kiểm tra lại hoạt động của NTP bằng lệnh dưới:
```sh
[root@controller ~]# chronyc sources
210 Number of sources = 2
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^- time1.isu.net.sa              2  10   377   44m    -15ms[  -17ms] +/-  341ms
^* 202-65-114-202.jogja.cit>     2  10   377   314  +1280us[+1451us] +/-  137ms
```

### 3.3  Cài đặt repo để cài Openstack Victoria <a name = '3.3'></a>

**Thực hiện trên cả 2 node**

- Cài đặt gói để cài Openstack Victoria
```sh
dnf config-manager --enable powertools

dnf install -y centos-release-openstack-victoria

dnf --enablerepo=centos-openstack-victoria -y upgrade
```

- Cài đặt Openstack Selinux
```sh
dnf --enablerepo=centos-openstack-victoria,epel,powertools -y install openstack-selinux
```

### 3.4 Cài đặt SQL Database <a name = '3.4'></a>

**Thực hiện cài đặt trên node controller**

- Cài đặt Mariadb:
```sh
dnf module -y install mariadb:10.3
```

- Cấu hình Mariadb

```sh
cat << EOF > /etc/my.cnf.d/openstack.cnf
[server]
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-error=/var/log/mariadb/mariadb.log
pid-file=/run/mariadb/mariadb.pid
character-set-server=utf8
bind-address = 0.0.0.0
max_connections = 102400
[galera]
[embedded]
[mariadb]
[mariadb-10.3]
EOF
```
- Kích hoạt dịch vụ MariaDB tự chạy khi khởi động hệ thống
```sh
systemctl enable --now mariadb
```

- Thiết lập mật khẩu tài khoản cho root
```sh
mysql_secure_installation
```
Ta sẽ để mật khẩu là `Welcome123`

### 3.5 Cài đặt RabbitMQ <a name = '3.5'></a>

**Thực hiện cài đặt trên node controller**

- Cài đặt gói:
```sh
dnf --enablerepo=powertools -y install rabbitmq-server 
```

- Khởi động dịch vụ RabbitMQ
```sh
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service
```

- Cấu hình RabbitMQ, tạo user openstack với mật khẩu là `Welcome123`
```sh
rabbitmqctl add_user openstack Welcome123
```

- Gán quyền read, write cho tài khoản openstack trong RabbitMQ
```sh
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
```

### 3.6 Cài đặt Memcache <a name = '3.6'></a>

**Thực hiện cài đặt trên node controller**

- Cài đặt gói:
```sh
dnf --enablerepo=powertools -y install memcached
```

- Cấu hình
```sh
sed -i -e "s/-l 127.0.0.1,::1/-l 127.0.0.1,::1,controller/g" /etc/sysconfig/memcached
```

- Enable và start dịch vụ Memcached
```sh
systemctl enable memcached.service
systemctl start memcached.service
```

### 3.7 Cài đặt thành phần Keystone <a name = '3.7'></a>

**Thực hiện trên node controller**

- Tạo Database cho Keystone
```sh
        cat << EOF | mysql -uroot -pWelcome123
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'192.168.10.93' IDENTIFIED BY 'Welcome123';
EOF
```

- Cài đặt Keystone
```sh
dnf --enablerepo=centos-openstack-victoria,epel,powertools -y install openstack-keystone python3-openstackclient httpd mod_ssl python3-mod_wsgi python3-oauth2client
```
- Sao lưu lại file cấu hình

```sh
keystonefile=/etc/keystone/keystone.conf
keystonefilebak=/etc/keystone/keystone.conf.bak
mv $keystonefile  $keystonefilebak
```
- Cấu hình Keystone

```sh 
cat << EOF > /etc/keystone/keystone.conf
[DEFAULT]
[application_credential]
[assignment]
[auth]
[cache]
[catalog]
[cors]
[credential]
[database]
connection = mysql+pymysql://keystone:Welcome123@192.168.10.93/keystone
[domain_config]
[endpoint_filter]
[endpoint_policy]
[eventlet_server]
[federation]
[fernet_receipts]
[fernet_tokens]
[healthcheck]
[identity]
[identity_mapping]
[jwt_tokens]
[ldap]
[memcache]
[oauth1]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[policy]
[profiler]
[receipt]
[resource]
[revoke]
[role]
[saml]
[security_compliance]
[shadow_users]
[token]
provider = fernet
[tokenless_auth]
[totp]
[trust]
[unified_limit]
[wsgi]
EOF
```

- Phân quyền file cấu hình
```sh
chown root:keystone /etc/keystone/keystone.conf
```

- Đồng bộ Database cho Keystone
```sh
su -s /bin/sh -c "keystone-manage db_sync" keystone
```

- Thiết lập tạo fernet key
```sh
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
```

- Bootstrap Keystone:
```sh
keystone-manage bootstrap --bootstrap-password Welcome123   --bootstrap-admin-url http://192.168.10.93:5000/v3/   --bootstrap-internal-url http://192.168.10.93:5000/v3/   --bootstrap-public-url http://192.168.10.93:5000/v3/   --bootstrap-region-id Hanoi
```

**Cấu hình Apache cho Keystone**

- Sửa file `/etc/httpd/conf/httpd.conf`:
```sh
sed -i -e "s/^Listen.*/Listen controller:80/g" /etc/httpd/conf/httpd.conf
```

- Tạo link tới file `/usr/share/keystone/wsgi-keystone.conf`
```sh
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
```
- Khởi động lại dịch vụ HTTPD
```sh
systemctl enable httpd.service
systemctl restart httpd.service
```
**Khởi tạo dịch vụ cho Keystone**

- Tạo file khai báo biến môi trường cho Keystone
```sh
cat << EOF > /root/admin-openrc
export OS_USERNAME=admin
export OS_PASSWORD=Welcome123
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://192.168.10.93:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF
```

- Truy xuất vào môi trường
```sh
source /root/admin-openrc
```

- Tạo project service
```sh
openstack project create --domain default \
  --description "Service Project" service
```

- Tạo project demo:
```sh
openstack project create --domain default \
  --description "Demo Project" demo
```

- Tạo user demo
```sh
openstack user create --domain default \
  --password Welcome123 demo
```

- Tạo role user
```sh
openstack role create user
```

- Thêm role user cho user demo trên project demo
```sh
openstack role add --project demo --user demo user
```

- Kiểm tra sau khi cài đặt 
```sh
openstack token issue
```


### 3.8 Cài đặt dịch vụ Image (glance) <a name = '3.8'></a>

**Thực hiện trên node controller**

- Tạo database cho Glance
```sh
	cat << EOF | mysql -uroot -pWelcome123
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'192.168.10.93' IDENTIFIED BY 'Welcome123';
EOF
```

- Tạo user glance
```sh
openstack user create --domain default --password Welcome123 glance
```

- Thêm role admin cho user glance trên project service
```sh
openstack role add --project service --user glance admin
```

- Tạo dịch vụ có tên glance
```sh
openstack service create --name glance \
  --description "OpenStack Image" image
```
- Tạo các endpoint cho dịch vụ glance
```sh
openstack endpoint create --region Hanoi image public http://192.168.10.93:9292

openstack endpoint create --region Hanoi image internal http://192.168.10.93:9292

openstack endpoint create --region Hanoi image admin http://192.168.10.93:9292
```

- Cài đặt gói glance
```sh
dnf --enablerepo=centos-openstack-victoria,powertools,epel -y install openstack-glance
```

- Sao lưu file cấu hình gốc
```sh
glanceapifile=/etc/glance/glance-api.conf
glanceapifilebak=/etc/glance/glance-api.conf.bak
mv $glanceapifile $glanceapifilebak
```

- Cấu hình:
```sh
cat << EOF > /etc/glance/glance-api.conf
[DEFAULT]
bind_host = 0.0.0.0

[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

[database]
# MariaDB connection info
connection = mysql+pymysql://glance:Welcome123@192.168.10.93/glance

# keystone auth info
[keystone_authtoken]
www_authenticate_uri = http://192.168.10.93:5000
auth_url = http://192.168.10.93:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = Welcome123

[paste_deploy]
flavor = keystone
EOF
```
- Phân quyền cho thư mục vừa tạo:
```sh
chmod 640 /etc/glance/glance-api.conf
chown root:glance /etc/glance/glance-api.conf
```

- Đồng bộ database glance
```sh
su -s /bin/sh -c "glance-manage db_sync" glance
```

- Enable và start dịch vụ Glance
```sh
systemctl enable openstack-glance-api.service 
systemctl restart openstack-glance-api.service  
```

- Download images Cirros
```sh
wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
```

- Upload images lên Openstack 
```sh
source /root/admin-openrc

openstack image create "Image Cirros"  --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --public
```

- Kiểm tra bằng lệnh:
```sh
openstack image list
```


### 3.9 Cài dịch vụ placement <a name = '3.9'></a>
 
**Thực hiện trên node controller**

- Tạo database cho Placement
```sh
    cat << EOF | mysql -uroot -pWelcome123
CREATE DATABASE placement;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'Welcome123';
EOF
```

- Tạo user, service cho Placement
```sh
source /root/admin-openrc

openstack user create --domain default --password Welcome123 placement

openstack role add --project service --user placement admin

openstack service create --name placement --description "Placement API" placement

```

- Tạo endpoints cho Placement
```sh
openstack endpoint create --region Hanoi placement public http://192.168.10.93:8778

openstack endpoint create --region Hanoi placement internal http://192.168.10.93:8778

openstack endpoint create --region Hanoi placement admin http://192.168.10.93:8778
```

- Cài đặt gói placement
```sh
 dnf --enablerepo=centos-openstack-victoria,powertools,epel -y install openstack-placement-api
```
- Sao lưu file cấu hình gốc
```sh
placementfile=/etc/placement/placement.conf
placementfilebak=/etc/placement/placement.conf.bak
mv $placementfile $placementfilebak
```

- Cấu hình 
```sh
cat << EOF > /etc/placement/placement.conf
[DEFAULT]
debug = false

[api]
auth_strategy = keystone

[keystone_authtoken]
www_authenticate_uri = http://192.168.10.93:5000
auth_url = http://192.168.10.93:5000
memcached_servers = 192.168.10.93:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = placement
password = Welcome123

[placement_database]
connection = mysql+pymysql://placement:Welcome123@192.168.10.93/placement
EOF
```

- Phân quyền cho file cấu hình
```sh
chmod 640 /etc/placement/placement.conf
chgrp placement /etc/placement/placement.conf
```
- Đồng bộ database placement
```sh
su -s /bin/sh -c "placement-manage db sync" placement
```

- Cấu hình http cho placement-api
```sh
cat << 'EOF' >> /etc/httpd/conf.d/00-placement-api.conf

<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>
EOF
```

- Khởi động lại dịch vụ HTTP
```sh
systemctl restart httpd
```

### 3.10 Cài dịch vụ compute (Nova) <a name = '3.10'></a>

**Thực hiện trên node controller**

- Tạo database cho nova
```sh
     cat << EOF | mysql -uroot -pWelcome123
CREATE DATABASE nova_api;
CREATE DATABASE nova;
CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';
EOF
```

- Tạo dịch vụ , user cho Nova
```sh
source /root/admin-openrc

openstack user create --domain default --password Welcome123 nova

openstack role add --project service --user nova admin

openstack service create --name nova --description "OpenStack Compute" compute
```

- Tạo endpoint cho Nova
```sh
openstack endpoint create --region Hanoi compute public http://192.168.10.93:8774/v2.1

openstack endpoint create --region Hanoi compute internal http://192.168.10.93:8774/v2.1

openstack endpoint create --region Hanoi compute admin http://192.168.10.93:8774/v2.1
```

- Cài đặt gói
```sh
dnf --enablerepo=centos-openstack-victoria,powertools,epel -y install openstack-nova 
```

- Sao lưu file cấu hình gốc
```sh
novafile=/etc/nova/nova.conf
novafilebak=/etc/nova/nova.conf.bak
mv $novafile $novafilebak
```

- Cấu hình
```sh
cat << EOF > /etc/nova/nova.conf 
[DEFAULT]
# define own IP address
my_ip = 192.168.10.93
state_path = /var/lib/nova
enabled_apis = osapi_compute,metadata
log_dir = /var/log/nova
# RabbitMQ connection info
transport_url = rabbit://openstack:Welcome123@192.168.10.93:5672/

[api]
auth_strategy = keystone

[cinder]
os_region_name = Hanoi
catalog_info = volumev3:cinderv3:internalURL
auth_url = http://192.168.10.93:5000/
auth_type = password
project_domain_name = default
user_domain_id = default
project_name = service
username = cinder
password = Welcome123

# Glance connection info
[glance]
api_servers = http://192.168.10.93:9292

[oslo_concurrency]
lock_path = $state_path/tmp

# MariaDB connection info
[api_database]
connection = mysql+pymysql://nova:Welcome123@192.168.10.93/nova_api

[database]
connection = mysql+pymysql://nova:Welcome123@192.168.10.93/nova

# Keystone auth info
[keystone_authtoken]
www_authenticate_uri = http://192.168.10.93:5000
auth_url = http://192.168.10.93:5000
memcached_servers = 192.168.10.93:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = Welcome123

[placement]
auth_url = http://192.168.10.93:5000
os_region_name = Hanoi
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = placement
password = Welcome123

[wsgi]
api_paste_config = /etc/nova/api-paste.ini
[oslo_concurrency]
lock_path = /var/lib/nova/tmp


[neutron]
url = http://192.168.10.93:9696
auth_url = http://192.168.10.93:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = Hanoi
project_name = service
username = neutron
password = Welcome123
service_metadata_proxy = true
metadata_proxy_shared_secret = 5b721855305f81836b04


[vnc]
enabled = true
server_listen = 192.168.10.93
server_proxyclient_address = 192.168.10.93
EOF
```

- Phân quyền cho file cấu hình
```sh
 chmod 640 /etc/nova/nova.conf
 chgrp nova /etc/nova/nova.conf
```

- Đồng bộ database Nova
```sh
su -s /bin/sh -c "nova-manage api_db sync" nova

su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

su -s /bin/sh -c "nova-manage db sync" nova
```

- Kiểm tra lại bằng lệnh 
```sh
nova-manage cell_v2 list_cells
```

- Khởi động và enable dịch vụ
```sh
systemctl start  openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-conductor.service   openstack-nova-novncproxy.service
    
systemctl enable openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-conductor.service   openstack-nova-novncproxy.service
```
**Thực hiện trên node compute**

- Cài đặt gói Nova compute
```sh
dnf --enablerepo=centos-openstack-victoria,powertools,epel -y install openstack-nova-compute libvirt-client
```

- Sao lưu file cấu hình gốc
```sh
    novafile=/etc/nova/nova.conf
    novafilebak=/etc/nova/nova.conf.bak
    mv $novafile $novafilebak
```

- Cấu hình nova-compute
```sh
cat << EOF > /etc/nova/nova.conf
[DEFAULT]
my_ip = 192.168.10.92
transport_url = rabbit://openstack:Welcome123@192.168.10.93:5672
enabled_apis = osapi_compute,metadata
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
[api]
auth_strategy = keystone
[api_database]
[barbican]
[cache]
[cinder]
os_region_name = Hanoi
catalog_info = volumev3:cinderv3:internalURL
auth_url = http://192.168.10.93:5000/
auth_type = password
project_domain_name = default
user_domain_id = default
project_name = service
username = cinder
password = Welcome123
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[cyborg]
[database]
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
api_servers = http://192.168.10.93:9292
[guestfs]
[healthcheck]
[hyperv]
[image_cache]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
www_authenticate_uri = http://192.168.10.93:5000
auth_url = http://192.168.10.93:5000
memcached_servers = 192.168.10.93:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = Welcome123
[libvirt]
[metrics]
[mks]
[neutron]
url = http://192.168.10.93:9696
auth_url = http://192.168.10.93:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = Hanoi
project_name = service
username = neutron
password = Welcome123
service_metadata_proxy = true
metadata_proxy_shared_secret = 5b721855305f81836b04
[notifications]
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[pci]
[placement]
region_name = Hanoi
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://192.168.10.93:5000/v3
username = placement
password = Welcome123
[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
[service_user]
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = $my_ip
novncproxy_base_url = http://192.168.10.93:6080/vnc_auto.html
[workarounds]
[wsgi]
[xenserver]
[zvm]
EOF
```

- Phân quyền cho file cấu hình
```sh
 chmod 640 /etc/nova/nova.conf
 chgrp nova /etc/nova/nova.conf
```

- Enable và khởi động lại dịch vụ
```sh
    systemctl enable libvirtd.service openstack-nova-compute.service
    systemctl restart libvirtd.service openstack-nova-compute.service
```

### 3.11 Cài dịch vụ Network ( Neutron ) <a name = '3.11'></a>

**Thực hiện trên node controller**

- Tạo database cho Neutron
```sh
    cat << EOF | mysql -uroot -pWelcome123
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'Welcome123';
EOF
```

- Tạo dịch vụ và user cho neutron
```sh
    openstack user create --domain default --password Welcome123 neutron
    openstack role add --project service --user neutron admin
    openstack service create --name neutron  --description "OpenStack Networking" network
```

- Tạo endpoints cho dịch vụ Neutron
```sh
    openstack endpoint create --region Hanoi network public http://192.168.10.93:9696
    openstack endpoint create --region Hanoi network internal http://192.168.10.93:9696
    openstack endpoint create --region Hanoi network admin http://192.168.10.93:9696
```

- Cài đặt gói Neutron
```sh
dnf --enablerepo=centos-openstack-victoria,powertools,epel -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch ebtables libibverbs
```

- Sao lưu file cấu hình gốc
```sh
    neutronfile=/etc/neutron/neutron.conf
    neutronfilebak=/etc/neutron/neutron.conf.bak
    mv $neutronfile $neutronfilebak
```

- Cấu hình neutron-server
```sh
cat << EOF > /etc/neutron/neutron.conf
[DEFAULT]
bind_host = 192.168.10.93
bind_port = 9696
core_plugin = ml2
service_plugins = router,qos,neutron.services.metering.metering_plugin.MeteringPlugin
advertise_mtu = true
allow_overlapping_ips = true
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true
transport_url = rabbit://openstack:Welcome123@192.168.10.93:5672
auth_strategy = keystone
metadata_proxy_socket = /var/lib/neutron/metadata_proxy
[cors]
[database]
connection = mysql+pymysql://neutron:Welcome123@192.168.10.93/neutron
[keystone_authtoken]
www_authenticate_uri = http://192.168.10.93:5000
auth_url = http://192.168.10.93:5000
memcached_servers = 192.168.10.93:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = Welcome123
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[privsep]
[ssl]
[nova]
auth_url = http://192.168.10.93:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = Hanoi
project_name = service
username = nova
password = Welcome123
[qos]
notification_drivers = message_queue
EOF
```


- Cấu hình l3_agent
```sh
mv /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.bak

cat << EOF > /etc/neutron/l3_agent.ini
[DEFAULT]
interface_driver = openvswitch
external_network_bridge =
agent_mode = legacy
EOF
```

- Cấu hình Modular Layer 2
```sh
mv /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak

cat << EOF > /etc/neutron/plugins/ml2/ml2_conf.ini
[DEFAULT]
[ml2]
type_drivers = flat,vlan,vxlan,gre
tenant_network_types = vxlan,gre,vlan
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security,qos
path_mtu = 1500
[ml2_type_flat]
flat_networks = physnet1
[ml2_type_vlan]
network_vlan_ranges = physnet1
[ml2_type_vxlan]
vni_ranges = 200:2000
[ml2_type_gre]
tunnel_id_ranges = 2000:4000
[securitygroup]
enable_ipset = true
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
EOF
```
- Cấu hình openvswitch agent
```sh
mv /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.bak

cat << EOF > /etc/neutron/plugins/ml2/openvswitch_agent.ini
[DEFAULT]
[agent]
tunnel_types = vxlan,gre
l2_population = True
extensions = qos
arp_responder = true
[ovs]
bridge_mappings = physnet1:br-provider
local_ip = 192.168.10.93
datapath_type = system
[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
EOF
```

- Cấu hình dhcp_agent
```sh
mv /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.bak

cat << EOF > /etc/neutron/dhcp_agent.ini
[DEFAULT]
interface_driver = openvswitch
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
EOF
```
- Cấu hình metadata agent
```sh
mv /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bak

cat << EOF > /etc/neutron/metadata_agent.ini
[DEFAULT]
metadata_proxy_shared_secret = 5b721855305f81836b04
nova_metadata_port = 8775
nova_metadata_host = 192.168.10.93
EOF
```
- Phân quyền file cấu hình 
```sh
chmod 640 /etc/neutron/neutron.conf /etc/neutron/l3_agent.ini /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/dhcp_agent.ini /etc/neutron/metadata_agent.ini

chgrp neutron /etc/neutron/neutron.conf /etc/neutron/l3_agent.ini /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/dhcp_agent.ini /etc/neutron/metadata_agent.ini
``` 

- Link file cấu hình
```sh
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
```

- Đồng bộ Database Neutron
```sh
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
```

- Khởi động lại dịch vụ Nova
```sh
    systemctl restart openstack-nova-api.service
    systemctl restart openstack-nova-scheduler openstack-nova-conductor
```

- Enable và khởi động lại dịch vụ Neutron Services
```sh
    systemctl enable neutron-server.service neutron-openvswitch-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service
    systemctl start neutron-server.service neutron-openvswitch-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service
    
    systemctl enable neutron-l3-agent.service
    systemctl restart neutron-l3-agent.service
```

**Thực hiện trên node compute**

- Cài đặt gói
```sh
dnf --enablerepo=centos-openstack-victoria,powertools,epel -y install openstack-neutron-openvswitch ebtables ipset
```

- Cấu hình Neutron
```sh
mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak

cat << EOF > /etc/neutron/neutron.conf
[DEFAULT]
bind_host = 192.168.10.92
interface_driver = openvswitch
auth_strategy = keystone
transport_url = rabbit://openstack:Welcome123@192.168.10.93:5672
core_plugin = ml2
[cors]
[database]
connection =
[keystone_authtoken]
www_authenticate_uri = http://192.168.10.93:5000
auth_url = http://192.168.10.93:5000
memcached_servers = 192.168.10.93:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = neutron
password = Welcome123
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[privsep]
EOF
```
- Cấu hình Openvswitch agent
```sh
mv /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.bak

cat << EOF > /etc/neutron/plugins/ml2/openvswitch_agent.ini
[DEFAULT]
[agent]
tunnel_types = vxlan,gre
l2_population = True
extensions = qos
[ovs]
local_ip = 192.168.10.92
bridge_mappings = physnet1:br-provider
[securitygroup]
firewall_driver = openvswitch
enable_security_group = true
EOF
```

- Phân quyền file cấu hình 
```sh
chmod 640 /etc/neutron/neutron.conf /etc/neutron/plugins/ml2/openvswitch_agent.ini

chgrp neutron /etc/neutron/neutron.conf /etc/neutron/plugins/ml2/openvswitch_agent.ini
``` 

- Khởi động lại dịch vụ 
```sh
systemctl restart openstack-nova-compute
systemctl enable neutron-openvswitch-agent.service 
systemctl restart neutron-openvswitch-agent.service 
```


### 3.12 Cấu hình network interfaces <a name = '3.12'></a>

**Thực hiện trên node controller**

- Enable và khởi động Openvswitch
```sh
    systemctl enable openvswitch
    systemctl start openvswitch
```

- Tạo brigde và gán interface flat cho brigde đó
```sh
    ovs-vsctl add-br br-provider
    ovs-vsctl add-port br-provider ens4
```

- Cấu hình network-script cho Flat interface 
```sh
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-ens4
DEVICE=ens4
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br-provider
BOOTPROTO=none
EOF
```

- Cấu hình br-provider
```sh
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br-provider
DEVICE=br-provider
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=none
IPADDR=192.168.20.93
NETMASK=255.255.255.0 
OVSDHCPINTERFACES=ens5
EOF
```

- Khởi động lại network
```sh
systemctl restart network
```
**Thực hiện trên node compute**

- Enable và khởi động Openvswitch
```sh
    systemctl enable openvswitch
    systemctl start openvswitch
```

- Tạo brigde và gán interface flat cho brigde đó
```sh
    ovs-vsctl add-br br-provider
    ovs-vsctl add-port br-provider ens4
```

- Cấu hình network-script cho Flat interface 
```sh
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-ens4
DEVICE=ens4
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br-provider
BOOTPROTO=none
EOF
```

- Cấu hình br-provider
```sh
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br-provider
DEVICE=br-provider
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=none
IPADDR=192.168.20.92
NETMASK=255.255.255.0 
OVSDHCPINTERFACES=ens5
EOF
```

- Khởi động lại network
```sh
systemctl restart network
```



###  3.13 Cài đặt dịch vụ dashboard ( Horizon ) <a name = '3.13'></a>

**Thực hiện trên node controller**

- Cài đặt gói Openstack-dashboard
```sh
dnf --enablerepo=centos-openstack-victoria,powertools,epel -y install openstack-dashboard
```

- Sao lưu file cấu hình gốc 
```sh
	horizonfile=/etc/openstack-dashboard/local_settings
	horizonfilebak=/etc/openstack-dashboard/local_settings.bak
	cp $horizonfile $horizonfilebak
	egrep -v "^$|^#" $horizonfilebak > $horizonfile
```

- Cấu hình horizon
```sh
sed -i  's|127.0.0.1|'"192.168.10.93"'|g' /etc/openstack-dashboard/local_settings

sed -i  's|"http://%s:5000/v3" % OPENSTACK_HOST|"'http://"$VIP_MGNT_IP":5000/v3'"|g' /etc/openstack-dashboard/local_settings

sed -i -e "s/ALLOWED_HOSTS.*/ALLOWED_HOSTS = ['*',]/g" /etc/openstack-dashboard/local_settings

echo "SESSION_ENGINE = 'django.contrib.sessions.backends.cache'" >> /etc/openstack-dashboard/local_settings

echo "OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True" >> /etc/openstack-dashboard/local_settings

echo "WEBROOT = '/dashboard/'" >> /etc/openstack-dashboard/local_settings

cat << EOF >> /etc/openstack-dashboard/local_settings
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}
CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': ['192.168.10.93']
        }
}
POLICY_FILES_PATH = '/etc/openstack-dashboard'

EOF

echo 'OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"' >> /etc/openstack-dashboard/local_settings

sed -i 's/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "_member_"/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"/g' /etc/openstack-dashboard/local_settings

sed -i 's/TIME_ZONE = "UTC"/TIME_ZONE = "Asia\/Ho_Chi_Minh"/g' /etc/openstack-dashboard/local_settings
	
echo "WSGIApplicationGroup %{GLOBAL}" >> /etc/httpd/conf.d/openstack-dashboard.conf

chown root:apache /etc/openstack-dashboard/local_settings

```
- Khởi động lại dịch vụ HTTPD
```sh
systemctl restart httpd memcached
```

## 3.14 Cài đặt thành phần Cinder <a name = '3.14'></a>

*Thực hiện dùng luôn node controller làm cinder volume, ở đây tôi gắn thêm vào controller một disk là `vdb`*

- Tạo Database và user cho Cinder
```sh
cat << EOF | mysql -pWelcome123
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'Welcome123';
EOF
```

- Tạo dịch vụ, user cho Cinder
```sh
source /root/admin-openrc

openstack user create --domain default --password Welcome123 cinder
openstack role add --project service --user cinder admin
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3
openstack endpoint create --region Hanoi volumev2 public http://192.168.10.93:8776/v2/%\(project_id\)s
openstack endpoint create --region Hanoi volumev2 internal http://192.168.10.93:8776/v2/%\(project_id\)s
openstack endpoint create --region Hanoi volumev2 admin http://192.168.10.93:8776/v2/%\(project_id\)s
openstack endpoint create --region Hanoi volumev3 public http://192.168.10.93:8776/v3/%\(project_id\)s
openstack endpoint create --region Hanoi volumev3 internal http://192.168.10.93:8776/v3/%\(project_id\)s
openstack endpoint create --region Hanoi volumev3 admin http://192.168.10.93:8776/v3/%\(project_id\)s
```

- Cài đặt Cinder
```sh
yum install openstack-cinder lvm2 device-mapper-persistent-data targetcli python3-keystone -y
```

- Cấu hình Cinder
```sh
cinderapifile=/etc/cinder/cinder.conf
cinderapifilebak=/etc/cinder/cinder.conf.bak
cp $cinderapifile $cinderapifilebak

cat << EOF > /etc/cinder/cinder.conf
[DEFAULT]
my_ip = 192.168.10.93
host = controller
use_forwarded_for = true
osapi_volume_listen = 192.168.10.93
osapi_volume_listen_port = 8776
glance_api_servers = http://192.168.10.93:9292
glance_api_version = 2
transport_url = rabbit://openstack:Welcome123@192.168.10.93:5672
log_dir = /var/log/cinder
state_path = /var/lib/cinder
auth_strategy = keystone
volume_name_template = volume-%s
api_paste_config = /etc/cinder/api-paste.ini
rootwrap_config = /etc/cinder/rootwrap.conf
allowed_direct_url_schemes = cinder
glance_api_insecure = False
glance_ca_certificates_file = /etc/ssl/private/haproxy.pem
enabled_backends = lvm


[lvm]
iscsi_ip_address = 192.168.10.93
volumes_dir = /var/lib/cinder/volumes
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
volume_backend_name = lvm
target_helper = lioadm
target_protocol = iscsi

[backend]
[backend_defaults]
[brcd_fabric_example]
[cisco_fabric_example]
[coordination]
[cors]

[database]
connection = mysql+pymysql://cinder:Welcome123@192.168.10.93/cinder

[fc-zone-manager]
[healthcheck]

[keystone_authtoken]
www_authenticate_uri = http://192.168.10.93:5000
auth_url = http://192.168.10.93:5000
memcached_servers = 192.168.10.93:11211
auth_type = password
project_domain_id = default
user_domain_id = default
project_name = service
username = cinder
password = Welcome123
region_name = Hanoi
[matchmaker_redis]

[nova]
interface = internal
auth_url = http://192.168.10.93:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = Hanoi
project_name = service
username = nova
password = Welcome123

[oslo_concurrency]
lock_path = /var/lib/cinder/tmp

[oslo_messaging_amqp]
[oslo_messaging_kafka]

[oslo_messaging_notifications]
transport_url = rabbit://openstack:Welcome123@192.168.10.93:5672
[oslo_messaging_rabbit]
[oslo_messaging_zmq]
[oslo_middleware]
[oslo_policy]
[barbican]
[oslo_reports]
[oslo_versionedobjects]
[profiler]
[service_user]
[ssl]
[vault]
EOF
```

- Đồng bộ Database Cinder
```sh
su -s /bin/sh -c "cinder-manage db sync" cinder
```
- Cấu hình LVM
```sh
pvcreate /dev/vdb

vgcreate cinder-volumes /dev/vdb

string="filter = [ \"a/vdb/\", \"r/.*/\"]"

lvmfile=/etc/lvm/lvm.conf

sed -i 's|# Accept every block device:|'"$string"'|g' $lvmfile
```

- Khởi động lại các service Cinder
```sh
systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service openstack-cinder-volume.service
systemctl restart openstack-cinder-api.service openstack-cinder-scheduler.service openstack-cinder-volume.service
```

- Tạo volume type
```sh
source /root/admin-openrc
openstack volume type create lvm
openstack volume type set lvm --property volume_backend_name=lvm
```


## 4. Kiểm tra hệ thống sau khi cài đặt <a name = '4'></a>

### 4.1 Discover compute hosts <a name = '4.1'></a>
- Discover compute hosts
```sh
source /root/admin-openrc

su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
```



### 4.2 Truy cập Openstack-dashboard <a name = '4.2'></a>
- Truy cập Openstack dashboard qua địa chỉ
```
http://192.168.10.93/dashboard/
```
