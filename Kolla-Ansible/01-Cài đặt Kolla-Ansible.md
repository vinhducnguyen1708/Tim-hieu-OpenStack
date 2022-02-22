# Cài đặt Kolla-Ansible
## Thông tin máy chủ
```
- HĐH: CentOS7
- RAM: 8GB
- CPU: 4vCPU
- HDD: 50GB
- NIC1 (eth0): 192.168.10.38
- NIC2 (eth1): 192.168.20.38
```
## Cài đặt Kolla-Ansible
- Sau khi cài đặt xong OS, ta thực hiện update HĐH:
```sh
yum update -y
```
- Thực hiện cài đặt các gói phụ thuộc
```sh
yum install -y epel-release
yum update -y
yum install python-devel libffi-devel gcc openssl-devel libselinux-python git wget byobu yum-utils python-setuptools vim -y
```
- Tiếp tục thực hiện cài đặt pip. Cập nhật bản pip mới nhất. Do kolla yêu cầu bản ansible từ 2.6 trở lên.
```sh
easy_install pip
pip install -U pip
pip install ansible==2.6.13
```

- Thực hiện cài đặt kolla-ansible tương ứng với phiên bản mới nhất (Train) của OpenStack:
```sh
pip install kolla-ansible==9.0.1
```	
	- Chi tiết các phiên bản xem [tại đây](https://releases.openstack.org/teams/kolla.html)

- Tạo thư mục chứa cấu hình cho kolla-ansible
```sh
mkdir -p /etc/kolla
chown $USER:$USER /etc/kolla
cp -r /usr/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
```
- Do cài đặt all-in-one nên ta sẽ sử dụng file inventory là all-in-one cho kolla-ansible:
```sh
cd ~
cp /usr/share/kolla-ansible/ansible/inventory/all-in-one .
```

- Thực hiện điều chỉnh cấu hình cho ansible bằng cách tạo file sau. Khi chạy ansible thì cấu hình này sẽ được load
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
- Thực hiện tạo password cho các thành phần của OpenStack
```sh
kolla-genpwd
```
- Backup lại file cấu hình toàn cục mà kolla-ansible sử dụng trước khi chỉnh sửa các thông số
```sh
cp /etc/kolla/globals.yml{,.org}
``` 