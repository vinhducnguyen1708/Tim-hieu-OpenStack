# Heat Orchestration Template (HOT)

## 1. Khái niệm 

HOT là định dạng template mới được sinh ra nhằm mục đích thay thế cho định dạng HeatCloudFormation-compatible (CFN, định dạng này được viết dưới dạng JSON) là định dạng gốc được Heat support suốt thời gian vừa qua. Hiện nay HOT đang trong quá trình vượt qua các chức năng của định dạng cũ CFN.

HOT template được viết ở định dạng YAML

## 2. Cấu trúc

```yml
heat_template_version: 2016-10-14

description:
  # a description of the template

parameter_groups:
  # a declaration of input parameter groups and order

parameters:
  # declaration of input parameters

resources:
  # declaration of template resources

outputs:
  # declaration of output parameters

conditions:
  # declaration of conditions
```

- **heat_template_version**: Có giá trị là phiên bản của HOT sẽ được sử dụng, phải có giá trị `2013-05-23` hoặc cao hơn.

- **description**: Key tùy chọn này khai báo miêu tả cho template hoặc workload sẽ được triển khai khi sử dụng template.

- **parameter_groups**: tại đây cho phép xác định các input parameters được gom lại thành nhóm, và thứ tự cung cấp các parameters. Phần này là tùy chọn.

- **parameters**: tại đây cho phép chỉ thị các input parameter phải được cung cấp khi khởi tạo. Phần này là tùy chọn. Sẽ bỏ qua khi không yêu cầu đầu vào.

- **resources**: Phần này chứa khai báo về tài nguyên của template. Tại đây cần phải có ít nhất 1 tài nguyên được định nghĩa trong HOT template, hoặc template sẽ không thực hiện bất cứ điều gì khi được khởi tạo.

- **outputs**: Phần này cho phép chỉ định các output parameters cho người dùng khi template được khởi tạo. Đây là tùy chọn.

- **conditions**: Tại đây bao gồm các statement có thể được sử dụng để ngăn ngừa việc tạo tài nguyên hoặc định nghĩa một đặc tính. Chúng có thể được liên kết với các tài nguyên và properties tài nguyên trong `resources`, cũng có thể được kết hợp với các `outputs` của template. Hỗ trợ này được thêm vào từ phiên bản Newton.


### 2.1 heat_template_version

- Mỗi phiên bản ở đây sẽ được hỗ trợ các tính năng nhất định
[HOT-template-version](https://docs.openstack.org/heat/latest/template_guide/hot_spec.html#heat-template-version)

### 2.2 description

Đây là nơi mô tả về template:
```yaml
description: >
      One server and one network
```

### 2.3 parameters_group

- Được định nghĩa dạng list với mỗi group là một danh sách chứa các parametes
- Các groups này được sử dụng để biểu thị thứ tự mong muốn của các parameters.
- Mỗi parameters chỉ được liên kết với 1 group được chỉ định để rằng buộc nó vào 1 parameters trong section parameters.

```yaml
parameter_groups:
- label: <human-readable label of parameter group>
  description: <description of the parameter group>
  parameters:
  - <param name>
  - <param name>
```

- **label**: là nhãn mà người dùng có thể đọc được để liên kết đến group của các parameters

- **description**: mô tả parameters groups

- **parameters**: danh sách của các parameters được gán cho parameters group này.

- **para name**: Tên của parameter được định nghĩa trong liên kết với phần parameters


### 2.4 parameters

- Parameters thường được sử dụng để tùy chọn mỗi lần triển khai (vd: username và password) hoặc ràng buộc với các thông tin cụ thể về environment như các images.
- Mỗi parameters được chỉ định trong 1 khối lồng nhau riêng biệt với tên của các parameters được định nghĩa trong dòng đầu tiên và các thuộc tính bổ sung như kiểu hoặc giá trị mặc định được định nghĩa là phần tử lồng nhau.
```yaml
parameters:
  <param name>:
    type: <string | number | json | comma_delimited_list | boolean>
    label: <human-readable name of the parameter>
    description: <description of the parameter>
    default: <default value for parameter>
    hidden: <true | false>
    constraints:
      <parameter constraints>
    immutable: <true | false>
    tags: <list of parameter categories>
```

- **param name**: tên của parameter.

- **type**: kiểu dữ liệu của parameter. hỗ trỡ cả kiểu: `string`, `number`, `comma_delimited`, `json`, `boolean`. phải điền thuộc tính này.

- **label**: là nhãn mà người dùng có thể đọc được để khai báo tên parameter.

- **default**: Giá trị default cho parameters. Giá trị này có thể được sử dụng khi user không chỉ định thay đổi giá trị parameter. Thuộc tính này không bắt buộc.

- **hidden**: giá trị boolean, nếu `true` thì sau khi chạy xong stack, các user không thể nhìn được parameter được truyền vào khi xem thông tin. Mặc định là `false`.

- **constraints**: Đây là danh sách ràng buộc được dùng. Khi khai báo param thì nó sẽ check xem giá trị của param có trong hệ thống không. Đây là thuộc tính tùy chọn.

### 2.5 resources
- Xác định resource của mỗi thành phần trong OPS làm nên 1 stack được deploy từ HOT template (vd: instance, network, storage volumes).
- Mỗi resource được định nghĩa trong 1 khối riêng biệt ở trong `resources`.

resources:
  <resource ID>:
    type: <resource type>
    properties:
      <property name>: <property value>
    metadata:
      <resource specific metadata>
    depends_on: <resource ID or list of ID>
    update_policy: <update policy>
    deletion_policy: <deletion policy>
    external_id: <external resource ID>
    condition: <condition name or expression or boolean>

- **resource ID**: ID của Resource phải là giá trị duy nhất trong section resource của template.
- **type**: Loại Resource, ví dụ như: OS::Nova::Server or OS::Neutron::Port. Attribute này bắt buộc phải có trong Resource và tùy theo Resouce mà cần chỉ ra loại. VD như Resouce là VM thì cần định nghĩa loại là OS::Nova::Server
- **properties**: danh sách các thuộc tính cung cấp bởi resource.

Ví dụ:
```yaml
resources:
  my_instance:
    type: OS::Nova::Server
    properties:
      flavor: m1.small
      image: F18-x86_64-cfntools
```

### 2.5 ouputs
- outputs định nghĩa ra các parameters trả về cho người dùng sau khi stack được tạo ra , ví dụ như địa chỉ IP của instance, địa chỉ URL của ứng dụng web được triển khai trong stack.
- Mỗi output parameters được định nghĩa trong 1 khối riêng biệt trong phần output theo cú pháp:
```yaml
outputs:
  <parameter name>:
    description: <description>
    value: <parameter value>
    condition: <condition name or expression or boolean>
```

ví dụ: 
```yaml
outputs:
  instance_ip:
    description: IP address of the deployed compute instance
    value: { get_attr: [my_instance, first_address] }
```

