# Giới thiệu về Trove

Trove là project trong Openstack cung cấp tính năng Database as a Service (DBaaS). Trove quản lý việc khởi tạo máy ảo sử dụng image đã được cấu hình sẵn để trở thành database server và cung cấp interface để quản lý các database. Trove giao tiếp với máy ảo thông qua RabbitMQ bằng cách sử dụng command và được tiếp nhận bởi Trove guestagent chạy trên máy ảo.

Trove cung cấp các tính năng như:
- Backup Database
- Replicate Database
- Quản lý truy cập của User vào Database

