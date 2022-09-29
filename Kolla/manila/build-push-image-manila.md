# Build and Push Image Manila

## Why

Hiện tại Manila chưa hỗ trợ tích hợp backend CephFS NFS, khi sử dụng driver `cephfs` của Manila chỉ có thể kết nối trực tiếp đến service Ganesha thông qua dbus để tạo NFS.
Việc này khiến nếu ta dựng NFS Ganesha thông qua Ceph adm thì sẽ không sử dụng được backend này.

## How 

Để sử dụng được tính năng này ta cần sửa code của manila share.
Gọi đến NFS Ganesha thông qua ceph client.

Hướng dẫn triển khai manila [tại đây](linkin).

1. Sửa code tại các file trong thư mục

- Truy cập vào thư mục sẽ build image `manila-share`

```sh
cd /kolla/manila/manila-base
```

- Cập nhật Dockerfile và file code 

2. Thực hiện build image

- Xóa các image tồn tại
```sh
for i in `docker ps -a | grep manila | awk '{print$1}'`; do docker rm -f $i --force; done
for i in `docker images | grep manila | awk '{print$3}'`; do docker image rm $i --force; done
```

- Chạy lệnh sau để build Image:
```sh
/root/kolla/.tox/genconfig/bin/kolla-build -b ubuntu manila --skip-existing
```

3. Push Image để sử dụng

- Đổi tag image trước khi push
```sh
docker tag kolla/ubuntu-source-manila-share:13.0.2  registry.cloudvnpt.com/kolla/openstack.kolla/ubuntu-source-manila-share:13.0.2
docker tag kolla/ubuntu-source-manila-api:13.0.2  registry.cloudvnpt.com/kolla/openstack.kolla/ubuntu-source-manila-api:13.0.2
docker tag kolla/ubuntu-source-manila-data:13.0.2  registry.cloudvnpt.com/kolla/openstack.kolla/ubuntu-source-manila-data:13.0.2
docker tag kolla/ubuntu-source-manila-scheduler:13.0.2  registry.cloudvnpt.com/kolla/openstack.kolla/ubuntu-source-manila-scheduler:13.0.2
```

- Thực hiện push bằng lệnh sau:
```sh
docker push registry.cloudvnpt.com/kolla/openstack.kolla/ubuntu-source-manila-share:13.0.2
docker push registry.cloudvnpt.com/kolla/openstack.kolla/ubuntu-source-manila-api:13.0.2
docker push registry.cloudvnpt.com/kolla/openstack.kolla/ubuntu-source-manila-scheduler:13.0.2
docker push registry.cloudvnpt.com/kolla/openstack.kolla/ubuntu-source-manila-data:13.0.2
```

---
## TK
[1] https://review.opendev.org/c/openstack/manila/+/848987