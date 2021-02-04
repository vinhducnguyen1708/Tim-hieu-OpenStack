
# Multiqueue

*Môi trường Openstack Ussuri*

## Vì sao nên sử dụng Multiqueue

- Khi nhiều đơn vị yêu cầu tài nguyên máy ảo trên Openstack lớn, nhưng ứng dụng chạy trên các máy ảo vẫn không đạt được hiệu năng tốt.

- Do không sử dụng multiqueue cho VMs, vì VMs được tạo ra trên Openstack mặc định chỉ sử dụng 1 Queue(Tức là có nhiều vCPU nhưng việc xử lý đẩy các packets lại chỉ đẩy đúng vào 1 queue dưới NIC)

- Vậy nên muốn tăng tốc độ xử lý Queue trên network thì ta cần phân làn dồn đều queue vào vCPU (có bao nhiêu core thì bây nhiêu Queue)

- Có thể việc sử dụng multiqueue có thể ảnh hưởng đến latency của ứng dụng chạy trên VMs nên cần test performance

## Để bật tính năng này có 2 cách:

- Set trong flavor:

```sh
openstack flavor set <id_flavor> --property vif_multiqueue_enabled='true'
```

- Set trong image:

```sh
openstack image set --property hw_vif_multiqueue_enabled='true'  <id_image>
```


## Kiểm tra VMs

- VM khi chưa phân luồng Queue:

![ima](../images/multiqueue1.png)

- VM khi đã phân luồng Queue:

![ima](../images/multiqueue2.png)

## Kiểm tra hiệu năng


