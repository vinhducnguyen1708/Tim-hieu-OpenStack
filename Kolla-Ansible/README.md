# Kolla-Ansible
*Đây là tài liệu về quá trình tìm hiểu Kolla-Ansible*
## Kolla
Kolla là một project của Openstack thực hiện build các Images trong project Openstack để sẵn sàng run các images này trên container.
## 2. Kolla-Ansible
### 2.1 Định nghĩa
- Kolla-Ansible là project thực hiện việc tự động hóa các công việc cho hệ thống cloud Openstack.
  - `bootstrap-servers`
  - `deploy`
  - `check`
  - `reconfigure`
  - `update`
  - `destroy`
  - `pull`
  - `mariadb_recovery`
  - `stop` 
- Các service được deploy bởi Kolla-Ansible mặc định được triển khai trong container.
### 2.2 Thao tác với Kolla-ansible
- Việc sử dụng deploy Openstack bằng Kolla-Ansible được thao tác bằng các lệnh chính:
  - `kolla-ansible -i <inventory-file> bootstrap-server`: Thực hiện cài đặt các gói phụ trợ(Docker, Pip, Docker SDK,..) và môi trường để sẵn sàng cài đặt các service ( Cấu hình file hosts, disabled firewall...)
  - `kolla-ansible -i <inventory-file> pull`: Thực hiện pull các Image do Kolla build từ dockerhub về các server target.
  - `kolla-ansible -i <inventory-file> prechecks`: Thực hiện check lại môi trường cài đặt ( check free port, ip-add,...)
  - `kolla-ansible -i <inventory-file> deploy`: Thực hiện cài đặt hệ thống Openstack (deploy các container, run các containers, tạo các file cấu hình,...)
  - `kolla-ansible -i <inventory-file> check`: Kiểm tra lại hệ thống sau khi cài đặt
  - `kolla-ansible -i <inventory-file> post-deploy`: Tạo ra một file biến môi trường để truy xuất vào Openstack thực thi các lệnh.
### 2.3 Khai báo thông tin và Customise hệ thống
- Việc khai báo hệ thống Openstack cần triển khai nằm ở các file trong thư mục `/etc/kolla`
  - `globals.yml`: Nơi khai báo các biến cho Kolla-Ansible khi chạy nhằm thực hiện cấu hình cho hệ thống Openstack
  - `passwords.yml`: đây là file chứa các khai báo về mật khẩu cho hệ thống Openstack được tạo ra bởi lệnh `kolla-genpwd`
  - `/config/<service>/<hostname>/keystone.cnf`: Đây các phân bố tổ chức để định dạng 1 file cấu hình được sử dụng nhằm việc muốn thêm các cấu hình do mình muốn thay vì sử dụng cấu hình mặc định khi Kolla-Ansible deploy hệ thống.
  - Một và các file khác như `certificates/ca/..` chứa các certificates tls được tạo ra bằng lệnh `kolla-ansible certificates`.
  
- Thực hiện khai báo thông tin các host đóng các vai trò khác nhau trong hệ thống Openstack bằng file inventory của Kolla-Ansible
  - [all-in-one](https://opendev.org/openstack/kolla-ansible/src/branch/master/ansible/inventory/all-in-one)
  - [multinode](https://opendev.org/openstack/kolla-ansible/src/branch/master/ansible/inventory/multinode)
  - Nơi Khai báo: Khai báo dưới các group này là ip hoặc hostname các host
    - `[control]`: Node controller thực hiện tiếp nhận API
    - `[network]`: Node thực hiện điều phối network
    - `[compute]`: Node compute 
    - `[storage]`: trỏ đến storage backend
    - `[monitoring]`: Các node thực hiện monitor
    - `[deployment]`: Node cài đặt Kolla-Ansible dùng để thực hiện điều khiển các node target
- Thực hiện Customise hệ thống bằng cách khai báo các giá trị trong file `/etc/kolla/globals.yml`:
  - Các cấu hình cơ bản bắt buộc cần khai báo cho Kolla-Ansible khi deploy một hệ thống Openstack
    - `kolla_base_distro:` : Khai báo Thực hiện cài đặt bằng hệ điều hành nào (VD: "centos")
    - `kolla_install_type:`: Khai báo định dạng cài đặt (VD: "binary")
    - `openstack_release:`: Chỉ định phiên bản Openstack muốn cài đặt (VD: "stein", "train" ,... hoặc theo tag image được build "9.0.2",..)
    - `kolla_internal_vip_address:`: Chọn 1 IP VIP cho Haproxy (  IP này không được bất kỳ host nào sử dụng trên network)
    - `network_interface:` : Chọn interface đóng vai tròn `api_interface` (mặc định) chi tiết xem [tại đây](https://github.com/vinhducnguyen1708/Internship-VNPT-IT/blob/master/Automation/Kolla-Ansible/doc/doc%20Production%20architecture%20guide.md)
    - `neutron_external_interface:` Chọn Interface làm external network để các Vm sử dụng đi ra ngoài Internet
    - `keepalived_virtual_router_id:` : Tránh việc bị Trùng VRID do sử dụng giao thức VRRP ta khai báo VRID tại đây có giá trị <0-255>
  - Một vài cách customise phức tạp hơn [tại đây](https://github.com/vinhducnguyen1708/Internship-VNPT-IT/tree/master/Automation/Kolla-Ansible/doc)
### 2.4 Cài đặt Kolla-Ansible 
- [Cài đặt Kolla-Ansible](https://github.com/vinhducnguyen1708/Internship-VNPT-IT/blob/master/Automation/Kolla-Ansible/C%C3%A0i%20%C4%91%E1%BA%B7t%20Kolla-Ansible.md)

- Lưu ý: khi cài đặt với các phiên bản Openstack khác thấp hơn bản Train, bạn cần điều chỉnh phiên bản của Ansible. Ví dụ khi cài đặt phiên bản Openstack Rocky thì phiên bản Ansible yêu cầu là 2.7


