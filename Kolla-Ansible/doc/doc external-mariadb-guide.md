# External MariaDB

## Yêu cầu

- Có sẵn cụm server MariaDB cluster và tất cả các node đều kết nối đến được
- Nếu khai báo `use_preconfigured_databases: "yes"` thì database và user của tất cả các service phải đã được tồn tại trọng DB (Sử dụng Trong trường hợp update phiên bản).
- Nếu khai báo `use_preconfigured_databases: "no"` thì phải khai báo password user root để Kolla-Ansible khởi tạo databases, user.

## Kích hoạt External MariaDB 

- Khi đã có sẵn external mariadb support, bạn cần disable việc deployment mariadb của Kolla-Ansible trong file `/etc/kolla/globals.yml`:
```yml
enable_mariadb: "no"
```

- Có 2 cách để sử dụng external MariaDB
	- Sử dụng địa chỉ load-balanced MariaDB có sẵn.
	
	- Sử dụng cụm external MariaDB cluster có sẵn.
	
### Sử dụng địa chỉ LB MariaDB có sẵn

- Nếu external database của bạn đang có LB, bạn sẽ cần làm theo chỉ dẫn dưới đây:

	1. Cấu hình file inventory, đổi khai báo host `control`  ở group `[mariadb]` thành địa chỉ Load-balancer như dưới:
	```ini
	[mariadb]
	myexternalmariadbloadbalancer.com
	```
	2. Khai báo `database_address` trong file `/etc/kolla/globals.yml`
	```yml
	database_address: myexternalmariadbloadbalancer.com
	```
- Lưu ý: nếu `enable_external_mariadb_load_balancer: no`(mặc định) , thì external DB load-balancer phải đã được kết nối vs tất cả các node trong quá trình deployment

### Sử dụng external MariaDB cluster
- Nếu bạn sử dụng theo cách này thì phải khai báo tất cả các node trong cluster trong file inventory(node khai báo đầu tiên là node khởi tạo):
```ini
[mariadb:children]
myexternaldbserver1.com
myexternaldbserver2.com
myexternaldbserver3.com
```
- Nếu bạn muốn sử dụng Haproxy làm LB cho các node trong cluster thì các node trong group `[mariadb]` phải được kết nối tới tất cả các node trong group `[haproxy:children]` (được định nghĩa mặc định ở group `[network]`).
- Khai báo trong file `/etc/kolla/globals.yml` :
```yml
enable_external_mariadb_load_balancer: yes
```
## Sử dụng External MariaDB với user đặc quyền

- Trong trường hợp MariaDB user chính là root thì chỉ cần khai báo password trong `/etc/kolla/globals.yml`:
```yml
databas_password: myrootDBpassword
```

- Nếu user của bạn không phải root thì khai báo trong file `/etc/kolla/globals`:
```yml
database_username: "myDBuser"
```

## Sử dụng Các cấu hình databases có sẵn
- Bước đầu tiên là khai báo trong `/etc/kolla/globals.yml`:
```yml
use_preconfigured_databases: "yes"
```
- Note: Khi khai báo `use_preconfigured_databases: "yes"` , bạn cần chắc chắn giá trị của mysql `log_bin_trust_function_creators` được set là `1` bởi quản trị viên database trước khi chạy lệnh upgrade

## Sử dụng External MariaDB với các cấu hình , user có sẵn khác với khai báo mặc định của Kolla-Ansible

- Trong trường hợp này bạn sẽ cần khai báo `username` của các service muốn tạo trong DB trong file `/etc/kolla/globals.yml`
```yml
#example

keystone_database_user: preconfigureuser1
nova_database_user: preconfigureduser2
```
- Cùng với đó là set passwords của các databases đó với passwords có sẵn trong file `/etc/kolla/passwords.yml`

## Sử dụng 1 user cho tất cả DB
- Khai báo trong file `/etc/kolla/globals.yml` :
```yml
use_common_mariadb_user: "yes"
database_user: mycommondatabaseuser
```
- Khai báo tất các các databases password về cùng 1 password trong file `/etc/kolla/passwords.yml`
```sh
sed -i -r -e 's/([a-z_]{0,}database_password:+)(.*)$/\1 mycommonpass/gi' /etc/kolla/passwords.yml
```






