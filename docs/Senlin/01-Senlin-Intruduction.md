# Giới thiệu về Senlin

Senlin là dịch vụ Cluster của Openstack. Senlin khởi tạo và vận hành cluster dồng nhất tài nguyên của các service trong Openstack. Mục tiêu là để điều phối các đối tượng tài nguyên dễ dàng hơn.

Senlin tương tác với các service khác trong Openstack để khởi tạo cluster dựa trên các tài nguyên của các service. Việc tương tác này thông qua profile plugins.

Profile là template có thể sử dụng để giao tiếp với Senlin thực hiện Create, update, delete các profile type là các tài nguyên của các services trong Openstack.

Policy dùng để xác nhận những thao tác khi làm việc với cluster (Ví dụ xóa tài nguyên ngay sau khi bị out khỏi cụm cluster, tạo lại capacity mong muốn ban đầu,... )


## Thành phần

Từ trước bản Ussuri, Senlin chỉ có 2 thành phần là Senlin-api và Senlin-engine(nơi quản lý cluster, phân tích thực thi các profile và policy).

Từ bản Ussuri trở đi, Vì Senlin chịu trách nhiệm cho số lượng lớn các thread task. Để giảm số lượng thread chạy trên mỗi process và khiến service Engine linh hoạt hơn nên service Engine đã được tách thành 3 services. `senlin-conductor`, `senlin-engine`, `senlin-health-manager`.


