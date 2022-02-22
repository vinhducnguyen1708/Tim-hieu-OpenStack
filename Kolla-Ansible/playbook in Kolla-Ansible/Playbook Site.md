# Playbook site.yml

#### `Serial`
- Khái niệm:
    - Module này sẽ giúp bạn thực hiện chạy playbook đồng thời trên nhiều node, để ví dụ nếu update các phiên bản sẽ tránh việc các node mất đồng bộ dẫn đến fail service
- Khi Kolla-Ansible sử dụng: 
```
serial: '{{ kolla_serial|default("0") }}'
```
- Chức năng khi sử dụng module này trong kolla-Ansible:
    - Ở đây Kolla-A tự tạo ra một biến là `kolla_serial` nhằm thực hiện tùy chỉnh thông số của module `serial` nếu không muốn mặc định là `0`. Ví dụ:
```
kolla-ansible bootstrap-servers -i INVENTORY -e kolla_serial=3
```
#### `Group_by`

- Khái niệm:
    -  Nhằm thực hiện đọc ghi thư mục inventory (trong kolla-ansible là `globals.yml` và `/group_vars/all.yml`) Ansible sinh ra 2 module `add_host` và `group_by`.
- Khi Kolla-Ansible sử dụng: 
```
    - name: Group hosts based on enabled services
      group_by:
        key: "{{ item }}"
      with_items:
        - enable_aodh_{{ enable_aodh | bool }}
        - enable_barbican_{{ enable_barbican | bool }}
       ...
```
- Chức năng khi sử dụng module này trong kolla-Ansible:
    
    - Ở đây, tasks này được gọi ở đầu playbook `site.yml` nhằm mục đích đọc và ghi lại các service nào đã được ta khai báo trong file `/group_vars/all.yml`
    - `bool` ở đây là bộ lọc để xác định biến ta khai báo có phải là `1`,`yes`,`true` không . Nếu đúng thì service ta chỉ định enable sẽ được cài.
    - Ví dụ ta khai báo trong  `/group_vars/all.yml` :
    ```
    ...
    enable_fluentd: "yes"
    enable_grafana: "no"
    ...
    ```
#### `set_fact`
- Khái niệm:
    - Module bản chất là một module cho phép đặt thêm các giá trị 

