# Phân chia tài nguyên vGPU bằng cách sử dụng trait cho resource provider


- **Bước 1:** Lệnh kiểm tra resource provier
```sh
openstack resource provider list
```
- **Bước 2:** Lệnh kiểm tra thông tin allocation
```sh
openstack allocation candidate list --resource VGPU=1
```

- **Bước 3:** Thiết lập tạo trait
```sh
openstack --os-placement-api-version 1.6 trait create CUSTOM_NVIDIA_232
```
- **Bước 4:** gắn trait vào resource provider
```sh
openstack --os-placement-api-version 1.6 resource provider trait set --trait CUSTOM_NVIDIA_232 <resource provider>
```
*Gỡ trait khỏi resource provider:*
```sh
openstack --os-placement-api-version 1.6 resource provider trait delete <resource provider>
```
- **Bước 5:** Lệnh gắn trait cho host aggregate
```
openstack --os-compute-api-version 2.53 aggregate set --property trait:CUSTOM_NVIDIA_232=required <host_aggregate>
```

- **Bước 6:** Lệnh thiết lập properties cho flavor sử dụng trait vGPU (bắt buộc phải có resource: vGPU)
```sh
openstack flavor set vgpu_1 --property "resources:VGPU=1"
openstack flavor set --property trait:CUSTOM_NVIDIA_232=required vgpu_1
```

- **Bước 7:** Cấu hình trong nova 
```sh
#...
vim /etc/nova/nova.conf

[scheduler]
enable_isolated_aggregate_filtering = True
#...
```
- **Bước 8:** Khởi động lại nova-api và nova-scheduler
```sh
systemctl restart openstack-nova-api openstack-nova-scheduler
```

---
# Tham Khảo
- https://docs.openstack.org/nova/latest/user/flavors.html
- https://docs.openstack.org/osc-placement/latest/cli/index.html
- https://docs.openstack.org/nova/latest/reference/isolate-aggregates.html
- https://specs.openstack.org/openstack/nova-specs/specs/train/implemented/placement-req-filter-forbidden-aggregates.html