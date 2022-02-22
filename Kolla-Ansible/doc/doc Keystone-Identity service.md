# Keystone-Identity service

## Tokens

- Định dạng token được khai báo tại `keystone_token_provider` và mặc định giá trị là `fernet`.

## Fernet Tokens

- Fernet token yêu cầu sử dụng keys đồng thời tại các Keystone servers. Kolla-Ansible deploy 2 containers để giải quyết vấn để này
	- `keystone_fernet`: chạy cron job để thực hiện việc rotate keys thông qua rsync khi cần thiết.
	- `keystone_ssh`: Đóng vai trò là SSH server .....
	
- Các khai báo cấu hình token expiry và key rotation.
	- `fernet_token_expiry`: khai báo đơn vị giây. Mặc định là 86400 (1 ngày)
	- `fernet_token_allow_expired_window`: 
	- `fernet_key_rotation_interval`: Khai báo thời gian thực hiện rotate key. Mặc định 3 ngày
	
