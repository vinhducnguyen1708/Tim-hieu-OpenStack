# Document deploy Openstack multinode by Kolla-Ansible

## Deploy a registry 

- Docker registry là 1 local registry lưu trữ các image cần pull từ Docker Hub
- Kolla vẫn có thể hoạt động dù có hoặc không dùng docker registry
- Docker registry dưới phiên bản 2.3 thì các container data đều được đẩy đến tất cả image nên  không được khuyến cáo sử dụng
- Chỉnh sửa file `/etc/kolla/globals.yml` và địa chỉ IP `192.168.1.100` là địa chỉ của node deployment làm docker registry local và port `5000` là port docker registry sử dụng để giao tiếp
```
docker_registry: 192.168.1.100:5000
```
- Cộng đồng Kolla khuyến cáo sử dụng docker registry 2.3 hoặc hơn, cách sử dụng
```
cd kolla
tools/start-registry
```
- Docker registry có cấu hình để pull được các images offcial của Kolla từ Docker Hub. Trong trường hợp sử dụng local registry để pull thì ở host machine thực hiện set biến môi trường `REGISTRY_PROXY_REMOTEURL` dẫn đến URL repo của Docker Hub
```
export REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io
```

## Cấu hình Docker on all nodes

- Để registry giao tiếp thì thực hiện cấu hình file `/etc/docker/daemon.json` khai báo thông số IP là IP của node chạy registry
```
{
  "insecure-registries" : ["192.168.1.100:5000"]
}
```
Thực hiện restart Docker:
For CentOS or Ubuntu with systemd:
```
systemctl restart docker
```
For Ubuntu with upstart or sysvinit:
```
service docker restart
```

## Chỉnh sửa file Inventory
- File Inventory của Ansible chứa thông tin cần thiết xác định rõ các service sẽ được thực hiện trên hosts nào.
- Chỉnh sửa file inventory có sẵn do Kolla cung cấp trong thư mục `ansible/inventory/multinode`. Nếu Kolla-Ansible được cài đặt bằng Pip thì file nằm ở `usr/share/kolla-ansible`
- Thêm IP hoặc hostname vào các group và các services đọc các group chứa các hosts đó để thực thi.
- Các IP hoặc hostname phải được khai báo ở các group `control`,`network`,`compute`,`monitoring`, `storage`.
- Có thể khai báo thêm các thông số như `ansible_ssh_user`, `ansible_become`, `ansible_private_key_file/ansible_ssh_pass` để kiểm soát ansible sẽ thực thi gì với remote hosts
```
# These initial groups are the only groups required to be modified. The
# additional groups are for more control of the environment.
[control]
# These hostname must be resolvable from your deployment host
control01      ansible_ssh_user=<ssh-username> ansible_become=True ansible_private_key_file=<path/to/private-key-file>
192.168.122.24 ansible_ssh_user=<ssh-username> ansible_become=True ansible_private_key_file=<path/to/private-key-file>
```
## Biến cho Host và group

- Bình thường các cấu hình của Kolla sẽ được lưu ở file `globals.yml`. Các biến trong file này sẽ áp cho tất cả các hosts. Trong môi trường cài đặt multinode, sẽ cần cài đặt thêm các biến khác nhau cho các node khác nhau .
- 1 Ví dụ đơn giản đó chính là mỗi node dùng một Network interface khác nhau làm `api_interface`. Có 2 cách:
```
# Host with a host variable.
[control]
control01 api_interface=eth3

# Group with a group variable.
[control:vars]
api_interface=eth4
```
- Hoặc có thể  khai báo trong thư mục `host_var`(thư mục chứa các file YAML có tên của host chứa các biến trên host đó) hoặc `group_vars`
```
inventory/
  group_vars/
    control
  host_vars/
    control01
  multinode
```
- Các biến được áp cho các playbook được khai báo ở `ansible/group_vars/all.yml` 
- Biến trong file `all.yml` sẽ ghi đề lên các biến được định nghĩa trong file inventory. 
- Các biến được lưu trong `globals.yml` sẽ có quyền cao nhất. Nên tất cả các biến khác nhau giữa các hosts thì không nên để trong file `globals.yml`

## Deploying Kolla

*Note*

- If there are multiple keepalived clusters running within the same layer 2 network, edit the file /etc/kolla/globals.yml and specify a keepalived_virtual_router_id. The keepalived_virtual_router_id should be unique and belong to the range 0 to 255.

- Nếu glance được cấu hình sử dụng  `file` làm backend, chỉ có duy nhất 1 container `glance_api` được khởi động và cài đặt. 
```
glance_backend_file: "{{ not (glance_backend_ceph | bool or glance_backend_swift | bool or glance_backend_vmware | bool) }}"
```
- Trong file `/etc/kolla/globals.yml` mặc định không khai báo các storage backend  nên mặc định thông số `glance_backend_file:` là `yes`


*First* 
- Check các trạng thái của remote hosts để Kolla có thể deploy trên đó:
```
kolla-ansible prechecks -i <path/to/multinode/inventory/file>
```
*Run the deployment:*
```
kolla-ansible deploy -i <path/to/multinode/inventory/file>
```



