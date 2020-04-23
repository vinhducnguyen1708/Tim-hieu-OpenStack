## Đóng gói image Ubuntu16 chứa app Mysql



*Môi trường*: Cài đặt phần mềm diskimage-builder và các tool xử lý image như trong tài liệu [tại đây](https://github.com/vinhducnguyen1708/Tim-hieu-OpenStack/blob/master/Image%20Create/Disk-image-builder/Diskimage-Builder.md#3).


##  App Mysql

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
    - Trong đây bao gồm:
        
        - xenial: phiên bản Ubuntu16.04
        - amd64: chip xử lý
        - ubuntu-16-DIB: tên image
        - openssh-server: package cài đặt ssh
        - các elements: `ubuntu`, `vm`, `devuser`, `mysql-install`
- **Bước 3**: Thực hiện upload lên Openstack với file `ubuntu-16-DIB-mysql.qcow2`

