# Glance - Image service
## Glance backends
### Overview
- Khi triển khai Glance được hỗ trợ bởi các backends:
	- file
	- ceph
	- vmware
	- swift

### File Backend
- Khi sử dụng `file` backend, các images sẽ được lưu tại local ở giá trị `glance_file_datadir_volume` tức là mặc định có một docker volume là `glance` chứa các images. Mặc định khi sử dụng `file` backend thì chỉ có 1 `glance_api` container chạy.

- Để tăng sự tin cậy và thực thi, `glance_file_datadir_volume` nên được mount bởi 1 shared filesystem như NFS:
```yml
glance_backend_file: "yes"
glance_file_datadir_volume: "/path/to/shared/storage/"
```
### Ceph backend
- Thực hiện enable ceph Backend
```yml
glance_backend_ceph: "yes"
```

### VMware backend
- Thực hiện enable vmware Backend
```yml
glance_backend_vmware: "yes"
```

### Swift backend
- Thực hiện enable Swift Backend
```yml
glance_backend_swift: "yes"
```

## Upgrading glance
### Overview
- Glance có thể được upgrade bằng 2 cơ chế:
	- Rolling upgrade
	- Legacy upgrade

### Rolling upgrade
- Từ khi phiên bản Rocky được phát hành, Glance có thể upgrade được bằng chế độ rolling upgrade. Chế độ này sẽ làm giảm downtime API đến mức tối thiểu của việc khởi động lại container, nhằm giảm downtime cho các phiên bản sau này.
- Mặc định thì chế độ này disabled, Nên muốn sử dụng mode này thì phải thực hiện enable trong file `/etc/kolla/globals.yml`
```yml
glance_enable_rolling_upgrade: "yes"
```
### Legacy upgrade
- Chế độ upgrade này sẽ stop APIs trong quá trình migrations database và restart container.
- Đây là chế độ mặc định. Nên muốn sử dụng thì kiểm tra xem khai báo rolling upgrade disabled:
```yml
glance_enable_rolling_upgrade: "no"
```

## Các Cấu hình khác
### Glance Cache
- Glance cache mặc định disabled, muốn enable ta thực hiện:
```yml
enable_glance_image_cache: "yes"
glance_cache_max_size: "10737418240" # 10GB by default
```



*Lưu ý: Khi sử dụng ceph làm backend, khuyến cáo không nên sử dụng glance cache, vì nova đã có cache version của image và image được copy thẳng từ ceph qua glance api nên sử dụng glance cache là không cần thiết.*


*Glance cache không được clean up tự động, cộng đồng khuyến cáo sự dụng cron service để thực hiện clean cache images định kì*