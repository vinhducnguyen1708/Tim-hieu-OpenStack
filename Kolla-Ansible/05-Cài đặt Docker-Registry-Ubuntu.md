# Install Docker Registry on Ubuntu 20.04
 
*Đây là một máy chủ tách riêng, độc lập với cụm Openstack Kolla*

**Cấu hình:**
- CPU: 2 
- RAM: 4 GB
- Disk: 80 GB
- IP: eth0 - 192.168.60.116, eth1 - 192.168.50.28
- Hệ điều hành: Ubuntu 20.04

## 1. Cài đặt, cấu hình cơ bản
- Cập nhật các gói phần mềm:
```sh
apt -y update && apt -y upgrade
```

- Khởi động lại máy để update kernel:
```sh
init 6
```

- Cấu hình network:
```sh
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address 192.168.60.116
netmask 255.255.255.0
gateway 192.168.60.1
dns-nameservers 8.8.8.8 8.8.4.4

auto eth1
iface eth1 inet static
address 192.168.50.28
netmask 255.255.255.0
EOF
```

- Khởi động lại interfaces:
```sh
ifdown -a && ifup -a
```

## 2. Cài đặt docker
- Cài đặt các phần mềm cần thiết để sử dụng https:
```sh
sudo apt install apt-transport-https ca-certificates curl software-properties-common
```

- Thêm GPG key cho docker repository:
```sh
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

- Thêm docker repository vào cấu hình apt:
```sh
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
```
- Chạy lệnh sau để chắc chắn cài docker từ repository của docker
```sh
apt-cache policy docker-ce
```

- Cài đặt Docker:
```sh
sudo apt install docker-ce -y
```
- Kiểm tra docker hoạt động:
```sh
sudo systemctl status docker

docker version
```

## 3. Cài đặt Docker Registry

- Tạo thư mục lưu trữ cert
```sh
mkdir -p docker_reg_certs
```

- Generate cert và key cho docker registry:
```sh
openssl req  -newkey rsa:4096 -nodes -sha256 -keyout docker_reg_certs/domain.key -x509 -days 365 -out docker_reg_certs/domain.crt
```

- Triển khai container registry:
```
docker run -d -p 5000:5000 --restart=always --name registry -v $PWD/docker_reg_certs:/certs -v /reg:/var/lib/registry -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key  registry:2
```

## Cấu hình Registry client
*Cấu hình tại các máy chủ pull image*
- Vì docker registry sử dụng self-sign cert nên các client khi gọi phải chọn insecure để truy cập. Tại file `/etc/docker/daemon.json` bổ sung cấu hình dưới đây:
```json
{
  "insecure-registries": ["192.168.60.116:5000"]
}
```

- Restart lại docker:
```sh
systemctl restart docker
```

- Kiểm tra lại bằng cách chạy lệnh dưới đây:
```sh
curl https://192.168.60.116:5000/v2/_catalog
```

- Pull thử image từ docker registry bằng lệnh:
```sh
docker pull 192.168.60.116:5000/openstack.kolla/ubuntu-source-horizon:13.0.2
```

---
## TK
https://medium.com/@ifeanyiigili/how-to-setup-a-private-docker-registry-with-a-self-sign-certificate-43a7407a1613