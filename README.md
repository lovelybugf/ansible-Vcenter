# Dự Án Tự Động Hóa Khởi Tạo Máy Ảo Trên vCenter (Ansible vSphere Automation)

Dự án này cung cấp bộ sưu tập Playbooks và Roles của Ansible giúp tự động hóa toàn bộ quy trình khởi tạo máy ảo (VM), cấu hình phần cứng, đĩa cứng và gán cạc mạng ảo (DVS Portgroup) trên nền tảng VMware vSphere vCenter.

Dự án hỗ trợ chuyển đổi linh hoạt giữa 3 cơ chế thực thi thông qua biến `vm_module_type`:
1. **Certified**: Sử dụng bộ sưu tập module chính thống `vmware.vmware` (SOAP API).
2. **Community**: Sử dụng bộ sưu tập cộng đồng `community.vmware` (Idempotent).
3. **REST**: Sử dụng REST API thế hệ mới `vmware.vmware_rest` (Phù hợp cho các môi trường bị phân quyền giới hạn trên vCenter).

---

## 🚀 Hướng Dẫn Các Lệnh Chạy Chuẩn Hóa

Dưới đây là tổng hợp toàn bộ các câu lệnh thực thi tiêu chuẩn trong dự án này:

### 1. Lệnh Tạo Máy Ảo Mới

#### Chạy bằng Ansible Navigator (Khuyên dùng với Execution Environment):
```bash
# Chạy tạo máy ảo bằng module REST (Khắc phục lỗi DVS Portgroup do phân quyền)
ansible-navigator run playbooks/vmware_create_vm.yml --mode stdout --extra-vars "vm_module_type=rest"

# Chạy tạo máy ảo bằng module Certified (Mặc định)
ansible-navigator run playbooks/vmware_create_vm.yml --mode stdout --extra-vars "vm_module_type=certified"

# Chạy tạo máy ảo bằng module Community
ansible-navigator run playbooks/vmware_create_vm.yml --mode stdout --extra-vars "vm_module_type=community"
```

#### Chạy bằng Ansible Playbook truyền thống (Cần nạp credentials trước):
```bash
# Nạp thông tin kết nối vCenter
source env.sh

# Chạy playbook
ansible-playbook playbooks/vmware_create_vm.yml -e "vm_module_type=rest"
```

---

### 2. Lệnh Quản Lý Inventory Động (vCenter Dynamic Inventory)

Inventory động được cấu hình tự động lọc và chỉ nạp các máy ảo có chữ `nampd` (không phân biệt hoa thường) trong tên:

```bash
# Hiển thị danh sách máy ảo dạng cây trực quan (Kiểm tra gom nhóm)
ansible-inventory -i inventory/my_vcenter.vmware.yml --graph

# Xuất toàn bộ thông số máy ảo dạng JSON
ansible-inventory -i inventory/my_vcenter.vmware.yml --list
```

---

### 3. Lệnh Truy Vấn Thông Tin vCenter (Playbooks phụ trợ)
```bash
source env.sh

# Lấy danh sách máy ảo hiện có và trạng thái của chúng
ansible-playbook playbooks/vmware_get_info.yml

# Lấy thông tin tài nguyên (Datastore, Cluster, Resource Pool, Network)
ansible-playbook playbooks/vmware_get_resource_info.yml
```

---

### 4. Lệnh Build và Cập Nhật Execution Environment (EE)
Khi cần cập nhật thêm thư viện hoặc Ansible collections (như bộ sưu tập `cloud.common`), thực hiện quy trình sau trên máy chủ build:

```bash
# 1. Di chuyển vào thư mục cấu hình build EE
cd ee-build-vcenter

# 2. Thực hiện build image container mới (gắn tag v1.2)
ansible-builder build -t quay-ssc2.local.amigo.com/admin/nampd-vmware-ee:v1.2

# 3. Đẩy image mới lên Registry nội bộ
podman push quay-ssc2.local.amigo.com/admin/nampd-vmware-ee:v1.2
```

---

## ⚙️ Cấu Hình Các Biến Quan Trọng (`defaults/main.yml`)

Mọi thông số hạ tầng được khai báo tập trung tại [defaults/main.yml](roles/vmware_provision/defaults/main.yml):

* **Biến Tên chữ (Dùng cho Certified & Community)**:
  * `vm_cluster`: Tên Cluster (Ví dụ: `"Amigo 2"`)
  * `vm_datastore`: Tên Datastore (Ví dụ: `"vsanDatastore"`)
  * `vm_folder`: Thư mục lưu trữ (Ví dụ: `"/vm/Software-2"`)
  * `vm_network`: Tên cạc mạng (Ví dụ: `"192.168.50.0"`)
* **Biến ID/MOID (Dùng cho REST API)**:
  * `vm_cluster_id`: Mã ID của cluster (Ví dụ: `"domain-c1198154"`)
  * `vm_datastore_id`: Mã ID của datastore (Ví dụ: `"datastore-1198166"`)
  * `vm_folder_id`: Mã ID của folder (Ví dụ: `"group-v1159426"`)
  * `vm_network_id`: Mã ID của cạc mạng (Ví dụ: `"dvportgroup-1201111"`)
