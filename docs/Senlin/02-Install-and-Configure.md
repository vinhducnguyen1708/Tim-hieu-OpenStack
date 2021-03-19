# Cài đặt và cấu hình Senlin

*Phiên bản Openstack Victoria*

## Mô tả hệ thống

*Mô hình 1 node controller, 1 node compute*

- Controller - IP Management: 192.168.10.91
- Compute - IP Management: 191.2681.10.28


## Cài đặt và cấu hình 

*Vì port 8778 trùng với port của service Placement nên có thể sử dụng port khác, bài viết này tôi đang chỉ thử nghiệm mặc định*

*Thực hiện trên node controller*

- Bước 1:  Khởi tạo cơ sở dữ liệu cho Senlin
```sh
CREATE DATABASE senlin DEFAULT CHARACTER SET utf8;
GRANT ALL ON senlin.* TO 'senlin'@'192.168.10.31' \
  IDENTIFIED BY 'Welcome123';
GRANT ALL ON senlin.* TO 'senlin'@'%' \
  IDENTIFIED BY 'Welcome123';
```

- Bước 2: Khởi tạo service, user
```sh
openstack service create --name senlin --description "Senlin Clustering Service V1" clustering

openstack user create --project service senlin --password Welcome123

#Gán quyền cho user senlin
openstack role add --project service --user senlin admin
```

- Bước 3: Khởi tạo endpoint 
```sh
openstack endpoint create senlin --region Hanoi \
  public http://192.168.10.91:8778
  
openstack endpoint create senlin --region Hanoi \
  internal http://192.168.10.91:8778

openstack endpoint create senlin --region Hanoi \
  admin http://192.168.10.91:8778
```

- Bước 4: Tải và cài đặt các gói 
```sh
  yum install -y openstack-senlin-engine openstack-senlin-api openstack-senlin-common openstack-senlin-conductor openstack-senlin-health-manager python3-senlinclient
```

- Bước 5: Cấu hình Senlin trong file `/etc/senlin/senlin.conf`
```ini
[default]
debug = true
transport_url = rabbit://openstack:Welcome123@192.168.10.91:5672//openstack
[database]
connection = mysql+pymysql://senlin:Welcome123@192.168.10.91/senlin?charset=utf8

[keystone_authtoken]
service_token_roles_required = True
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = senlin
password = Welcome123
www_authenticate_uri = http://192.168.10.91:5000
auth_url = http://192.168.10.91:5000
memcached_servers = 192.168.10.91:11211

[senlin_api]
bind_host = 192.168.10.91
bind_port = 8778

[authentication]
auth_url = http://192.168.10.91:5000
service_username = senlin
service_password = Welcome123
service_project_name = service

[oslo_messaging_rabbit]
rabbit_userid = openstack
rabbit_hosts = 192.168.10.91
rabbit_password = Welcome123

[oslo_messaging_notifications]
driver = messaging
topics = stacklight_notifications
```

- Bước 6: Cấu hình giao tiếp api trong file `/etc/senlin/api-paste.ini`
```ini
# senlin-api pipeline
[pipeline:senlin-api]
pipeline = cors http_proxy_to_wsgi request_id faultwrap ssl versionnegotiation osprofiler webhook authtoken context trust apiv1app

[app:apiv1app]
paste.app_factory = senlin.api.common.wsgi:app_factory
senlin.app_factory = senlin.api.openstack.v1.router:API

# Middleware to set x-openstack-request-id in http response header
[filter:request_id]
paste.filter_factory = oslo_middleware.request_id:RequestId.factory

[filter:faultwrap]
paste.filter_factory = senlin.api.common.wsgi:filter_factory
senlin.filter_factory = senlin.api.middleware:fault_filter

[filter:context]
paste.filter_factory = senlin.api.common.wsgi:filter_factory
senlin.filter_factory = senlin.api.middleware:context_filter
oslo_config_project = senlin

[filter:ssl]
paste.filter_factory = oslo_middleware.ssl:SSLMiddleware.factory

[filter:versionnegotiation]
paste.filter_factory = senlin.api.common.wsgi:filter_factory
senlin.filter_factory = senlin.api.middleware:version_filter

[filter:trust]
paste.filter_factory = senlin.api.common.wsgi:filter_factory
senlin.filter_factory = senlin.api.middleware:trust_filter

[filter:webhook]
paste.filter_factory = senlin.api.common.wsgi:filter_factory
senlin.filter_factory = senlin.api.middleware:webhook_filter

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware.http_proxy_to_wsgi:HTTPProxyToWSGI.factory
oslo_config_project = senlin

# Auth middleware that validates token against keystone
[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory

[filter:cors]
paste.filter_factory =  oslo_middleware.cors:filter_factory
oslo_config_project = senlin
```


- Bước 7: Phân quyển cho các file
```sh
chown :senlin -R /etc/senlin
chmod 640 -R /etc/senlin
```

- Bước 8: Khởi tạo tables trong DB
```sh
senlin-manage db_sync
```

- Bước 9: Restart các service
```sh
systemctl restart openstack-senlin-api openstack-senlin-engine openstack-senlin-conductor openstack-senlin-health-manager
```

### Kiểm tra sau cài đặt
```sh
openstack cluster service list

openstack cluster build info
```

