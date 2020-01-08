 ## Đóng gói image Ubuntu16 chứa ứng dụng Apache,Nginx

- [1. Apache](#1)
- [2. Nginx](#2)


*Môi trường*: Cài đặt phần mềm diskimage-builder và các tool xử lý image như trong tài liệu [tại đây](https://github.com/vinhducnguyen1708/Tim-hieu-OpenStack/blob/master/Image%20Create/Diskimage-Builder.md).

 <a name="1"></a>
## 1. Apache

- **Bước 1**: thực hiện export các biến đưa vào elements

    ```
    # Đường dẫn đến thư mục chứa elements
    export ELEMENTS_PATH=/root/diskimage-builder/diskimage_builder/elements/
    # Gán username mặc định cho image
    export DIB_DEV_USER_USERNAME=vinhdn178
    # Gán shell cho user
    export DIB_DEV_USER_SHELL=/bin/bash
    # Enable passwordless sudo for the user (tùy chọn)
    export DIB_DEV_USER_PWDLESS_SUDO=yes
    # Gán pass cho user
    export DIB_DEV_USER_PASSWORD=12345
    ```
 - **Bước 2**: Thưc hiện lệnh tạo image
   -    ```
        DIB_RELEASE=xenial disk-image-create -a amd64 -o  ubuntu-16-DIB-apache2 -p openssh-server,apache2  ubuntu vm devuser 
        ```
    - Trong đây bao gồm:
        
        - xenial: phiên bản Ubuntu16.04
        - amd64: chip xử lý
        - ubuntu-16-DIB: tên image
        - openssh-server,apache2: package cài đặt ssh
        - các elements: `ubuntu`, `vm`, `devuser`
- **Bước 3**: Thực hiện upload lên Openstack qua file `ubuntu-16-DIB-apache2.qcow2`

<a name="2"></a>
## 2. Nginx

- **Bước 1**: thực hiện export các biến đưa vào elements

    ```
    # Đường dẫn đến thư mục chứa elements
    export ELEMENTS_PATH=/root/diskimage-builder/diskimage_builder/elements/
    # Gán username mặc định cho image
    export DIB_DEV_USER_USERNAME=vinhdn178
    # Gán shell cho user
    export DIB_DEV_USER_SHELL=/bin/bash
    # Enable passwordless sudo for the user (tùy chọn)
    export DIB_DEV_USER_PWDLESS_SUDO=yes
    # Gán pass cho user
    export DIB_DEV_USER_PASSWORD=12345
    ```
 - **Bước 2**: Thưc hiện lệnh tạo image
   -    ```
        DIB_RELEASE=xenial disk-image-create -a amd64 -o  ubuntu-16-DIB-nginx -p openssh-server,nginx  ubuntu vm devuser 
        ```
    - Trong đây bao gồm:
        
        - xenial: phiên bản Ubuntu16.04
        - amd64: chip xử lý
        - ubuntu-16-DIB: tên image
        - openssh-server,nginx: package cài đặt ssh
        - các elements: `ubuntu`, `vm`, `devuser`
- - **Bước 3**: Thực hiện upload lên Openstack qua file `ubuntu-16-DIB-nginx.qcow2`
