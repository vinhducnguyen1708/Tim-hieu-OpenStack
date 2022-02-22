# Upgrade phiên bản cho Openstack AIO bằng Kolla-Ansible ( Rocky - Train)

## Mục tiêu
- Thực hiện upgrade hệ thống Openstack từ phiên bản Rocky lên phiên bản Train
- Thực hiện cài đặt external Mariadb ( không đưa service Mariadb lên container)
- Việc thực hiện dưới của tôi vẫn chưa hoàn chỉnh vì tôi phải phân quyền cho user trong DB để các thành phần có thể kết nối đến DB. Và việc tạo DB cho các thành phần mới của phiên bản cao hơn vẫn phải làm thủ công 
- Thực hiện cài đặt AIO
## Chuẩn bị môi trường
- HĐH: Centos7
- 2 NIC:
	- eth0: 192.168.20.35/24
	- eth1: 192.168.30.26/24
- RAM: 4GB
- DISK: 50GB
## Thực hiện trên node target
### Cấu hình network và hostname
- Bước 1: Cấu hình static network
- Bước 2: Cấu hình hostname
### Cài đặt Mariadb
- Bước 1: Cài đặt Mariadb
```sh
yum -y install mariadb mariadb-server python2-PyMySQL
```
- Bước 2: Cấu hình mariadb bằng cách tạo file `/etc/my.cnf.d/openstack.cnf` với nội dung:
```
bind-address = 0.0.0.0
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
```
- Bước 3: Enable và start dịch vụ MariaDB
```sh
systemctl enable mariadb.service
systemctl start mariadb.service
```
- Bước 4: Thiết lập mật khẩu cho tài khoản root (tài khoản root của mariadb)
```
mysql_secure_installation
```
- Bước 5: Thực hiện tạo user 
```sh
CREATE USER 'root'@'%' IDENTIFIED BY  '1234';
GRANT ALL PRIVILEGES ON * . * TO  'root'@'%' IDENTIFIED BY  '1234' WITH GRANT OPTION ;
GRANT PROXY ON ''@'%' TO 'root'@'localhost' WITH GRANT OPTION ;
#Do sự thay đổi của phiên bản Train , thành phần Placement được tách riêng nên ta tạo trước database và user cho thành phần này có password được định nghĩa phía mục ####2.3 của bài viết
CREATE DATABASE placement;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost'  IDENTIFIED BY 'RsezLpdhv8DkATXHHxE8b1CcvEFyfNI8hbRvmIBf';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'RsezLpdhv8DkATXHHxE8b1CcvEFyfNI8hbRvmIBf';
FLUSH PRIVILEGES;
exit;
```

## Thực hiện cài đặt trên node Deployment

### 1.Cài đăt Openstac Rocky

#### 1.1 Cài đặt Kolla-Ansible
- Bước 1: Thực hiện cài đặt các gói phụ trợ 
```
yum install -y epel-release
yum update -y
yum install python-devel libffi-devel gcc openssl-devel libselinux-python git wget byobu yum-utils python-setuptools vim -y
```
- Bước 2: Cài đặt Pip và Ansible (phiên bản Kolla-Ansible cho Rocky yêu cầu các phiên bản Ansible thấp hơn 2.8)
```sh
easy_install pip
pip install -U pip
pip install ansible==2.7.10
```
- Bước 3: Cài đặt Kolla-Ansible tương ứng với phiên bản Rocky
```sh
pip install kolla-ansible==7.1.1
```
- Bước 4: Tạo thư mục chứa cấu hình cho kolla-ansible
```sh
mkdir -p /etc/kolla
chown $USER:$USER /etc/kolla
cp -r /usr/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
```

- Bước 5: Do cài đặt all-in-one nên ta sẽ sử dụng file inventory là all-in-one cho kolla-ansible:
```sh
cd ~
cp /usr/share/kolla-ansible/ansible/inventory/all-in-one .
```

- Bước 6: Thực hiện điều chỉnh cấu hình cho ansible bằng cách tạo file sau. Khi chạy ansible thì cấu hình này sẽ được load
```sh
cat << EOF > ~/ansible.cfg
[defaults]
retry_files_enabled=False
host_key_checking=False
deprecation_warnings=False
pipelining=True
forks=100
EOF
```

- Bước 7: Thực hiện tạo password cho các thành phần của OpenStack
```sh
kolla-genpwd
```

- Bước 8: Backup lại file cấu hình toàn cục mà kolla-ansible sử dụng trước khi chỉnh sửa các thông số
```sh
cp /etc/kolla/globals.yml{,.org}
```
- Bước 9: sửa lại password database `/etc/kolla/passwords.yml`
```yml
database_password: 1234
```
#### 1.2 Khai báo cho Kolla-Ansible để cài đặt Openstack

- Bước 1: Khai báo tên host trong file inventory `all-in-one`
```ini
[control]
192.168.20.35

[network]
192.168.20.35

[inner-compute]
192.168.20.35

[storage]
192.168.20.35

[monitoring]
192.168.20.35

[deployment]
localhost       ansible_connection=local
```

- Bước 2: Khai báo các giá trị trong file `/etc/kolla/globals.yml`
```yml
---
kolla_base_distro: "centos"
kolla_install_type: "binary"
openstack_release: "rocky"
kolla_internal_vip_address: "192.168.20.192"
network_interface: "eth0"
neutron_external_interface: "eth1"
keepalived_virtual_router_id: "192"
use_preconfigured_databases: "no"
enable_mariadb: "no"
enable_heat: "no"
```
#### 1.3 Tiến hành deploy phiên bản rocky
- Bước 1: Cài đặt các phần mềm môi trường
```
kolla-ansible -i all-in-one bootstrap-servers
```
- Bước 2: Kéo image từ DockerHub về
```
kolla-ansible -i all-in-one pull
```
- Bước 3: Deploy Hệ thống OpenStack
```
kolla-ansible -i all-in-one deploy
```

- Bước 4: Sau khi Deloy truy cập vào địa chỉ `192.168.20.192` và tạo network, VM để test sau khi upgrade

### 2.Cài đăt Openstac Train
### 2.1 Cập nhật phiên bản Kolla-Ansible cho phiên bản train
*Việc này được thực hiện để lấy nội dung playbook để deploy, upgrade lên phiên bản Train*
- Bước 1: Upgrade phiên bản cho Kolla-Ansible
```
pip install kolla-ansible==9.0.1
```
#### 2.2 Khai báo cho Kolla-Ansible để cài đặt Openstack

*Giữ nguyên file iventory*

- Bước 1: Khai báo các giá trị trong file `/etc/kolla/globals.yml`
```yml
---
kolla_base_distro: "centos"
kolla_install_type: "binary"
#Thay đổi phiên bản
openstack_release: "train"
kolla_internal_vip_address: "192.168.20.192"
network_interface: "eth0"
neutron_external_interface: "eth1"
keepalived_virtual_router_id: "192"
#Vì khi cài đặt Rocky ta đã tạo db cho các thành phần rồi nên khai báo sử dụng DB cũ
use_preconfigured_databases: "yes"
enable_mariadb: "no"
enable_heat: "no"
```

#### 2.3 Thực hiện merge file password của Rocky và train thành 1
- Bước 1: Tạo file passwords.yml của phiên bản train
*Ở đây Kolla-Ansible đưa các khai báo password cho các thành phần vào  file passwords.yml.new*
```
touch  /etc/kolla/passwords.yml.new
cd /etc/kolla/
kolla-genpwd -p passwords.yml.new
cd ~
```
- Bước 2: Đổi tên file passwords.yml cũ
```
mv /etc/kolla/passwords.yml passwords.yml.old
```
- Bước 3: Merge 2 file này lại với nhau thành file passwords.yml để sử dụng *(Lưu ý password database của user placement trong này nhé)*
```
cd /etc/kolla/
kolla-mergepwd --old passwords.yml.old --new passwords.yml.new --final /etc/kolla/passwords.yml
cd ~
```
#### 2.4 Thực hiện upgrade phiên bản Train
- Bước 1 : Pull các Image của phiên bản train về
```
kolla-ansible -i all-in-one pull
```
- Bước 2: Tiến hành Upgrade
```
kolla-ansible -i all-in-one upgrade
```
- Bước 3 : Trong khi chạy đến quá trình upgrade nova sẽ thực hiện `Wait for nova-compute services to update service versions`  Khi đó `ctrl + c` rồi nhấn `C` để cho phép upgrade service

---


