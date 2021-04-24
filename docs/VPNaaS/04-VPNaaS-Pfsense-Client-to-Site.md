# VPN client to site

*Trong bài viết này sẽ hướng dẫn sử dụng OpenVPN cài đặt trên Laptop Window kết nối tới VMs dải private, thông qua một VM Pfsense trên hệ thống Openstack*

*Thực hiện cài đặt server Pfsense phiên bản 2.5.1* (Hướng dẫn cài đặt [tại đây](https://github.com/longsube/Tim-hieu-pfSense/blob/master/docs/pfSense-install.md))



## Mô hình hệ thống 

![ima](../../images/vpnaas-clients-to-site01.png)


## Thiết lập VPN phía Pfsense

- Bước 1: Khởi tạo CAs

    ![ima](../../images/vpnaas-clients-to-site02.png)

    ![ima](../../images/vpnaas-clients-to-site03.png)


- Bước 2: Khởi tạo Cert cho Server

    ![ima](../../images/vpnaas-clients-to-site04.png)

    ![ima](../../images/vpnaas-clients-to-site05.png)

- Bước 3: Khởi tạo cert cho User

    ![ima](../../images/vpnaas-clients-to-site06.png)

    ![ima](../../images/vpnaas-clients-to-site07.png)

- Bước 4: Tạo user 

    ![ima](../../images/vpnaas-clients-to-site08.png)

- Bước 5: Import Cert cho user

    ![ima](../../images/vpnaas-clients-to-site09.png)

- Bước 6: Tải VPN Client Export

    ![ima](../../images/vpnaas-clients-to-site10.png)

- Bước 7: Khởi tạo OpenVPN Server

    - `Server mode: Remote Access (SSL/TLS + User Auth)` Chọn mode Remote Access và xác thực qua cert và user passwords
    - `Backend for authentication: Local Database` Chọn Backend đang lưu trữ thông tin user
    - `Protocol: UDP IPV4 and IPV6 on all interfaces` Chọn Protocol sẽ giao tiếp là UDP trên tất cả các interfaces
    - `Local port: 1194` Port UDP
    - `Description: VPN-VNPT-IT-TUN` Khai báo tên server

    ![ima](../../images/vpnaas-clients-to-site11.png)

    - `Peer Certificate Authority: server-ca` CA đã tạo ở bước 1
    - `Server certificate: server-cert` Cert dành cho server đã tạo ở bước 2

    ![ima](../../images/vpnaas-clients-to-site12.png)

    ![ima](../../images/vpnaas-clients-to-site13.png)

    - `IPv4 Tunnel Network: 192.168.17.0/24` Virtual network tự khai báo cấp DHCP cho các clients
    - `IPv4 local networks: 192.168.100.0/24` Dải Private network mà client muốn kết nối tới
    - `Concurrent connections: 20` Số lượng clients có thể kết nối đồng thời đến OpenVPN server

    ![ima](../../images/vpnaas-clients-to-site14.png)

    ![ima](../../images/vpnaas-clients-to-site15.png)

    - `Custom options: route 192.168.100.0 255.255.255.0` Add route cho client

    ![ima](../../images/vpnaas-clients-to-site16.png)


- Bước 8: Add Interface cho OpenVPN server

    ![ima](../../images/vpnaas-clients-to-site17.png)

    ![ima](../../images/vpnaas-clients-to-site18.png)


- Bước 9: Mở hết rules cho các Interface trên Pfsense

- Bước 10: Thực hiện lưu lại OpenVPN server đã tạo ở bước 7 lần nữa để lấy cấu hình cho OpenVPN Interface

    *Kết quả OpenVPN Interface lấy được IP*

    ![ima](../../images/vpnaas-clients-to-site19.png)


- Bước 11: Client Export, Khai báo, Lưu lại và Download cert và cấu hình

    - `Remote Access Server: VPN-VNPT-IT-TUN:1194` OpenVPN server đã tạo ở bước 7
    - `Host Name Resolution: Other`
    - `Host Name: 123.456.7.8` Là IP WAN của Pfsense

    ![ima](../../images/vpnaas-clients-to-site20.png)

    ![ima](../../images/vpnaas-clients-to-site21.png)



## Thực hiện trên Client OpenVPN

- Bước 1: Copy toàn bộ cert và cấu hình vào thư mục `C:\Program Files\OpenVPN\config` ( tùy bạn lưu config cho OpenVPN ở đâu)

- Bước 2: Khởi động lại OpenVPN và kết nối 

    ![ima](../../images/vpnaas-clients-to-site22.png)

    - Khai báo user passwords

    ![ima](../../images/vpnaas-clients-to-site23.png)

    - Check lại log

    ![ima](../../images/vpnaas-clients-to-site24.png)


----
 
## Tài liệu chi tiết xem tại đây:

[1] https://github.com/longsube/Tim-hieu-pfSense/blob/master/docs/pfSense-OpenVPN-TUNmode.md

[2] https://github.com/longsube/Tim-hieu-pfSense/blob/master/docs/pfSense-OpenVPN-TUN-OpenStackVM.md

[3] https://github.com/longsube/Tim-hieu-pfSense/blob/master/docs/pfSense-install.md