# Neutron - Networking Service
## Preparation and deployment

- Neutron đã được cấu hình mặc định sẵn trong file /etc/kolla/globals.yml	
```
#enable_neutron: "{{ enable_openstack_core | bool }}"
```

- `neutron_external_interface` dùng để giao tiếp với mạng bên ngoài( sử dụng floating Ips) để cấu hình ta cần dùng riêng một dải mạng provider để cấp cho interface này
```
neutron_external_interface: "eth1"
```

- Để chắc chắn việc các VM ở host compute sử dụng được dải mạng `neutron_external_interface` làm floating IPs thì ta cần cấu hình `enable_neutron_provider_networks`
```
enable_neutron_provider_networks: yes
```
- Mặc định thì kolla-ansible sử dụng openvswitch , có thể đổi plugin khác:
```
neutron_plugin_agent: "openvswitch"
```
