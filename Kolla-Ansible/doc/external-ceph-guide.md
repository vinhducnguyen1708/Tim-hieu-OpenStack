# External Ceph

Kolla Ansible không hỗ trợ cài đặt cấu hình trực tiếp Ceph Cluster. Bạn cần sử dụng các công cụ như:
- ceph-ansible 
- ceph-adm

Việc khởi tạo pool, keyrings phải được khởi tạo thông qua module hoặc CEPH CLI,...

# Requirements
- Tồn tại sẵn một hạ tầng CEPH Cluster
- Có sẵn Ceph pool lưu trữ
- Có sẵn xác keyring xác thực cho các service trong Openstack kết nối tới CEPH

Tham khảo tài liệu [tại đây](https://docs.ceph.com/en/latest/rbd/rbd-openstack/)

# Configuring External Ceph
Cấu hình tích hợp Ceph khác với các service Openstack vì nó độc lập.
## Cinder

1. Khi sử dụng external CEPH cluster, cần chỉ định node cài đặt cinder-volume và cinder-backup nên trong file inventory cần chỉ định host làm controller trong group `[storage]`
```ini
[storage]
kolla-controller anisble_host=192.168.60.238 ansible_connection=ssh     ansible_user=root
```
2. Thiết lập biến để cấu hình ceph backend trong `/etc/kolla/globals.yml`
```yml
enable_cinder: "yes"
cinder_backend_ceph: "yes"
```
3. Copy thư mục từ cụm CEPH cluster sang máy chủ chạy Kolla Ansible

*Đứng từ máy chủ ceph-mon*

```sh
scp -r /etc/ceph root@192.168.60.238:/etc/
```

4. Thiết lập giá trị biến xác thực trong `/etc/kolla/globals.yml`:
```yml
# Glance ceph credential
ceph_glance_keyring: "ceph.client.glance.keyring"
ceph_glance_user: "glance"
ceph_glance_pool_name: "images"
# Cinder ceph credential
ceph_cinder_keyring: "ceph.client.cinder.keyring"
ceph_cinder_user: "cinder"
ceph_cinder_pool_name: "volumes"
ceph_cinder_backup_keyring: "ceph.client.cinder-backup.keyring"
ceph_cinder_backup_user: "cinder-backup"
ceph_cinder_backup_pool_name: "backups"
# Nova ceph credential
ceph_nova_user: "cinder"
```

5. Tạo thư mục cấu hình cho các service và copy cert vào thư mục đó
```sh
mkdir -p /etc/kolla/config/cinder/cinder-volume
mkdir -p /etc/kolla/config/cinder/cinder-backup

cp /etc/ceph/ceph.client.cinder.keyring /etc/kolla/config/cinder/cinder-volume/
cp /etc/ceph/ceph.client.cinder-backup.keyring /etc/kolla/config/cinder/cinder-backup/
cp /etc/ceph.client.cinder.keyring /etc/kolla/config/cinder/cinder-backup/
```
### Cinder multi backend

- Trong file `/etc/kolla/globals.yml`:

```yml
ceph_backend:
    - name: "ceph_ssd"
      pool: "volumes_ssd"
    - name: "ceph_hdd"
      pool: "volumes_hdd"
```

- Trong file `/usr/local/share/kolla-ansible/ansible/roles/cinder/defaults/main.yml`:
```yml
####################
# Cinder
####################
cinder_backends:
  - name: "{{ ceph_backend | map(attribute='name') | join(',') }}" ### Thay thế rbd-1
    enabled: "{{ cinder_backend_ceph | bool }}" ### Thay thế rbd-1
  - name: "lvm-1"
    enabled: "{{ enable_cinder_backend_lvm | bool }}"
  - name: "nfs-1"
    enabled: "{{ enable_cinder_backend_nfs | bool }}"
  - name: "hnas-nfs"
    enabled: "{{ enable_cinder_backend_hnas_nfs | bool }}"
  - name: "vmwarevc-vmdk"
    enabled: "{{ cinder_backend_vmwarevc_vmdk | bool }}"
  - name: "QuobyteHD"
    enabled: "{{ enable_cinder_backend_quobyte | bool }}"

skip_cinder_backend_check: False
cinder_enabled_backends: "{{ cinder_backends | selectattr('enabled', 'equalto', true) | list }}"
```

- Trong file `/usr/local/share/kolla-ansible/ansible/roles/cinder/templates/cinder.conf.j2`
```ini
{% if cinder_backend_ceph | bool %}
{% for backend in ceph_backend %}
[{{ backend.name }}]
volume_driver = cinder.volume.drivers.rbd.RBDDriver
volume_backend_name = {{ backend.name }}
rbd_pool = {{ backend.pool }}
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_flatten_volume_from_snapshot = false
rbd_max_clone_depth = 5
rbd_store_chunk_size = 4
rados_connect_timeout = 5
rbd_user = {{ ceph_cinder_user }}
rbd_secret_uuid = {{ cinder_rbd_secret_uuid }}
report_discard_supported = True
image_upload_use_cinder_backend = True
{% endfor %}
{% endif %}
```

## Glance

1. Bổ sung biến sau để enable cấu hình glance sử dụng ceph backend trong file `/etc/kolla/globals.yml`:
```yml
glance_backend_ceph: 'yes'
glance_backend_file: 'yes'
```
2. Bổ sung biến sau để cấu hình glance tìm image thông qua url rbd trong file `/usr/local/share/kolla-ansible/ansible/roles/glance/templates/glance-api.conf.j2`
```ini
{% if glance_backend_ceph | bool %}
show_multiple_locations = True
show_image_direct_url = True
{% endif %}
```

## Nova
1. Bổ sung biến sau để enable cấu hình nova sử dụng ceph backend trong file `/etc/kolla/globals.yml`:
```yml
nova_backend_ceph: "yes"
```

2. hiện tại hệ thống của tôi VM sử dụng trực tiếp pool volumes nên comment 3 dòng sau trong file `/usr/local/share/kolla-ansible/ansible/roles/nova-cell/templates/nova.conf.d/libvirt.conf.j2`
```ini
{% if nova_backend == "rbd" %}
#images_type = rbd
#images_rbd_pool = {{ ceph_nova_pool_name }}
#images_rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = {{ ceph_nova_user }}
disk_cachemodes="network=writeback"
{% if nova_hw_disk_discard != '' %}
hw_disk_discard = {{ nova_hw_disk_discard }}
{% endif %}
{% endif %}
{% if nova_backend == "rbd" and external_ceph_cephx_enabled | bool %}
rbd_secret_uuid = {{ rbd_secret_uuid }}
{% endif %}
```

