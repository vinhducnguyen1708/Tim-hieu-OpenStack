# Unify CPU Model on Compute

*Đặt vấn đề:*
Host compute có nhiều loại CPU khác nhau, Bios Version khác nhau thì k thể live-migrate các VMs.

## Specify the CPU model of KVM guests
Theo cấu hình mặc định của Openstack, thì Openstack sẽ mapping thẳng model cpu và các flags của host compute lên các VMs.

Khi cài đặt libvirt, ta có thể xem được model CPU đang sử dụng và các flags trong đó bằng cách 
```sh
lscpu
cat /usr/share/libvirt/cpu_map/<cpu_model>.xml
```
Cấu hình trong `[libvirt]` sẽ chỉ định dòng CPU nào sẽ được sử dụng trong VMs `cpu_mode`, `cpu_models`

Các mode cấu hình CPU có thể lựa chọn: `host-passthrough`, `host-model`(default), `custom`

### **Host-passthrough**

Là công nghệ cho phép Hypervisor (KVM) chuyển thẳng CPU đến một máy ảo nào đó, tức là máy ảo (Guest OS) có thể sử dụng trực tiếp phần cứng của CPU thông qua Hypervisor mà không cần thông qua HostOS

Nhưng khi sử dụng Passthrough yêu cầu hạ tầng các host compute cần có sự đồng nhất về các dòng CPU và các flags trong đó. Và cũng vì lý do này việc sử dụng Passthrough sẽ gặp vấn đề trong việc Live-migration.

### **Host-model**

Nếu bạn không cấu hình `cpu_mode` trong `nova.conf` thì Openstack sẽ chỉ định mode mặc định là `host-model`. Đây là công nghệ sẽ tối ưu hóa việc sử dụng các CPU features của các host lên trên các máy ảo ( sẽ đưa toàn bộ các flags của host cung cấp cho máy ảo ).

Nhưng việc sử dụng host-model sẽ cần lưu ý vì có thể sẽ đưa một vài flags nguy hiểm lên VM dẫn đến tồn tại các lỗ hổng Meltdown and Spectre.

Và khi sử dụng host-model trong quá trình live-migration, như vậy sẽ xảy ra vấn đề ở các VMs có nhiều flags khi live-migrate sang host compute có cpu cung cấp ít flags hơn. Sẽ gây ra việc không tương thích. Nhưng vẫn có thể live-migrate từ host ít flags sang host có nhiều flags hơn.

Cũng không thể live-migration giữa các VMs có dòng mới hơn về host có dòng CPU cũ hơn.


### **Custom**

Với mode này bạn có thể rõ ràng chỉ định model CPU host ấy đang sử dụng bằng cách khai báo ở `cpu_models`


Người dùng có thể chỉ định rõ features của CPU. Khi đó, libvirt driver sẽ chọn model CPU trong list `cpu_models` có thể cung cấp features đó. Nếu features đó không tồn tại, VM sẽ được tạo mặc định với model CPU đầu tiên trong list.  

```ini
[libvirt]
cpu_mode = custom
cpu_models = Penryn,IvyBridge,Haswell,Broadwell,Skylake-Client
```

Cách truyền metadata vào flavor để tạo máy ảo có features yêu cầu:

```sh
openstack flavor set FLAVOR_ID --property trait:HW_CPU_X86_AVX=required \
                                 --property trait:HW_CPU_X86_AVX2=required
```

## How Do I Know?
Vậy làm thế nào để kiểm tra nên sử dụng mode nào hoặc ở dây cụ thể hơn là khi sử dụng mode `custom` ta nên chọn model nào để các VMs sẽ sử dụng dòng CPU tương thích với các host compute

Ở đây tôi có 2 server có 2 model khác nhau: `Cascadelake-Server-noTSX` và `Cascadelake-Server`

Khi cài Openstack, sử dụng mode `host-model` trên 2 host compute này. tôi chỉ có thể live-migrate từ host có dòng CPU `Cascadelake-Server-noTSX` sang host có dòng CPU `Cascadelake-Server` và sau đó không thể live-migrate ngược lại.

Vậy nên tôi quyết định chọn mode `custom` và chỉ định model cho từng host compute. Nhưng hiện tại tôi chưa muốn phân zone cho nova (gom các host compute có cùng dòng CPU thành một zone). Nên tôi cần chọn ra một model có thể tương thích nhất.

Để biết được model nào có thể tương thích với model còn lại. Dùng lệnh để check ở mỗi host compute:
```sh
virsh domcapabilities
```

Đối với server CPU `Cascadelake-Server-noTSX`:

```xml
  <cpu>
    <mode name='host-passthrough' supported='yes'>
      <enum name='hostPassthroughMigratable'>
        <value>on</value>
        <value>off</value>
      </enum>
    </mode>
    <mode name='host-model' supported='yes'>
      <model fallback='forbid'>Cascadelake-Server</model>
      <vendor>Intel</vendor>
      <feature policy='require' name='ss'/>
      <feature policy='require' name='vmx'/>
      <feature policy='require' name='hypervisor'/>
      <feature policy='require' name='tsc_adjust'/>
      <feature policy='require' name='umip'/>
      <feature policy='require' name='pku'/>
      <feature policy='require' name='md-clear'/>
      <feature policy='require' name='stibp'/>
      <feature policy='require' name='arch-capabilities'/>
      <feature policy='require' name='xsaves'/>
      <feature policy='require' name='invtsc'/>
      <feature policy='require' name='ibpb'/>
      <feature policy='require' name='amd-stibp'/>
      <feature policy='require' name='amd-ssbd'/>
      <feature policy='require' name='rdctl-no'/>
      <feature policy='require' name='ibrs-all'/>
      <feature policy='require' name='skip-l1dfl-vmentry'/>
      <feature policy='require' name='mds-no'/>
      <feature policy='require' name='pschange-mc-no'/>
      <feature policy='disable' name='hle'/>
      <feature policy='disable' name='rtm'/>
    </mode>
    <mode name='custom' supported='yes'>
      <model usable='yes'>qemu64</model>
      <model usable='yes'>qemu32</model>
      <model usable='no'>phenom</model>
      <model usable='yes'>pentium3</model>
      <model usable='yes'>pentium2</model>
      <model usable='yes'>pentium</model>
      <model usable='yes'>n270</model>
      <model usable='yes'>kvm64</model>
      <model usable='yes'>kvm32</model>
      <model usable='yes'>coreduo</model>
      <model usable='yes'>core2duo</model>
      <model usable='no'>athlon</model>
      <model usable='yes'>Westmere-IBRS</model>
      <model usable='yes'>Westmere</model>
      <model usable='yes'>Skylake-Server-noTSX-IBRS</model>
      <model usable='no'>Skylake-Server-IBRS</model>
      <model usable='no'>Skylake-Server</model>
      <model usable='yes'>Skylake-Client-noTSX-IBRS</model>
      <model usable='no'>Skylake-Client-IBRS</model>
      <model usable='no'>Skylake-Client</model>
      <model usable='yes'>SandyBridge-IBRS</model>
      <model usable='yes'>SandyBridge</model>
      <model usable='yes'>Penryn</model>
      <model usable='no'>Opteron_G5</model>
      <model usable='no'>Opteron_G4</model>
      <model usable='no'>Opteron_G3</model>
      <model usable='yes'>Opteron_G2</model>
      <model usable='yes'>Opteron_G1</model>
      <model usable='yes'>Nehalem-IBRS</model>
      <model usable='yes'>Nehalem</model>
      <model usable='yes'>IvyBridge-IBRS</model>
      <model usable='yes'>IvyBridge</model>
      <model usable='no'>Icelake-Server-noTSX</model>
      <model usable='no'>Icelake-Server</model>
      <model usable='no'>Icelake-Client-noTSX</model>
      <model usable='no'>Icelake-Client</model>
      <model usable='yes'>Haswell-noTSX-IBRS</model>
      <model usable='yes'>Haswell-noTSX</model>
      <model usable='no'>Haswell-IBRS</model>
      <model usable='no'>Haswell</model>
      <model usable='no'>EPYC-Rome</model>
      <model usable='no'>EPYC-IBPB</model>
      <model usable='no'>EPYC</model>
      <model usable='no'>Dhyana</model>
      <model usable='no'>Cooperlake</model>
      <model usable='yes'>Conroe</model>
      <model usable='yes'>Cascadelake-Server-noTSX</model>
      <model usable='no'>Cascadelake-Server</model>   ### Không thể sử dụng dòng CPU Cascadelake-Server trên host này ###
      <model usable='yes'>Broadwell-noTSX-IBRS</model>
      <model usable='yes'>Broadwell-noTSX</model>
      <model usable='no'>Broadwell-IBRS</model>
      <model usable='no'>Broadwell</model>
      <model usable='yes'>486</model>
    </mode>
  </cpu>
```

Đối với server có CPU `Cascadelake-Server`:

```xml
  <cpu>
    <mode name='host-passthrough' supported='yes'>
      <enum name='hostPassthroughMigratable'>
        <value>on</value>
        <value>off</value>
      </enum>
    </mode>
    <mode name='host-model' supported='yes'>
      <model fallback='forbid'>Cascadelake-Server</model>
      <vendor>Intel</vendor>
      <feature policy='require' name='ss'/>
      <feature policy='require' name='vmx'/>
      <feature policy='require' name='hypervisor'/>
      <feature policy='require' name='tsc_adjust'/>
      <feature policy='require' name='umip'/>
      <feature policy='require' name='pku'/>
      <feature policy='require' name='md-clear'/>
      <feature policy='require' name='stibp'/>
      <feature policy='require' name='arch-capabilities'/>
      <feature policy='require' name='xsaves'/>
      <feature policy='require' name='invtsc'/>
      <feature policy='require' name='ibpb'/>
      <feature policy='require' name='amd-stibp'/>
      <feature policy='require' name='amd-ssbd'/>
      <feature policy='require' name='rdctl-no'/>
      <feature policy='require' name='ibrs-all'/>
      <feature policy='require' name='skip-l1dfl-vmentry'/>
      <feature policy='require' name='mds-no'/>
      <feature policy='require' name='pschange-mc-no'/>
      <feature policy='require' name='tsx-ctrl'/>
    </mode>
    <mode name='custom' supported='yes'>
      <model usable='yes'>qemu64</model>
      <model usable='yes'>qemu32</model>
      <model usable='no'>phenom</model>
      <model usable='yes'>pentium3</model>
      <model usable='yes'>pentium2</model>
      <model usable='yes'>pentium</model>
      <model usable='yes'>n270</model>
      <model usable='yes'>kvm64</model>
      <model usable='yes'>kvm32</model>
      <model usable='yes'>coreduo</model>
      <model usable='yes'>core2duo</model>
      <model usable='no'>athlon</model>
      <model usable='yes'>Westmere-IBRS</model>
      <model usable='yes'>Westmere</model>
      <model usable='yes'>Skylake-Server-noTSX-IBRS</model>
      <model usable='yes'>Skylake-Server-IBRS</model>
      <model usable='yes'>Skylake-Server</model>
      <model usable='yes'>Skylake-Client-noTSX-IBRS</model>
      <model usable='yes'>Skylake-Client-IBRS</model>
      <model usable='yes'>Skylake-Client</model>
      <model usable='yes'>SandyBridge-IBRS</model>
      <model usable='yes'>SandyBridge</model>
      <model usable='yes'>Penryn</model>
      <model usable='no'>Opteron_G5</model>
      <model usable='no'>Opteron_G4</model>
      <model usable='no'>Opteron_G3</model>
      <model usable='yes'>Opteron_G2</model>
      <model usable='yes'>Opteron_G1</model>
      <model usable='yes'>Nehalem-IBRS</model>
      <model usable='yes'>Nehalem</model>
      <model usable='yes'>IvyBridge-IBRS</model>
      <model usable='yes'>IvyBridge</model>
      <model usable='no'>Icelake-Server-noTSX</model>
      <model usable='no'>Icelake-Server</model>
      <model usable='no'>Icelake-Client-noTSX</model>
      <model usable='no'>Icelake-Client</model>
      <model usable='yes'>Haswell-noTSX-IBRS</model>
      <model usable='yes'>Haswell-noTSX</model>
      <model usable='yes'>Haswell-IBRS</model>
      <model usable='yes'>Haswell</model>
      <model usable='no'>EPYC-Rome</model>
      <model usable='no'>EPYC-IBPB</model>
      <model usable='no'>EPYC</model>
      <model usable='no'>Dhyana</model>
      <model usable='no'>Cooperlake</model>
      <model usable='yes'>Conroe</model>
      <model usable='yes'>Cascadelake-Server-noTSX</model> ### Có thể sử dụng dòng CPU >Cascadelake-Server-noTSX trên host này ###
      <model usable='yes'>Cascadelake-Server</model>
      <model usable='yes'>Broadwell-noTSX-IBRS</model>
      <model usable='yes'>Broadwell-noTSX</model>
      <model usable='yes'>Broadwell-IBRS</model>
      <model usable='yes'>Broadwell</model>
      <model usable='yes'>486</model>
    </mode>
  </cpu>
```

Qua thử nghiệm, nếu muốn sử dụng chung một dòng CPU trên tất cả các host compute thì nên sử dụng dòng `Cascadelake-Server-noTSX`

Ta cấu hình như sau trong `/etc/nova/nova.conf`
```ini
[libvirt]
cpu_mode = custom
cpu_models = Cascadelake-Server-noTSX
``` 

Để enable flags
```ini
[libvirt]
cpu_mode = custom
cpu_models = Cascadelake-Server-noTSX
cpu_model_extra_flags = vmx,pcid
```

---
## Tham khảo

[1] https://www.slideshare.net/vietstack/meetup-23-01-the-things-i-wish-i-would-have-known-before-doing-openstack-cloud-transformation

[2] https://docs.openstack.org/nova/latest/admin/configuration/hypervisor-kvm.html

[3] https://www.openstack.org/videos/summits/berlin-2018/effective-virtual-cpu-configuration-in-nova

[4] https://vietstack.wordpress.com/2015/06/01/486/

[5] https://bugzilla.redhat.com/show_bug.cgi?id=1761678
