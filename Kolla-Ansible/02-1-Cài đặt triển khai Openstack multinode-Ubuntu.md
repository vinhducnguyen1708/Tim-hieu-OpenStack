# Cài đặt Openstack bằng Kolla-Ansible trên Ubunutu

## 1. Thông tin mô hình

![topology](ima/kolla-multinode-ubuntu01.png)

## 2. Cài đặt cơ bản

*Thực hiện trên tất cả các node*

- Update các gói cài đặt 
```sh
apt update -y && apt upgrade -y
```
- Cài đặt python3 pip:
```sh
apt install -y python3-pip
```
- Cấu hình host domain
```sh
cat << EOF > /etc/hosts
127.0.0.1 localhost
127.0.1.1 cloud

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
192.168.60.238  kolla-controller
192.168.60.69   kolla-compute01
```
- Khởi động lại máy 
```sh
init 6
```

## 3. Cấu hình network
*Thực hiện trên máy chủ kolla-controller*

- Cấu hình network:
```sh
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
address 192.168.60.238
netmask 255.255.255.0
gateway 192.168.60.1
dns-nameservers 8.8.8.8 8.8.4.4

auto eth1
iface eth1 inet static
address 10.10.43.212
netmask 255.255.255.0

auto eth2
iface eth2 inet static
address 192.168.50.34
netmask 255.255.255.0
EOF
```
- Khởi động lại các card mạng
```sh
ifdown -a && ifup -a
```

*Thực hiện trên máy chủ kolla-compute01*

- Cấu hình network:
```sh
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
address 192.168.60.69
netmask 255.255.255.0
gateway 192.168.60.1
dns-nameservers 8.8.8.8 8.8.4.4

auto eth1
iface eth1 inet static
address 10.10.43.104
netmask 255.255.255.0

auto eth2
iface eth2 inet static
address 192.168.50.39
netmask 255.255.255.0
EOF
```
- Khởi động lại các card mạng
```sh
ifdown -a && ifup -a
```
## 4. Cài đặt kolla-ansible
*Thực hiện trên node kolla-ansible vì node này sẽ thực hiện cài đặt trên các node*

- Cài đặt Ansible *(yêu cầu phiên bản 2.10 - 2.11)*:
```sh
pip3 install ansible=="2.10.7"
```

- Cài đặt Kolla Ansible:
```sh
pip3 install "kolla-ansible==13.0.0"
```
- Tạo thư mục cấu hình kolla
```sh
mkdir -p /etc/kolla
```

- Copy các file cấu hình của Kolla Ansible 
```sh
cp /usr/local/share/kolla-ansible/etc_examples/kolla/* /etc/kolla/
cp /usr/local/share/kolla-ansible/ansible/inventory/* .
```

- Generate value password vào file `/etc/kolla/passwords.yml`
```sh
kolla-genpwd
```

- Cấu hình file inventory tại `/root/multinode`:
```ini
# These initial groups are the only groups required to be modified. The
# additional groups are for more control of the environment.
[control]
# These hostname must be resolvable from your deployment host
kolla-controller anisble_host=192.168.60.238 ansible_connection=ssh     ansible_user=root
# The above can also be specified as follows:
#control[01:03]     ansible_user=kolla

# The network nodes are where your l3-agent and loadbalancers will run
# This can be the same as a host in the control group
[network]
kolla-controller anisble_host=192.168.60.238 ansible_connection=ssh     ansible_user=root

[compute]
kolla-compute01 anisble_host=192.168.60.69 ansible_connection=ssh     ansible_user=root


[monitoring]
kolla-controller anisble_host=192.168.60.238 ansible_connection=ssh     ansible_user=root

# When compute nodes and control nodes use different interfaces,
# you need to comment out "api_interface" and other interfaces from the globals.yml
# and specify like below:
#compute01 neutron_external_interface=eth0 api_interface=em1 storage_interface=em1 tunnel_interface=em1

[storage]
kolla-controller anisble_host=192.168.60.238 ansible_connection=ssh     ansible_user=root

[deployment]
localhost       ansible_connection=local

[baremetal:children]
control
network
compute
storage
monitoring

[tls-backend:children]
control

# You can explicitly specify which hosts run each project by updating the
# groups in the sections below. Common services are grouped together.

[common:children]
control
network
compute
storage
monitoring
#...
```

- Backup lại cấu hình file extra_vars:
```sh
cp /etc/kolla/globals.yml /etc/kolla/globals.yml.bak
```

- Cấu hình `extra_vars` tại file `/etc/kolla/globals.yml`
```sh
cat << EOF > /etc/kolla/globals.yml
---
kolla_base_distro: "ubuntu"
kolla_install_type: "source"
openstack_release: "xena"

# Không sử dụng HA Controller (VIP RabbitMQ, MariaDB v.v)
# enable_haproxy: "no"

# Dải Mngt + admin, internal API
kolla_internal_vip_address: "192.168.60.123"
network_interface: "eth0"

# Dải Mngt Provider
neutron_external_interface: "eth2"

# Cho phép neutron sử dụng dải provider
enable_neutron_provider_networks: "yes"

nova_compute_virt_type: "kvm"

keepalived_virtual_router_id: "60"


enable_swift: 'no'
#enable_cinder: "yes"
#enable_cinder_backend_lvm: "yes"
#enable_cinder_backup: "no"
EOF
```
- Copy SSH key đến các node cài Kolla-Ansible
```sh
ssh-keygen
ssh-copy-id root@kolla-controller
ssh-copy-id root@kolla-compute01
```
## 5. Triển khai Openstack Kolla

- Khởi tạo môi trường cho Openstack Kolla
```sh
kolla-ansible -i multinode bootstrap-servers
```

- Kiểm tra thiết lập Kolla Ansible
```sh
kolla-ansible -i multinode prechecks
```

- Thực hiện triển khai Openstack Kolla
```sh
kolla-ansible -i multinode deploy
```

- Thiết lập File Environment Openstack, file này được lưu tại `/etc/kolla/admin-openrc.sh`
```sh
kolla-ansible -i multinode post-deploy
```

- Cài đặt Openstack Client
```sh
apt-get install -y python3-openstackclient python3-glanceclient python3-neutronclient 
```

## 6. Kiểm tra cài đặt
- Truy cập biến môi trường Openstack
```sh
source /etc/kolla/admin-openrc.sh
```

- Gọi token của keystone
```sh
openstack token issue
```

