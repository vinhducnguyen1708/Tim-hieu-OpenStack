# Upgrade phiên bản cho hệ thống Openstack

## Tổng quan về Upgrade
1. Upgrade planning
 
*Trước khi thực hiện upgrade cần lưu ý!*

- Cần đọc kỹ các `release notes` xem có gì mới, những gì đã được updated, những gì đã được loại bỏ từ phiên bản trước. Tìm sự không tương thích giữa các phiên bản.

- Xem xét sự ảnh hưởng của việc upgrade với người dùng. Quá trình upgrade sẽ làm gián đoạn việc quản lý của bạn trên hệ thống. Nếu bạn đã thực sự chuẩn bị cho việc upgrade thì trong quá trình upgrade, các VMs , networks, hệ thống lưu trữ vẫn phải được vận hành. Tuy nhiên, các VMs có thể bị gián đoạn việc mất kết nối network.

- Bạn vẫn có thể upgrade với hệ thống đang có các VMs đang chạy, nhưng việc này rất nguy hiểm. Bạn nên cân nhắc việc sử dụng `live migration` để tạm thời di chuyển các VMs sang node compute khác khi thực hiện quá trình upgrades. Tuy nhiên, bạn phải chắc chắn rằng database không bị mất dữ liệu trong cả quá trình: nếu không hệ thống của bạn sẽ trở nên không ổn định. 

- Để ý việc khai báo các thông tin trong file cấu hình của các service, hợp nhất các tùy chọn của file cấu hình của phiên bản cũ với file cấu hình của phiên bản mới.

- Như việc nâng cấp các hệ thống lớn, việc upgrade có thể bị thất bại vì một hay nhiều lí do. Bạn có thể chuẩn bị cho vấn đề này bằng cách có khả năng sẵn có bản backup để phục hồi lại hệ thống của phiên bản trước, bao gồm: Databases, file cấu hình cũ, packages cũ. 


2. Upgrade process

*Quá trình thử nghiệm upgrade hệ thống Openstack với 2 node (1 controller, 1 compute). Ở đây tôi cài đặt phiên bản Stein và sẽ upgrade lên phiên bản Train*

2.1  Các service upgrade:
    - Neutron 
    - Nova
    - Keystone
    - Cinder
    - Heat


3. Chuẩn bị

- Thực hiện một số thao tác làm sạch hệ thống trước khi thực hiện upgrade để có được trạng thái tốt nhất. Ví dụ, Những VMs không được gỡ ra hoàn toàn sau quá trình xóa sẽ dẫn tới những rủi ro không xác định được.

- Cho hệ thống sử dụng Neutron. cần xác thực phiên bản database.
```sh
 su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini current" neutron
```

4. Thực hiện backup
- Tạo thư mục backup và backup tất cả các file cấu hình cho hệ thống
```sh
for i in keystone glance nova neutron openstack-dashboard cinder heat ; \
  do mkdir $i-Stein; \
  done

for i in keystone glance nova neutron openstack-dashboard cinder heat ; \
  do cp -r /etc/$i/* $i-Stein/; \
  done
```

- Thực hiện backup database hệ thống
```sh
mysqldump -u root -p --opt --add-drop-database --all-databases > Stein-db-backup.sql
```

5. Quản lý repo

*Trên tất cả các node* 
- B1: Xóa tất cả các repository của phiên bản cũ
- B2: Thêm repository của phiên bản mới
- B3: Thực hiện update repository của database 

6. Upgrade Packages trên mỗi node

7. Update services

*Để update service thên mỗi node, bạn cần sửa đổi file cấu hình , stop service đó, đồng bộ database rồi start service. Một vài service sẽ có các bước khác. Nên kiểm tra lại service sau khi chuyến đến upgrade service khác.


    - Keystone: Xóa hết các Token hết hạn trước khi đồng bộ hóa DB
    - Horizon: Update packages rồi restart service HTTP
    - Nova-Compute: Chỉnh sửa file cấu hình rồi khởi động lại dịch vụ
    - OVS-agent: Chỉnh sửa file cấu hình rồi khởi động lại dịch vụ

## Thực hiện upgrade

### Neutron Upgrade


1. Cách thức thực hiện

- Bước 1: Thực hiện stop service neutron-server
```sh
systemctl stop neutron-server
```

- Bước 2: Thực hiện xóa repo phiên bản cũ
```sh
yum -y remove centos-release-openstack-stein

rm -rf /etc/yum.repos.d/CentOS-OpenStack-stein.repo
```

- Bước 3: Thực hiện Update package cho phiên bản mới
```sh
yum -y install centos-release-openstack-train

yum -y update openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch ebtables libibverbs
```

- Bước 4: Thực hiện chỉnh sửa file cấu hình 

- Bước 5: Upgrade DB
```sh
# Mở rộng Database với các dữ liệu tính năng (tables ,column) của hệ thống mới
neutron-db-manage upgrade --expand

# Xóa các dữ liệu tính năng của hệ thống cũ
neutron-db-manage upgrade --contract
```

- Bước 5: Khởi động lại toàn bộ services
```sh
systemctl restart neutron-server.service neutron-openvswitch-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service
```

### Nova Upgrade

1. Cách thực hiện 

- Bước 1: Cài đặt package phiên bản mới
```sh
yum -y update openstack-nova-api openstack-nova-conductor openstack-nova-novncproxy openstack-nova-scheduler
```

- Bước 2: Chỉnh sửa lại file cấu hình `/etc/nova/nova.conf`
```sh
# THêm thẻ trong file cấu hình
[upgrade_levels]
compute = auto
```

- Bước 3: Thực hiện đồng bộ hóa DB
```sh
nova-manage api_db sync

nova-manage db sync
```


### Placement Upgrade

1. Cách thực hiện 

- Bước 1: Update package phiên bản mới
```sh
yum -y upgrade openstack-placement-api
```

- Bước 2: Chỉnh sửa lại file cấu hình 

- Bước 3: Thực hiện check việc đồng bộ hóa của NOva
```sh
placement-status upgrade check

# Kết quả
[root@controller1 ~]# placement-status upgrade check
+----------------------------------+
| Upgrade Check Results            |
+----------------------------------+
| Check: Missing Root Provider IDs |
| Result: Success                  |
| Details: None                    |
+----------------------------------+
| Check: Incomplete Consumers      |
| Result: Success                  |
| Details: None                    |
+----------------------------------+
```

- Bước 4: Đồng bộ DB placement
```sh
 placement-manage db sync
```

### Keystone Upgrade

- Bước 1: Dừng dịch vụ http
```sh
systemctl stop httpd
```

- Bước 2: Update package phiên bản mới
```sh

yum -y upgrade openstack-keystone httpd mod_wsgi
```
- Bước 3: Chỉnh sửa lại file cấu hình 
```sh
# Thêm thẻ
[cache]
backend = oslo_cache.memcache_pool
enabled = True
memcached_servers = 192.168.10.101:11211
```

- Bước 4: Thực hiện kiểm tra trước khi đồng bộ và làm theo chỉ dẫn nếu có
```sh
keystone-manage doctor 
```

- Bước 5: Đồng bộ hóa DB
```sh
keystone-manage db_sync --expand

keystone-manage db_sync --migrate

keystone-manage db_sync --contract 

```

- Bước 6: Kiểm tra lại việc đồng bộ hóa 
```sh
keystone-manage db_sync --check
```

- Bước 7: Khởi động lại dịch vụ HTTP
```sh
systemctl start httpd
```


### Cinder upgrade

### Glance Upgrade

- Bước 1: Dừng dịch vụ Image
```sh
systemctl stop openstack-glance-api
```

- Bước 2: Upgrade gói cài đặt phiên bản mới
```shs
yum -y upgrade openstack-glance
```

- Bước 3: Chính sửa lại file cấu hình 

- Bước 4: Đồng bộ hóa database
```sh
glance-manage db expand

glance-manage db migrate

glance-manage db contract
```

- Bước 5: Khởi động lại dịch vụ
```sh
systemctl start openstack-glance-api
```


#### Heat Upgrade

- B1: Upgrade packages phiên bản mới
```sh
yum -y upgrade openstack-heat-api openstack-heat-api-cfn openstack-heat-engine openstack-heat-ui
```

- B2: Chỉnh sửa file cấu hình
```sh
# Thêm cấu hình vhost cho rabbitmq
[DEFAULT]
transport_url = rabbit://openstack:4ychZAT5VrWlk6KFfgAmpXvGdzfdV8hEpIgOLhyF@192.168.10.101:5672
```

- B3: Thực hiện đồng bộ hóa DB
```sh
heat-manage db_sync
```

- B4: Khởi động lại service Heat-api và Heat-engine
```sh
systemctl restart openstack-heat-api
systemctl restart openstack-heat-cfn
```

#### Upgrade Horizon

- B1: Upgrade packages phiên bản mới
```sh
yum -y upgrade openstack-dashboard
```

- B2: Chỉnh sửa lại file cấu hình

- B3: Khởi động lại dịch vụ HTTP
```sh
systemctl restart httpd
```


#### Đối với dịch vụ trên node compute

- Thực hiện upgrade packages cho các dịch vụ
```sh
yum -y upgrade openstack-nova-compute libvirt-client  openstack-neutron-openvswitch ebtables ipset
```

- B2: Chỉnh lại file cấu hình phù hợp với phiên bản mới

- B3: Khởi động lại tất cả các dịch vụ
```sh
systemctl restart libvirtd.service openstack-nova-compute.service

systemctl restart neutron-openvswitch-agent.service 
```
