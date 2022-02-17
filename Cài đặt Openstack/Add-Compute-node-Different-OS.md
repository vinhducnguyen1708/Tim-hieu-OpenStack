# Ghép máy chủ compute khác Distro OS vào hệ thống Openstack
## 1. Mô hình hệ thống
![topo](../images/ops-df-os-topo.png)

**Thông tin:**
- Hệ thống cũ đã được triển khai trên OS CentOS Linux8 `(compute-udev-hn01, compute-udev-hn02)`
- Các node compute bổ sung sẽ được cài OS Ubuntu1804 `(compute-udev-hn03)`
- Hệ thống vẫn chạy Openstack Ussuri

## 2. Triển khai
### 2.1 Cài đặt cơ bản cho máy chủ
- Update các gói phần mềm:
```sh
apt update -y && apt upgrade -y
```

- Cài đặt cấu hình NTP:
```sh
apt install chrony -y

ntpfile=/etc/chrony/chrony.conf

sed -i 's/pool 0.ubuntu.pool.ntp.org iburst maxsources 1//g' $ntpfile
sed -i 's/pool 1.ubuntu.pool.ntp.org iburst maxsources 1//g' $ntpfile
sed -i 's/pool 2.ubuntu.pool.ntp.org iburst maxsources 2//g' $ntpfile

timedatectl set-timezone Asia/Ho_Chi_Minh

service chrony restart
```

- Cài đặt repository Openstack Ussuri:
```sh
apt install software-properties-common -y
add-apt-repository cloud-archive:ussuri -y
apt update -y && apt dist-upgrade -y
```

- Khởi động lại máy chủ:
```sh
init 6
```
- Copy thư mục cert để giao tiếp với haproxy sang node compute mới:

*Đứng tại các node compute ban đầu*
```sh
scp -r /etc/ssl/private root@192.168.30.32:/etc/ssl/
```

- Phân quyền lại thư mục lưu cert SSL
```sh
chmod 751 /etc/ssl/private
```
- Copy cấu hình và key SSH cho noce compute mới:

*Đứng tại các node compute ban đầu*
```sh
scp -r /root/.ssh/* root@192.168.30.32:/root/.ssh/
```
### 2.2 Cấu hình Network cho máy chủ
```sh
cat <<EOF> /etc/network/interfaces
auto lo
iface lo inet loopback

source /etc/network/interfaces.d/*
auto ens3
iface ens3 inet static
address 192.168.30.32
netmask 255.255.255.0
gateway 192.168.30.1
dns-nameservers 8.8.8.8 8.8.4.4

auto ens4
iface ens4 inet static
address 192.168.20.50
netmask 255.255.255.0

auto ens5
iface ens5 inet static
address 10.10.20.241
netmask 255.255.255.0
EOF
```
- Khởi động lại cấu hình card mạng
```sh
ifdown -a && ifup -a
```
### 2.3 Cài đặt Nova compute
- Cài đặt gói phần mềm cho Nova compute:
```sh
apt -y install qemu-kvm libvirt-daemon-system libvirt-daemon virtinst bridge-utils libosinfo-bin libguestfs-tools virt-top

apt -y install nova-compute nova-compute-kvm qemu-system-data
```

- Cấu hình nova compute, copy y nguyên cấu hình của các node compute khác và thay IP, bổ sung `rootwrap_config=/etc/nova/rootwrap.conf
` vào trường `[DEFAULT]` để tránh lỗi [tại đây](https://yumserv.tistory.com/365) :
```sh
cat << EOF > /etc/nova/nova.conf
[DEFAULT]
my_ip = 192.168.30.32
transport_url = rabbit://openstack:Welcome123@192.168.30.11:5672,openstack:Welcome123@192.168.30.12:5672
enabled_apis = osapi_compute,metadata
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
compute_driver = libvirt.LibvirtDriver
resume_guests_state_on_host_boot = True
ram_allocation_ratio = 1.7
allow_resize_to_same_host = True
allow_migrate_to_same_host = True
instance_usage_audit = True
instance_usage_audit_period = hour
notify_on_state_change = vm_and_task_state
notification_driver = messagingv2
instances_path=/var/lib/nova/instances
rootwrap_config=/etc/nova/rootwrap.conf ## Cau hinh bo sung

[api]
auth_strategy = keystone
[api_database]
[barbican]
verify_ssl = false
[cache]
[cinder]
os_region_name = Hanoi
catalog_info = volumev3:cinderv3:internalURL
auth_url = https://192.168.30.10:5000/
auth_type = password
project_domain_name = default
user_domain_id = default
project_name = service
username = cinder
password = Welcome123
cafile = /etc/ssl/private/haproxy.pem
insecure = false

[compute]
[conductor]
[console]
[consoleauth]
[cors]
[database]
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]

[glance]
api_servers = https://192.168.30.10:9292
cafile = /etc/ssl/private/haproxy.pem
insecure = False
os_region_name = Hanoi

[guestfs]
[healthcheck]
[hyperv]
[ironic]

[key_manager]
backend = barbican
api_class = castellan.key_manager.barbican_key_manager.BarbicanKeyManager

[keystone]

[keystone_authtoken]
www_authenticate_uri = https://192.168.30.10:5000
auth_url = https://192.168.30.10:5000
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
region_name = Hanoi
password = Welcome123
cafile = /etc/ssl/private/haproxy.pem
insecure = False

[libvirt]
virt_type = kvm
rbd_user = cinder
rbd_secret_uuid = a6f033e0c540-4a9b-8951-66fbaf577418
#images_type = rbd
#images_rbd_pool = vms
#images_rbd_ceph_conf = /etc/ceph/ceph.conf
inject_partition = -2
inject_password = false
live_migration_flag = VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST
inject_key = false
disk_cachemodes = "network=writeback"
hw_disk_discard = unmap
#cpu_mode = custom
#cpu_model=Broadwell
[metrics]

[mks]

[neutron]
url = https://192.168.30.10:9696
auth_url = https://192.168.30.10:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = Hanoi
project_name = service
username = neutron
password = Welcome123
cafile = /etc/ssl/private/haproxy.pem
service_metadata_proxy = true
metadata_proxy_shared_secret = Welcome123
insecure = False

[notifications]
[osapi_v21]

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
os_region_name = Hanoi
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = https://192.168.30.10:5000/v3
username = placement
region_name = Hanoi
password = Welcome123
cafile = /etc/ssl/private/haproxy.pem
insecure = False

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
enabled = True
server_listen = 0.0.0.0
server_proxyclient_address = 192.168.30.32
novncproxy_base_url = https://192.168.30.10:6080/vnc_auto.html

[workarounds]
[wsgi]
[xenserver]
[xvp]
[zvm]
EOF
```
- Khởi động lại dịch vụ Nova compute
```sh
systemctl restart nova-compute
```

- Thêm shell cho user nova
```sh
usermod -s /bin/bash nova
```

- Copy thư mục ssh của nova sang node compute mới:

*Đứng tại các node compute ban đầu*
```sh
scp -r /var/lib/nova/.ssh root@192.168.30.32:/var/lib/nova/
```

- Phân quyền cho cấu hình ssh của nova:
```sh
chown -R nova:nova /var/lib/nova
```
- Kiểm tra log của nova compute:
```sh
tail -f /var/log/nova/nova-compute.log
```
### 2.4 Cài đặt Neutron-openvswitch-agent

- Cài đặt Neutron-openvswitch-agent
```sh
apt install neutron-openvswitch-agent -y
```

- Cấu hình neutron:
```sh
cat  << EOF > /etc/neutron/neutron.conf
[DEFAULT]
debug = true
bind_host = 192.168.30.32
interface_driver = openvswitch
auth_strategy = keystone
transport_url = rabbit://openstack:Welcome123@192.168.30.11:5672,openstack:Welcome123@192.168.30.12:5672
core_plugin = ml2
advertise_mtu = true
global_physnet_mtu = 1550
[cors]
[database]
[keystone_authtoken]
www_authenticate_uri = https://192.168.30.10:5000
auth_url = https://192.168.30.10:5000
memcached_servers =192.168.30.11:11211,192.168.30.12:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = Welcome123
region_name = Hanoi
cafile = /etc/ssl/private/haproxy.pem
insecure = False

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
EOF
```
- Cấu hình neutron-openvswitch-agent:
```sh
cat <<EOF> /etc/neutron/plugins/ml2/openvswitch_agent.ini
[DEFAULT]

[agent]
tunnel_types = vxlan,gre
l2_population = True
extensions = qos
arp_responder = true
enable_distributed_routing = True
dscp = 8
dscp_inherit = true


[ovs]
local_ip = 192.168.30.32
bridge_mappings = physnet1:br-provider
datapath_type = system


[securitygroup]
firewall_driver = openvswitch
enable_security_group = true
EOF
```
- Khởi tạo openvswitch:
```sh
ovs-vsctl add-br br-provider
ovs-vsctl add-port br-provider ens4
ip a flush ens4
ifconfig br-provider 192.168.20.50 netmask 255.255.255.0
ip link set br-provider up
```
- Cấu hình network :
```sh
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

source /etc/network/interfaces.d/*

auto ens3
iface ens3 inet static
address 192.168.30.32
netmask 255.255.255.0
gateway 192.168.30.1
dns-nameservers 8.8.8.8 8.8.4.4


auto br-provider
allow-ovs br-provider
iface br-provider inet static
  address 192.168.20.50
  netmask 255.255.255.0
  ovs_type OVSBridge
  ovs_ports ens4
allow-br-provider ens4
iface ens4 inet manual
  ovs_bridge br-provider
  ovs_type OVSPort

#auto ens4
#iface ens4 inet static
#address 192.168.20.50
#netmask 255.255.255.0



auto ens5
iface ens5 inet static
address 10.10.20.241
netmask 255.255.255.0
```
- Khởi động lại network đường external:
```sh
ifdown ens4 && ifup ens4
```

- Cấu hình user neutron trong visudo:
```sh
# visudo
neutron ALL = (root) NOPASSWD: /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf *
neutron ALL = (root) NOPASSWD: /usr/bin/neutron-rootwrap-daemon /etc/neutron/rootwrap.conf *
neutron ALL = (root) NOPASSWD: /usr/bin/privsep-helper *
neutron ALL = (root) NOPASSWD: /usr/sbin/iptables-save *
```

- Khởi động lại neutron-openvswitch-agent:
```sh
systemctl restart neutron-openvswitch-agent
```


---
## Tham khảo

[1] https://github.com/TrongTan124/install-OpenStack/blob/master/Ubuntu1804-Stein-OVS

[2] https://yumserv.tistory.com/365

[3] https://bugs.launchpad.net/oslo.privsep/+bug/1908525