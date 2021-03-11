# 1. Tìm hiểu về Masakari

Masakari Là dự án của Openstack được thiết kế để đảm bảo tính sẵn sàng cho các máy ảo và các tiến trình chạy trên các node compute.

## 1.2 Thành phần

![ima](../../images/masakari-1.png)
- Masakari-api: Thành phần tiếp nhận các request, chuyển thành lệnh để tương tác với masakari-engine thông qua Rabbitmq

- Masakari-engine: Thực thi các quy trình khôi phục và giao tiếp với Nova

![ima](../../images/masakari-2.png)

Trên các node compute sẽ là nơi chứa các service monitor, mỗi một service này sẽ giám sát một thành phần trong compute:

- instance monitor: Giám sát trạng thái của máy ảo, tránh trường hợp bất đồng bộ trạng thái giữa nova và hypervisor, luôn giữ trạng thái "Active" cho máy ảo được trạo trên node compute đó 
- process monitor: Giám sát trạng thái của các tiến trình, các service tác động trực tiếp đến máy ảo như libvirtd, openstack-nova-compute,.. sẽ được giám sát và luôn được giữ ở trạng thái active, nếu không hoạt động sẽ thực hiện restart service đó.
- host monitor: Giám sát trạng thái của cả node compute đó. Trong thực tế các node compute có thể bị hỏng hoặc mất điện, khi đó tất cả các VM trên node compute đó cần phải được dịch chuyển sang node compute khác.

# 2. Cài đặt Masakari
## 2.1 Mô hình
- controller-vic:
    - HĐH: Centos8
    - NIC:
        - eth0: 14.225.23.228/24 (Internet)
        - eth1: 192.168.10.238/24 (Management+Data)
        - eth2: 192.168.29.177/24 (Provider)

- compute-vic01:
    - HĐH: Centos8
    - NIC:
        - eth0: 14.225.23.248/24 (Internet)
        - eth1: 192.168.10.159/24 (Management+Data)
        - eth2: 192.168.29.119/24 (Provider)

- compute-vic02:
    - HĐH: Centos8
    - NIC:
        - eth0: 14.225.23.232/24 (Internet)
        - eth1: 192.168.10.202/24 (Management+Data)
        - eth2: 192.168.29.118/24 (Provider)

## 2.2 Thực hiện trên controller 
### 2.2.1 Cài đặt Masakari-api, Masakari-engine
- Bước 1: Cài đặt các gói cần thiết
```sh
yum -y install libvirt-devel gcc libpq-devel python3-pip
```

- Bước 2: Khởi tạo database cho Masakari
```sh
cat << EOF | mysql -uroot -pWelcome123
CREATE DATABASE masakari CHARACTER SET utf8;

GRANT ALL PRIVILEGES ON masakari.* TO 'masakari'@'localhost' \
  IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON masakari.* TO 'masakari'@'%' \
  IDENTIFIED BY 'Welcome123';
EOF
```

- Bước 3: Tạo User và phân quyền cho masakari
```sh
openstack user create --domain default --password Welcome123 masakari

openstack role add --project service --user masakari admin
```

- Bước 4: Khởi tạo dịch vụ Masakari
```sh
openstack service create --name masakari --description "masakari high availability" instance-ha
```

- Bước 5: Khởi tạo Endpoint cho Masakari
```sh
source admin-openrc
openstack endpoint create --region Hanoi masakari public http://192.168.10.238:15868/v1/%\(tenant_id\)s
openstack endpoint create --region Hanoi masakari internal http://192.168.10.238:15868/v1/%\(tenant_id\)s
openstack endpoint create --region Hanoi masakari admin http://192.168.10.238:15868/v1/%\(tenant_id\)s
```

- Bước 6: Clone bộ cài đặt Masakari từ Github
```sh
git clone https://github.com/openstack/masakari.git

git checkout stable/victoria
```

- Bước 6: Cài đặt Masakari
```sh
cd masakari/
tox -egenconfig
sudo python3 setup.py install
```

- Bước 7: Tạo thư mục chứa cấu hình Masakari và copy cấu hình vào thư mục
```sh
mkdir /etc/masakari

cp etc/masakari/masakari.conf /etc/masakari/
cp etc/masakari/api-paste.ini /etc/masakari/
```
- Bước 8: Cấu hình Masakari
```sh
cat << EOF > /etc/masakari/masakari.conf 
[DEFAULT]
os_region_name = Hanoi
transport_url = rabbit://openstack:Welcome123@192.168.10.238:5672/
graceful_shutdown_timeout = 5
os_privileged_user_tenant = service
os_privileged_user_password = Welcome123
os_privileged_user_auth_url = http://192.168.10.238:5000
os_privileged_user_name = nova
logging_exception_prefix = %(color)s%(asctime)s.%(msecs)03d TRACE %(name)s [01;35m%(instance)s[00m
logging_debug_format_suffix = [00;33mfrom (pid=%(process)d) %(funcName)s %(pathname)s:%(lineno)d[00m
logging_default_format_string = %(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [[00;36m-%(color)s] [01;35m%(instance)s%(color)s%(message)s[00m
logging_context_format_string = %(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [[01;36m%(request_id)s [00;36m%(project_name)s %(user_name)s%(color)s] [01;35m%(instance)s%(color)s%(message)s[00m
use_syslog = False
debug = True
masakari_api_workers = 2
[keystone_authtoken]
www_authenticate_uri = http://192.168.10.238:5000
auth_url = http://192.168.10.238:5000
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = masakari
password = Welcome123
memcached_servers = 192.168.10.238:11211
[host_failure]
evacuate_all_instances = True
ignore_instances_in_error_state = false
add_reserved_host_to_aggregate = false
[oslo_messaging_notifications]
transport_url = rabbit://openstack:Welcome123@192.168.10.238:5672/
[database]
connection = mysql+pymysql://masakari:Welcome123@192.168.10.238/masakari?charset=utf8
[taskflow]
connection = mysql+pymysql://masakari:Welcome123@192.168.10.238/masakari?charset=utf8
EOF
```

- Bước 9: Đồng bộ DB với cấu hình
```sh
masakari-manage db sync
```

- Bước 10: Cấu hình systemd cho service Masakari (Tùy chọn)
```sh
cat << EOF >  /usr/lib/systemd/system/masakari-api.service
[Unit]
Description=Masakari Api
[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/masakari-api
[Install]
WantedBy=multi-user.target
EOF


cat << EOF > /usr/lib/systemd/system/masakari-engine.service
[Unit]
Description=Masakari Api
[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/local/masakari-engine
[Install]
WantedBy=multi-user.target
EOF
```
- Bước 11: Reload Daemon và các service
```sh
systemctl reload-daemon

systemctl restart masakari-api.service

systemctl restart masakari-engine.service
```

- Bước 12: Cài đặt masakari-client
```sh
pip3 install python-masakariclient
```

## 2.3 Thực hiện trên Compute
### 2.3.1 Cài đặt Masakari-instancemonitor, Masakari-processmonitor, Masakari-hostmonitor

- Bước 1: Cài đặt các gói cần thiết và Clone bộ cài đặt Masakari-monitor từ Github
```sh
yum -y install libvirt-devel gcc libpq-devel

git clone https://github.com/openstack/masakari-monitors.git

git checkout stable/victoria
```
- Bước 2: Cài đặt Masakari-monitor
```sh
cd masakari-monitors/
sudo python3 setup.py install
```
- Bước 3: Tạo thư mục cấu hình
```sh
mkdir /etc/masakarimonitors
```

- Bước 4: Cấu hình các services monitor
```sh
cat << EOF > /etc/masakarimonitors/masakarimonitors.conf
[DEFAULT]
debug = True
transport_url = rabbit://openstack:Welcome123@192.168.10.238:5672
[api]
region = Hanoi
auth_url = http://192.168.10.238:5000
user_domain_name = default
project_name = service
project_domain_id = default
username = masakari
password = Welcome123
[keystone_authtoken]
region = Hanoi
www_authenticate_uri = http://192.168.10.238:5000
auth_url = http://192.168.10.238:5000
auth_type = password
user_domain_id = Default
project_name = service
project_domain_id = Default
username = masakari
password = Welcome123
memcached_servers = 192.168.10.238:11211
[libvirt]
connection_uri = "qemu+tcp://192.168.10.159/system"
[host]
monitoring_driver = default
monitoring_interval = 10
disable_ipmi_check = True
restrict_to_remotes = True
[process]
process_list_path = /etc/masakarimonitors/process_list.yaml
EOF

cat << EOF > /etc/masakarimonitors/process_list.yaml
-
    # libvirt-bin
    process_name: /usr/sbin/libvirtd
    start_command: systemctl start libvirtd
    pre_start_command:
    post_start_command:
    restart_command: systemctl restart libvirtd
    pre_restart_command:
    post_restart_command:
    run_as_root: True
-
    # nova-compute
    process_name: /usr/bin/nova-compute
    start_command: systemctl start openstack-nova-compute
    pre_start_command:
    post_start_command:
    restart_command: systemctl restart openstack-nova-compute
    pre_restart_command:
    post_restart_command:
    run_as_root: True
-
    # instancemonitor
    process_name:  /usr/local/bin/masakari-instancemonitor
    start_command: systemctl start masakari-instancemonitor
    pre_start_command:
    post_start_command:
    restart_command: systemctl restart masakari-instancemonitor
    pre_restart_command:
    post_restart_command:
    run_as_root: True
    #-
    # hostmonitor
    process_name: /usr/bin/python /usr/local/bin/masakari-hostmonitor
    start_command: systemctl start masakari-hostmonitor
    pre_start_command:
    post_start_command:
    restart_command: systemctl restart masakari-hostmonitor
    pre_restart_command:
    post_restart_command:
    run_as_root: True
-
    # sshd
    process_name: /usr/sbin/sshd
    start_command: systemctl start sshd
    pre_start_command:
    post_start_command:
    restart_command: systemctl restart sshd
    pre_restart_command:
    post_restart_command:
    run_as_root: True
EOF

cat << EOF > /etc/masakarimonitors/processmonitor.conf
PROCESS_CHECK_INTERVAL=5
PROCESS_REBOOT_RETRY=3
REBOOT_INTERVAL=5
MASAKARI_API_SEND_TIMEOUT=10
MASAKARI_API_SEND_RETRY=12
MASAKARI_API_SEND_DELAY=10
LOG_LEVEL="debug"
DOMAIN="Default"
PROJECT="admin"
ADMIN_USER="admin"
ADMIN_PASS="Welcome123"
AUTH_URL="http://192.168.10.238:5000/"
REGION="Hanoi"
EOF

cat << EOF > /etc/masakarimonitors/hostmonitor.conf
MONITOR_INTERVAL=120
NOTICE_TIMEOUT=30
NOTICE_RETRY_COUNT=3
NOTICE_RETRY_INTERVAL=3
MAX_CHILD_PROCESS=3
TCPDUMP_TIMEOUT=10
HA_CONF="/etc/corosync/corosync.conf"
LOG_LEVEL="debug"
DOMAIN="Default"
ADMIN_USER="admin"
ADMIN_PASS="Welcome123"
PROJECT="service"
REGION="Hanoi"
AUTH_URL="http://192.168.10.238:5000/"
IGNORE_RESOURCE_GROUP_NAME_PATTERN="stonith"
EOF
```

- Bước 5: Cấu hình systemd cho các services
```sh
cat << EOF > /usr/lib/systemd/system/masakari-instancemonitor.service
[Unit]
Description=Masakari Instancemonitor
[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/masakari-instancemonitor
[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /usr/lib/systemd/system/masakari-processmonitor.service
[Unit]
Description=Masakari Processmonitor
[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/masakari-processmonitor
[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /usr/lib/systemd/system/masakari-hostmonitor.service
[Unit]
Description=Masakari Hostmonitor
[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/masakari-hostmonitor
[Install]
WantedBy=multi-user.target
EOF
```

- Bước 6: Reload Daemon và các service
```sh
systemctl reload-daemon
systemctl restart masakari-instancemonitor.service
systemctl restart masakari-processmonitor.service
systemctl restart masakari-hostmonitor.service
```


*Muốn thực hiện tính năng giám sát host compute thì phải thực hiện sử dụng Pacemaker*
# 2.4 Cài đặt Pacemaker
## 2.4.1 Thực hiện trên Compute
- Bước 1: Cài đặt Pacemaker-remote
```sh
yum --enablerepo=ha install -y pacemaker-remote  pcs fence-agents-all resource-agents

systemctl enable --now pacemaker_remote.service
```

- Thiết lập mật khẩu cho user hacluster
```sh
echo hacluster | passwd --stdin hacluster
```
## 2.4.2 Thực hiện trên Controller
- Bước 1: Cài đặt Pacemaker Corosync
```sh
yum --enablerepo=ha install -y lvm2 cifs-utils quota psmisc pcs pacemaker corosync fence-agents-all resource-agents
```
- Bước 2: Khởi động pcsd
```sh
systemctl enable --now pcsd
```

- Bước 3: Thiết lập mật khẩu cho user hacluster
```sh
echo hacluster | passwd --stdin hacluster
```

- Bước 4: Xác thực với tất cả các node 
```sh
pcs host auth controller-vic.novalocal compute-vic01.novalocal compute-vic02.novalocal
``` 

- Bước 5: Khởi tạo cluster trên node controller
```sh
pcs cluster setup --start  ha_cluster controller-vic
pcs cluster enable --all
pcs cluster start --all
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
```

- Bước 6: Tạo các resource và remote host nova compute kết nối tới
```sh
scp /etc/pacemaker/authkey 14.225.23.248:/etc/pacemaker/authkey
scp /etc/pacemaker/authkey 14.225.23.232:/etc/pacemaker/authkey

pcs resource --force  create compute-vic02.novalocal ocf:pacemaker:remote
pcs resource --force  create compute-vic01.novalocal ocf:pacemaker:remote
```
***Lưu ý!!!***: Tên các node nova compute phải đúng tên của cột host trong lệnh `openstack compute service list`

*Kiểm tra lại bằng lệnh `pcs status` trên node controller và `systemctl status pacemaker-remote` trên compute*

---
**InstanceMonitor**
- Gán metadata cho VMs muốn thực hiện HA
```sh
openstack server set --property HA_Enabled=True <VM_name>
```



**Hostmonitor**
- Khởi tạo segment:
```sh
openstack segment create S2 auto COMPUTE
```

- Add các host compute vào segment:
```sh
openstack segment host create compute-vic01.novalocal COMPUTE SSH S2
openstack segment host create compute-vic02.novalocal COMPUTE SSH S2
```
