# Tạo Image Ubuntu 16.04

## Mục lục 
 - [1. Image Default](#1)
 - [2. App Mysql](#2)
 - [3. App Wordpress](#3)
 - [4. App Magento](#4)
 - [5. Package Apache, Nginx](#5)
 ---


*Môi trường*: Cài đặt phần mềm diskimage-builder và các tool xử lý image như trong tài liệu [tại đây](https://github.com/vinhducnguyen1708/Tim-hieu-OpenStack/blob/master/Image%20Create/Diskimage-Builder.md).

 <a name="1"></a>
## 1. Image Default

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

- **Bước 2**: Thực hiện lệnh tạo image:
    - ```
        DIB_RELEASE=xenial disk-image-create -a amd64 -o  ubuntu-16-DIB -p openssh-server  ubuntu vm devuser
        ```
    - Trong đây bao gồm:
        
        - xenial: phiên bản Ubuntu16.04
        - amd64: chip xử lý
        - ubuntu-16-DIB: tên image
        - openssh-server: package cài đặt ssh
        - các elements: `ubuntu`, `vm`, `devuser`

- **Bước 3**: Sau khi thực hiện chạy xong sẽ tạo ra file `ubuntu-16-DIB.qcow2`
có thể upload lên Openstack.

<a name="2"></a>
## 2. App Mysql

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

- **Bước 2**:

    - Thực hiện tạo một element `mysql-install` trong thư mục `/root/diskimage-builder/diskimage_builder/elements/`
    - Tạo thư mục `post-install.d/`
    - Tạo file script `mysql-install`  trong thư mục `/root/diskimage-builder/diskimage_builder/elements/post-install.d/`
     với nội dung: 

        ```
        echo "$(tput setaf 2)##### install-MYSQL #####$(tput sgr0)"\
        sleep 3
        apt-get upgrade -y
        sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password 123"
        sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password 123"
        apt-get install mysql-server -y
        apt-get update
        echo "$(tput setaf 2)##### config-MYSQL #####$(tput sgr0)"
        sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
        ```

    - Phân quyền `chmod +x mysql-install`

- **Bước 3**: Thực hiện lệnh tạo image:
    - ```
        DIB_RELEASE=xenial disk-image-create -a amd64 -o  ubuntu-16-DIB-mysql -p openssh-server  ubuntu vm devuser mysql-install
        ```
- **Bước 3**: Thực hiện upload lên Openstack với file `ubuntu-16-DIB-mysql.qcow2`

 <a name="3"></a>
## 3. App Wordpress

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

- **Bước 2**: Tạo element 
    - Thực hiện tạo một element `wordpress-install` trong thư mục `/root/diskimage-builder/diskimage_builder/elements/`
    - Tạo thư mục `post-install.d/`
    - Tạo file script `wordpress-install`  trong thư mục `/root/diskimage-builder/diskimage_builder/elements/post-install.d/`
     với nội dung:
        [SCRIPT TẠI ĐÂY](U16-script-Wordpress.sh)
    - Phân quyền `chmod +x mysql-install`
- **Bước 3**: Thưc hiện lệnh tạo image
   -    ```
        DIB_RELEASE=xenial disk-image-create -a amd64 -o  ubuntu-16-DIB-wordpress -p openssh-server  ubuntu vm devuser wordpress-install
        ```
- **Bước 4**: Thực hiện upload lên Openstack qua file `ubuntu-16-DIB-wordpress.qcow2`

- **Bước 5**: Vào dashboad khởi chạy máy ảo chứa Image. Trong bảng configuration
Nội dung truyền vào
    ```
    #cloud-config
    ssh_pwauth: True
    chpasswd:
        list: |
            root:{passforroot}
        expire: False

    # run command on first boot

    runcmd:
        - sudo /bin/bash /var/setup_app.sh
    ```    


 <a name="4"></a>
## 4. APP Magento

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
- **Bước 2**: Tạo element 
    - Thực hiện tạo một element `magento-install` trong thư mục `/root/diskimage-builder/diskimage_builder/elements/`
    - Tạo thư mục `post-install.d/`
    - Tạo file script `magento-install`  trong thư mục `/root/diskimage-builder/diskimage_builder/elements/post-install.d/`
     với nội dung:
        [SCRIPT TẠI ĐÂY](U16-script-magento.sh)
    - Phân quyền `chmod +x mysql-install`
- **Bước 3**: Thưc hiện lệnh tạo image
   -    ```
        DIB_RELEASE=xenial disk-image-create -a amd64 -o  ubuntu-16-DIB-magento -p openssh-server  ubuntu vm devuser mangento-install
        ```
- **Bước 4**: Thực hiện upload lên Openstack qua file `ubuntu-16-DIB-wordpress.qcow2`

- **Bước 5**: Vào dashboad khởi chạy máy ảo chứa Image. Trong bảng configuration
Nội dung truyền vào
    ```
    #cloud-config
    ssh_pwauth: True
    chpasswd:
        list: |
            root:{passforroot}
        expire: False

    # run command on first boot

    runcmd:
        - sudo /bin/bash /var/setup_app.sh
    ```    

 <a name="5"></a>
## 5. Apache

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
- - **Bước 3**: Thực hiện upload lên Openstack qua file `ubuntu-16-DIB-apache2.qcow2`

<a name="6"></a>
## 6. Nginx

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
- - **Bước 3**: Thực hiện upload lên Openstack qua file `ubuntu-16-DIB-nginx.qcow2`

```
#cloud-config
ssh_pwauth: True
chpasswd:
    list: |
        root:{passforroot}
    expire: False

# run command on first boot

runcmd:
    - sudo /bin/bash /var/setup_app.sh
```    