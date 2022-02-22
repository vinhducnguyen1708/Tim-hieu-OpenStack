# Production architecture guide

*Hướng dẫn này sẽ giúp bạn cấu hình Kolla-ansible phù hợp môi trường production. Ở đây sẽ trả lời một vài câu hỏi về các vấn đề cơ bản mà Kolla yêu cầu.*

## Node types and services running on them
*( Các dạng khai báo node và các services chạy trên node)*
- file inventory của Kolla gồm có các dạng node đơn giản
	- `Control`: là Cloud controller node quản lý các services như APIs và databases.Các Node này nên có số lượng lẻ
	- `Network`: Network node là nơi quản lý Neutron agents cùng với haproxy/keepalived. Node này sẽ có floating ip được khai báo ở `kolla_internal_vip_address`.
	- `Compute`: Compute nodes thực hiện chứa các compute services. Đây là nơi các Vm tồn tại
	- `Storage`: Storage nodes , dùng cho cinder-volume, LVM hoặc ceph-osd.
	- `Monitoring`: Monitor nodes là Node giám sát các services

## Network configuration
### Interface configuration


- `network_interface`: Khi các interface khác không được định nghĩa, thì khi khai báo interface ở đây sẽ mặc định là interface cho các khai báo ở dưới
- `api_interfaces`:	Interface này được sự dụng làm management network. Interface được các service Openstack dùng để giao tiếp với nhau qua API và giao tiếp với các databases. Để đảm bảo sự bảo mật hãy ddeeer network này là internal để không bị truy nhập từ bên ngoài
- `kolla_external_vip_interface`: Đây là interface dùng làm public. Nó được sử dụng khi bạn muốn HAproxy public các endpoints tiếp xúc với các mạng nội bộ khác. Sẽ bắt buộc phải khai báo `kolla_external_vip_interface` nếu option `kolla_enable_tls_external= yes` (mặc định là `network_interface`)
- `storage_interface`: đây là interface được sử dụng bởi các VMs để kết nối tới Ceph. Việc kết nối này có thể mất nhiều băng thông nên khuyên cáo sử dụng high speed network fabric
- `cluster_interface`: Đây là interface khác được sử dụng bới Ceph. Được sử dụng để tái tạo phục hồi data. Interface này có thể bị quá tải và sẽ trở thành  "bottleneck" và ảnh hưởng đến toàn bộ cụm cluster
- `tunnel_interface`: Đây là interface được Neutron sử dụng để kết nối vm-to-vm qua đường tunnel networks(VXLAN, GRE).
- `neutron_external_interface`: Interface này đươc yêu cầu bởi Neutron. Neutron sẽ đặt brigde `br-ex` lên interface này . Và sẽ được sử dụng cho Flat network cũng như Vlan network
- `dns_interface`: Interface này yêu cầu bởi Designate và Bind9.
- `swift_storage_interface`: được sử dụng bởi Swift cho storage truy cập traffic.

