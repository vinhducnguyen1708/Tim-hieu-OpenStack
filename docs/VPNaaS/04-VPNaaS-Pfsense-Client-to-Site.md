# VPN client to site

*Trong bài viết này sẽ hướng dẫn sử dụng OpenVPN cài đặt trên Laptop Window kết nối tới VMs dải private, thông qua một VM Pfsense trên hệ thống Openstack*

## Mô hình hệ thống 

![ima](../images/vpnaas-clients-to-site01.png)


## Thiết lập VPN phía Pfsense

- Bước 1: Khởi tạo CAs

![ima](../images/vpnaas-clients-to-site02.png)

![ima](../images/vpnaas-clients-to-site03.png)


- Bước 2: Khởi tạo Cert cho Server

![ima](../images/vpnaas-clients-to-site04.png)

![ima](../images/vpnaas-clients-to-site05.png)

- Bước 3: Khởi tạo cert cho User

![ima](../images/vpnaas-clients-to-site06.png)

![ima](../images/vpnaas-clients-to-site07.png)

- Bước 4: Tạo user 

![ima](../images/vpnaas-clients-to-site08.png)

- Bước 5: Import Cert cho user

![ima](../images/vpnaas-clients-to-site09.png)

