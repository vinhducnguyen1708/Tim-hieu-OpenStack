# Build Amphora Image

Bài viết này sẽ hướng dẫn đóng Image Amphora cho project Octavia

## Server DIB
- OS: Ubuntu 18.04
  - Ram: 2GB
  - CPU: 2c
  - Disk: 100Gb

### Cài đặt cho Server DIB

- B1: update và upgrade packages
```sh
apt-get -y update
apt-get -y upgrade
```

- B2: Set hostname 
```sh
hostnamectl set-hostname dib-image
```

- B3: Cài đặt repo
```sh
sudo apt-get install software-properties-common
sudo apt-add-repository universe
sudo apt-get update
sudo apt-get -y install alien
sudo apt-get -y install yum-utils
sudo apt-get update
```

- B4: Cài đặt các tool và gói cần thiết 
```sh
sudo apt-get -y install python-pip
sudo apt-get -y install git
```

- B5: Clone repo DIB từ github
```sh
git clone https://github.com/openstack/diskimage-builder.git
```

- B6: Cài đặt module yêu cầu
```sh
cd diskimage-builder/

sudo pip install -r requirements.txt
```

- B7: Cài đặt DIB
```sh
pip install diskimage-builder
```
- B8: Cài đặt các gói hỗ trợ quá trình build image
```sh
apt install -y qemu qemu-kvm libvirt-bin  bridge-utils  virt-manager
apt-get install -y qemu-user-static
apt-get -y install qemu-utils git kpartx debootstrap
```


- Bước 1: Clone các git repository cần thiết
```sh
git clone https://github.com/stackforge/octavia.git
git clone https://git.openstack.org/openstack/tripleo-image-elements.git
```

- Bước 2: Chuyển branch sang ussuri
```sh
cd octavia/
git checkout stable/ussuri
```

- Bước 3: Vì Script của Octavia khi chạy không lấy elements được chỉ định theo path mà sẽ chỉ lấy elements đã được cài đặt bằng pip nên ta phải sửa đoạn script cài đặt pip cho python2
```sh
root@dib-image:~# vim /usr/local/lib/python2.7/dist-packages/diskimage_builder/elements/pip-and-virtualenv/source-repository-pip-and-virtualenv

pip-and-virtualenv file /tmp/get-pip.py https://bootstrap.pypa.io/pip/2.7/get-pip.py
```

- Bước 4: Thêm các elements để custom cho Image nếu cần thiết. Ở đây tôi sẽ cài đặt filebeat trong Image này 
```sh 
mkdir -p elements/filebeat/post-install.d
```

- Bước 5: Chỉnh sửa file script elements/filebeat/post-install.d/ubuntu-filebeat với nội dung:
```sh
#!/bin/bash

echo "Install FileBeat"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
sudo apt-get update
sudo apt-get install filebeat -y


echo "Enable service filebeat"

systemctl enable filebeat

echo "Config Filebeat"

cat <<EOF > /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: log
  enabled: false
  paths:
    - /var/log/*.log
- type: filestream
  enabled: false
  paths:
    - /var/log/*.log
filebeat.config.modules:
  path: \${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:
output.elasticsearch:
  hosts: ["localhost:9200"]
processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
EOF
```
- Bước 6: Phân quyền cho script
```sh
chmod +x elements/filebeat/post-install.d/ubuntu-filebeat
```

- Bước 7: chỉnh sửa lệnh chạy diskimage-create để khai báo thêm element `filebeat` trong file `octavia/diskimage-create/diskimage-create.sh`
```sh
#...
disk-image-create $AMP_LOGFILE $dib_trace_arg -a $AMP_ARCH -o $AMP_OUTPUTFILENAME -t $AMP_IMAGETYPE --image-size $AMP_IMAGESIZE --image-cache $AMP_CACHEDIR $AMP_DISABLE_TMP_FS $AMP_element_sequence filebeat
#...
```

- Bước 8: Thực hiện chạy lệnh build image
```sh
cd octavia/diskimage-create/
./diskimage-create.sh -g stable/train  -d bionic -i ubuntu 
```

## Kiểm tra


----
## TK

[1] https://opendev.org/openstack/octavia/commit/9df9ff9137af0d4602283232dc1352cb6b43a3d1

[2] https://ask.openstack.org/en/question/116606/how-to-create-an-amphora-image-for-octavia/