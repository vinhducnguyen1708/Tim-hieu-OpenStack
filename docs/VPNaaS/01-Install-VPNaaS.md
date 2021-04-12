# Cài đặt và cấu hình VPNaaS trên Openstack

*Thực hiện trên phiên bản Openstack Ussuri*

*Thực hiện trên Centos8*

Neutron VPNaaS cung tính năng Virtual Private Network as a Service (VPNaaS). Từ phiên bản Queens VPNaaS không còn được tách thành một agent riêng( neuton-vpn-agent) mà trở thành extension của L3-agent.
## Thực hiện cài đặt cấu hình

- Bước 1: Cài đặt dịch vụ IPsec
```sh
dnf -y install libreswan
```

- Bước 2: Cấu hình sysctl 
```sh
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter = 0" >> /etc/sysctl.conf
```

- Bước 3: Reload lại sysctl
```sh
sysctl -p
```

- Bước 4: Khởi động dịch vụ IPsec
```sh
systemctl enable --now ipsec
```

- Bước 5: Cài đặt các gói của VPNaaS

```sh
dnf -y install openstack-neutron-vpnaas python3-neutron-vpnaas
``` 

- Bước 6: Cấu hình enable plug-in trong file cấu hình neutron `/etc/neutron/neutron.conf` 
```ini
[DEFAULT]
# ...
service_plugins = vpnaas
# ...
```

- Bước 7: Cấu hình service provider bằng các cấu hình file `/etc/neutron/neutron_vpnaas.conf` 
```ini
[service_providers]
service_provider = VPN:openswan:neutron_vpnaas.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default
```

- Bước 8: Cấu hình VPNaaS cho L3 agnet trong file `/etc/neutron/l3_agent.ini`
```ini
[AGENT]
extensions = vpnaas
[vpnagent]
vpn_device_driver = neutron_vpnaas.services.vpn.device_drivers.libreswan_ipsec.LibreSwanDriver
```

- Bước 9: Khởi dộng lại dịch vụ
```sh
systemctl restart neutron-server neutron-l3-agent
```

- Bước 10: chạy lệnh Khởi tạo table của VPN trong DB Neutron
```sh
neutron-db-manage --subproject neutron-vpnaas upgrade head
```

## Tính năng 

Việc triển khai VPNaaS của Openstack cung cấp:
- Site-to-site VPN, có thể kết nối 2 private networks
- Multiple VPN kết nối giữa các project
- IKE policy hỗ trợ mã hóa 3des, aes-128, aes-256, aes-192.
- IPsec policy hỗ trợ: 
    - Mã hóa  3des, aes-128, aes-256, aes-192 
    - Xác thực sha1
    - Giao thức tranform ESP, AH, AH-ESP
    - Cung cấp tunnel và transport đóng gói packet
- DPD ( Dead Peer Detection ) cung cấp các cơ chế hold, clear, restart, disabled, restart-by-peer.

- Các extension tượng trưng cho các tài nguyên:
    - `services`: Parent object liên kết VPN với subnet và router được chỉ định.
    - `ike policy`: The Internet Key Exchange (IKE) policy xác định thuật toán xác thực và mã hóa để sử dụng trong giai đoạn đàm phán 1 và 2 trước khi thiết lập kết nối VPN
    - `ipsecpolicy`: IP security policy chỉ định thuật toán xác thực mã hóa và cơ chế đóng gói packets sử dụng khi thiết lập kết nối VPN.
    - `ipsec-site-connection`: Thông tin cho kết nốt site-to-site IPsec, bao gồm: peer CIDRs, MTU, cơ chế xác thực, peer address, DPD và trạng thái.

