## Đóng gói image Ubuntu16 chứa app Magento

*Môi trường*: Cài đặt phần mềm diskimage-builder và các tool xử lý image như trong tài liệu [tại đây](https://github.com/vinhducnguyen1708/Tim-hieu-OpenStack/blob/master/Image%20Create/Diskimage-Builder.md).


 <a name="4"></a>
##  APP Magento

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
        [SCRIPT TẠI ĐÂY](script/U16-script-magento.sh)
    - Phân quyền `chmod +x mysql-install`
- **Bước 3**: Thưc hiện lệnh tạo image
   -    ```
        DIB_RELEASE=xenial disk-image-create -a amd64 -o  ubuntu-16-DIB-magento -p openssh-server  ubuntu vm devuser mangento-install
        ```
    - Trong đây bao gồm:
        
        - xenial: phiên bản Ubuntu16.04
        - amd64: chip xử lý
        - ubuntu-16-DIB: tên image
        - openssh-server: package cài đặt ssh
        - các elements: `ubuntu`, `vm`, `devuser`, `magento-install`
- **Bước 4**: Thực hiện upload lên Openstack qua file `ubuntu-16-DIB-wordpress.qcow2`

- **Bước 5**: Vào dashboad khởi chạy máy ảo chứa Image. Trong bảng configuration
Nội dung truyền vào
    ```
    #cloud-config
    ssh_pwauth: True
    chpasswd:
        list: |
            root:1234
        expire: False

    # run command on first boot

    runcmd:
        - mysql -uroot -p123 -e "CREATE DATABASE magentodb;"
        - mysql -uroot -p123 -e "CREATE USER 'magentouser'@'localhost' IDENTIFIED BY '12345';"
        - mysql -uroot -p123 -e "GRANT ALL ON magentodb.* TO 'magentouser'@'localhost' IDENTIFIED BY '12345' WITH GRANT OPTION;"
	    - mysql -uroot -p123 -e "FLUSH PRIVILEGES;"
    ```    

 