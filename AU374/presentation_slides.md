# BÁO CÁO THUYẾT TRÌNH KHÓA AU374

---

## 📌 Bố cục nội dung thuyết trình
1. Các thành phần chính của nền tảng **AAP**.
2. Chi tiết tài nguyên trong **Automation Controller** (AWX).
3. Ứng dụng **Git** quản lý mã nguồn dự án.
4. Quản lý **Ansible Collections** & **Execution Environment (EE)**.
5. Quy trình **Build Custom EE** chuẩn hóa.
6. **Thực hành tốt nhất (Best Practices)** khi phát triển dự án Ansible.
7. Giải đáp các nội dung thảo luận chưa rõ ở buổi thuyết trình trước.
8. Quản lý và Tối ưu hóa việc Thực thi Task (Chương 6).
9. Biến đổi dữ liệu với Filters và Plug-ins (Chương 7).
10. Điều phối cập nhật cuốn chiếu (Chương 8).
11. Tạo Ansible Collections và Môi trường thực thi EE (Chương 9).



---

## Ⅰ. CÁC THÀNH PHẦN CỦA ANSIBLE AUTOMATION PLATFORM (AAP)
### Hệ sinh thái giải pháp tự động hóa toàn diện
![Kiến trúc tổng quan Ansible Automation Platform (AAP)](images/AAP%20architechture.png)

Ansible Automation Platform (AAP) là một bộ công cụ hoàn chỉnh được thiết kế để chuẩn hóa, vận hành và mở rộng quy mô tự động hóa:

*   **ansible-navigator (CLI):** Công cụ dòng lệnh hiện đại giúp các kỹ sư chạy thử nghiệm playbook trực tiếp bên trong container cục bộ (Execution Environment) để đồng bộ hóa hành vi chạy giống hệt như trên máy chủ Production của AWX.
*   **ansible-builder (CLI):** Công cụ dòng lệnh giúp tự động hóa việc đóng gói hệ điều hành, thư viện Python và bộ sưu tập Collections thành một container image hoàn chỉnh.
*   **Event-Driven Ansible (EDA):** Cơ chế tự động hóa hướng sự kiện, tự động kích hoạt playbook xử lý sự cố khi nhận cảnh báo từ các hệ thống giám sát.
*   **Automation Hub:** Kho lưu trữ Collections, EE nội bộ dành riêng cho 
*   **Automation Controller:** Trung tâm điều khiển tập trung, cung cấp giao diện Web UI, REST API và hệ thống lập lịch biểu chuyên nghiệp.

---

## Ⅱ. CÁC TÀI NGUYÊN TRONG AUTOMATION CONTROLLER 
### Quản lý tài nguyên chạy tự động hóa trên giao diện Web

Để tự động hóa một kịch bản, Automation Controller quản lý 6 tài nguyên cốt lõi sau:

#### 1. Project (Dự án)
*   Liên kết trực tiếp tới kho lưu trữ Git chứa playbooks của ta.
*   Mỗi khi chạy Job, AAP cần thực hiện kéo mã nguồn mới nhất về để thực thi.

#### 2. Inventory (Kho máy chủ)
*   **Inventory Tĩnh:** Nạp từ file cấu hình trong Git chứa các host hoặc nhập tay thủ công
*   **Inventory Động (Dynamic Inventory):** Sử dụng plugin để quét tự động danh sách máy ảo trực tiếp từ vCenter API theo thời gian thực.

#### 3. Execution Environment (EE)
*   Khai báo đường dẫn tới container image chứa sẵn các thư viện Python, Collection kết nối VMware (như `vcenter-1.2-ee-nampd`) để chạy playbook.

#### 4. Credential (Thông tin xác thực)
*   Lưu trữ an toàn các thông tin nhạy cảm như tài khoản vCenter và mật khẩu.
*   **Cơ chế bảo mật:** AWX tự động truyền thông tin này dưới dạng các biến môi trường ẩn (`VMWARE_HOST`, `VMWARE_USER`, `VMWARE_PASSWORD`) vào container chạy playbook mà không để lộ mật khẩu trong code Git.

#### 5. Job Template (Mẫu chạy công việc)
*   Là bản thiết kế liên kết các tài nguyên trên lại với nhau: **Playbook** + **Inventory** + **Credential** + **EE**.
*   Hỗ trợ tính năng **Survey** tạo form nhập liệu động cho người dùng khi kích hoạt (nhập: tên máy ảo, CPU, RAM).

#### 6. Schedule (Lịch trình chạy)
*   Hệ thống lập lịch tự động chạy playbook theo chu kỳ cố định (ví dụ: Tự động backup máy ảo lúc 2h sáng hàng ngày).

---

## Ⅲ. CÁCH SỬ DỤNG GIT TRONG DỰ ÁN ANSIBLE

![Sơ đồ các trạng thái của file trong Git](images/git1.png)
![Sơ đồ các vùng làm việc của Git](images/git2.png)

Mọi thay đổi cấu hình hệ thống đều được lưu vết chi tiết qua Git => dễ :

*   **Vòng đời file trong Git:**
    *   `Modified`: File đã bị sửa nội dung so với local repo
    *   `Staged`: File được đưa vào vùng staged thông qua lệnh `git add`.
    *   `Committed`: Lưu lại vĩnh viễn vào lịch sử mã nguồn cục bộ.
*   **Tầm quan trọng của vùng Staged:**
    *   **Vùng đệm kiểm tra an toàn (Safety Net):** Hoạt động như một bước xem trước (review). Ta có thể dùng lệnh `git diff --staged` để rà soát kỹ lưỡng mọi thay đổi trước khi chính thức ghi nhận vĩnh viễn vào lịch sử mã nguồn bằng `git commit`
    *   **Nơi xử lý xung đột (Conflict Resolution):** Khi xảy ra xung đột code lúc merge hoặc rebase, Staging Area là nơi ta đánh dấu những file đã giải quyết xong xung đột trước khi hoàn tất commit.


---

## Ⅳ. ANSIBLE COLLECTIONS 
### Đóng gói nội dung tự động hóa sẵn có của cộng đồng

*   **Ansible Collections:** modules + roles + plugins: phục vụ tác vụ cho một hạ tầng cụ thể 
*   **2 nguồn tải Collection chính (khai báo cấu hình):**
    *   **Ansible Galaxy (`galaxy.ansible.com`):** Kho lưu trữ cộng đồng (Community) chứa các Collection miễn phí, mã nguồn mở do cộng đồng phát triển.
    *   **Automation Hub / Console (`console.redhat.com`):** Kho lưu trữ doanh nghiệp chứa các Collection được chứng thực (Certified) bởi Red Hat và đối tác, đảm bảo tính an toàn và hỗ trợ kỹ thuật lâu dài.
*   **Cách tải qua file yêu cầu cài đặt (`collections/requirements.yml`):**
```yaml
---
collections:
  - name: community.vmware
    version: 4.8.5
  - name: vmware.vmware
    version: 3.8.0
```
*   **Lệnh tải tự động:**
```bash
ansible-galaxy collection install -r collections/requirements.yml
```

---

## Ⅴ. GIỚI THIỆU VỀ AUTOMATION EXECUTION ENVIRONMENT (EE)
### Chuẩn hóa môi trường chạy playbook bằng Container

Execution Environment (EE) giải quyết triệt để lỗi "chạy được trên local nhưng lỗi trên máy chủ":

*   **Cấu trúc bên trong của một EE tiêu chuẩn:**
    *   **UBI Base Image:** Hệ điều hành nền Linux tối giản của Red Hat.
    *   **ansible-core:** Phiên bản Ansible lõi (ví dụ: `2.16.19`).
    *   **Thư viện Python (Python packages):** Các thư viện kết nối API (như `pyvmomi`).
    *   **Dependencies hệ thống (RPM packages):** Các gói OS bổ sung.
    *   **Ansible Runner:** Bộ thư viện hỗ trợ chạy ngầm Ansible.

---

## Ⅵ.  BUILD EXECUTION ENVIRONMENT (EE)
### Cấu trúc thư mục build EE

Để xây dựng một Execution Environment (EE) hoàn chỉnh bằng Ansible Builder, thư mục làm việc của bạn cần chứa 5 thành phần cốt lõi sau:

1. **`execution-environment.yml` (File cấu hình chính):**
   * Định nghĩa cấu trúc tổng thể của EE bao gồm: Container base image nền (ví dụ RHEL 9), phiên bản `ansible-core`, và liên kết tới các file khai báo dependencies khác.
2. **`requirements.txt` (Thư viện Python):**
   * Khai báo các thư viện Python (như `pyVmomi`, `requests`, `aiohttp`) cần tải từ PyPI để hỗ trợ các Module Ansible tương tác với API của vCenter.
3. **`requirements.yml` (Ansible Collections):**
   * Khai báo các bộ sưu tập Collection (như `community.vmware`, `vmware.vmware_rest`) cần tải từ Ansible Galaxy hoặc Automation Hub để cài đặt vào trong EE.
4. **`bindep.txt` (Gói hệ thống RPM):**
   * Khai báo các thư viện hoặc công cụ của hệ điều hành nền (như `gcc`, `python3-devel`, `git`) cần cài đặt thông qua trình quản lý gói (DNF/Microdnf) để phục vụ cho việc biên dịch.
5. **`ansible.cfg` (File cấu hình Ansible):**
   * File cấu hình tạm thời chứa thông tin xác thực/đường dẫn tải Collection từ Automation Hub doanh nghiệp nội bộ để sử dụng trong lúc build.

*   **Lệnh build hoàn chỉnh (chạy tại thư mục workspace):**
```bash
ansible-builder build -f execution-environment.yml --tag vcenter-1.2-ee-nampd:latest -v 2
```


---

## Ⅶ. CÁC THỰC HÀNH TỐT NHẤT (BEST PRACTICES) KHI VIẾT CODE ANSIBLE
### Các thực hành Ansible được khuyến nghị:

*   **Giữ mọi thứ đơn giản**
    *   **Tối đa hóa khả năng đọc**: Sử dụng tên mô tả chi tiết, ghi chú giải thích và khoảng trống dòng kẻ dọc hợp lý.
    *   **Tận dụng các Module sẵn có**: Sử dụng các module chuyên dụng có tính Idempotency và định nghĩa tường minh trạng thái mong muốn của tài nguyên.
*   **Tổ chức khoa học & Hệ thống**
    *   **Chuẩn hóa cách đặt tên và cấu trúc**: Chuẩn hóa cách đặt tên và cấu trúc thư mục dự án theo cấu trúc Ansible Role.
    *   **Tạo nội dung có thể tái sử dụng**: Đóng gói các tác vụ lặp lại thành các Role có thể tái sử dụng.
    *   **Sử dụng Inventory động**: Sử dụng Inventory động của VMware để tự động cập nhật danh sách máy chủ từ vCenter.
*   **Kiểm thử thường xuyên**
    *   **Áp dụng cơ chế xử lý lỗi**: Sử dụng khối `block` và `rescue` để tự động xử lý sự cố hoặc rollback khi gặp lỗi.
    *   **Sử dụng công cụ ansible-lint**: Sử dụng công cụ `ansible-lint` để tự động phát hiện lỗi cú pháp và những đoạn code không chuẩn hóa trước khi commit.

---

## Ⅷ. GIẢI ĐÁP CÁC NỘI DUNG CHƯA RÕ TRONG BUỔI THUYẾT TRÌNH TRƯỚC
### Làm rõ về Include/Import, Cơ chế requirements.txt của Python và Dynamic Inventory

---

#### 1. Sự khác nhau giữa `include_*` và `import_*` và tác động tới Playbook

Sự khác biệt cốt lõi nằm ở **thời điểm xử lý** (Static vs Dynamic) và cách các biến kế thừa khi thực thi:

*   **`import_*` (Static - Tĩnh / Compile Time):**
    *   Ansible phân tích và nạp nội dung của file con **trước khi playbook bắt đầu chạy** (giống như copy-paste code vào file cha).
    *   **Ảnh hưởng đến biến:** Các biến truyền vào qua `vars` của `import` sẽ có phạm vi ảnh hưởng rộng trên toàn bộ playbook. Bạn không thể sử dụng các biến động (được định nghĩa bằng `register` từ tác vụ trước đó) để đặt tên cho file import (ví dụ: `import_tasks: "{{ os_type }}.yml"` sẽ báo lỗi vì lúc biên dịch biến này chưa tồn tại).
    *   **Vòng lặp:** Không hỗ trợ sử dụng chung với vòng lặp (`loop`, `with_*`).
*   **`include_*` (Dynamic - Động / Runtime):**
    *   Ansible chỉ phân tích và nạp nội dung của file con **khi luồng thực thi chạy đến tác vụ đó**.
    *   **Ảnh hưởng đến biến:** Bạn có thể dùng các biến động được tạo ra ở runtime để quyết định file nào sẽ được nạp. Các biến truyền qua `vars` cho một tác vụ `include` chỉ có phạm vi **cục bộ (local scope)** bên trong file được include đó, không ảnh hưởng sang các phần khác của playbook.
    *   **Vòng lặp:** Hỗ trợ đầy đủ vòng lặp (file include sẽ được chạy lặp lại cho mỗi phần tử).

---

#### 2. Cơ chế của file `requirements.txt` và cách hoạt động của `pip` khi không ghi phiên bản

![Bằng chứng pip tự phân giải và hạ cấp phiên bản từ log build EE](images/log%20build%20ee.png)

*   **Cơ chế hoạt động:** Trong quá trình build Execution Environment (EE), file `requirements.txt` khai báo các thư viện Python (như `pyVmomi`, `requests`) cần thiết để các Ansible Modules (ví dụ kết nối VMware vCenter) chạy được.
*   **Khi không chỉ định phiên bản (ví dụ chỉ ghi `requests` hoặc `urllib3`):**
    *   Công cụ cài đặt `pip` sẽ tự động tìm kiếm phiên bản **mới nhất (latest stable version)** tại nguồn chứa mà nó có thể tiếp cận được tại thời điểm build:
        *   **Trong môi trường có Internet:** `pip` truy vấn trực tiếp lên kho chứa PyPI công cộng (`pypi.org`) để tải bản mới nhất (như minh họa trong log: ban đầu `pip` cố gắng tải `vmware-vcenter 9.1.0.0` là bản mới nhất trên mạng).
        *   **Trong môi trường Disconnected (Offline):** `pip` sẽ quét và tải bản mới nhất có sẵn trong **kho lưu trữ nội bộ (như Nexus, Artifactory)** hoặc từ thư mục chứa **Local Wheels** được cấu hình.
    *   **Rủi ro hệ thống:** Không ghi rõ phiên bản sẽ làm mất tính nhất quán và tính lặp lại (Non-reproducible). Lần build hôm nay có thể thành công, nhưng lần build tuần sau có thể bị lỗi do nhà phát triển thư viện bên thứ ba vừa phát hành phiên bản mới có chứa các thay đổi phá vỡ tương thích (breaking changes). 
    *   **Khuyến nghị:** Nên ghi rõ phiên bản (ví dụ: `requests==2.31.0`) để đảm bảo môi trường EE luôn đồng nhất trong mọi lần build, bất kể bạn build ở môi trường online hay disconnected.

---

#### 3. Cấu hình Dynamic Inventory từ vCenter có cần khai báo khóa `plugin` không?

![Ảnh minh họa log đồng bộ Inventory trên AWX](images/awx-log.png)

*   **Câu trả lời:**
    *   **Đồng bộ trực tiếp bằng tính năng của AWX (Source = VMware vCenter):**
        *   **KHÔNG CẦN** viết file YAML hay khai báo khóa `plugin`. 
        *   Khi ta tạo Inventory Source trên giao diện AWX và chọn loại nguồn là `VMware vCenter`, hệ thống AWX đã tự động cấu hình và gọi ngầm plugin tích hợp sẵn. Ta chỉ việc điền thông tin và lọc máy chủ trực tiếp trên Form giao diện.

---

---

## Ⅸ. QUẢN LÝ VÀ TỐI ƯU HÓA VIỆC THỰC THI TASK (CHƯƠNG 6)

### Kiểm soát đặc quyền, xử lý lỗi và tối ưu hiệu năng chạy Playbook

Để kiểm soát chặt chẽ luồng chạy và tối ưu hóa tốc độ thực thi của Ansible Playbook:

#### 1. Kiểm soát leo thang đặc quyền (Privilege Escalation)
*   **Chỉ thị cơ bản:**
    ![Chỉ thị cấu hình đặc quyền](images/config%20directive.png)
*   **Precedence (Độ ưu tiên):**
    *   **Thứ tự ghi đè:** Play level ➔ Block level ➔ Task level (Hẹp nhất, ưu tiên cao nhất).
    *   **Ghi đè dòng lệnh:** Cờ tham số (`-b`, `-e`, `-K`) ghi đè mọi cấu hình tĩnh trong code.
*   **Connection Variables (Biến kết nối):**
    ![Biến kết nối đặc quyền](images/connection%20var.png)
    *   `ansible_become`, `ansible_become_method`, `ansible_become_user`, `ansible_become_password`.
    *   Cấu hình động theo từng host (Inventory/Vars). Ghi đè được playbook directive nhưng không đè được extra vars.
*   **Best Practices:**
    *   *Đặc quyền tối thiểu:* Bật `become: false` toàn cục, chỉ set `become: true` ở các task sửa đổi hệ thống.
    *   *localhost:* Task kết nối API chạy qua `delegate_to: localhost` phải set `become: false` để tránh lỗi thiếu lệnh sudo cục bộ trong Container/Control Node.

#### 2. Quản lý Thứ tự Thực thi Task (Execution Order)
*   **Trật tự mặc định:** Trong một Play, `roles` luôn chạy trước `tasks` bất kể thứ tự viết trong code.
*   **Điều khiển luồng linh hoạt:**
    *   *Role as a Task:* Dùng `import_role` (Tĩnh) hoặc `include_role` (Động) để gọi chạy role xen kẽ giữa các task thường.
    *   *pre_tasks & post_tasks:*
        *   `pre_tasks`: Chạy trước `roles`.
        *   `post_tasks`: Chạy sau `tasks` và sau khi toàn bộ handlers đã chạy xong.
*   **Luồng thực thi một Play (Execution Flowchart):**
    ```text
    [1] pre_tasks ➔ [2] pre_tasks handlers ➔ [3] roles ➔ [4] tasks ➔ [5] roles/tasks handlers ➔ [6] post_tasks ➔ [7] post_tasks handlers
    ```
*   **Điều khiển Handlers & Hosts:**
    *   *Flush Handlers:* Dùng `ansible.builtin.meta: flush_handlers` để ép chạy ngay các handler xếp hàng.
    *   *listen:* Cho phép nhiều handler khác nhau cùng lắng nghe một sự kiện notify.
    *   *order (Thứ tự Host):* `inventory` (mặc định), `reverse_inventory`, `sorted`, `reverse_sorted`, `shuffle`.

#### 3. Chạy chọn lọc qua Tags và Tối ưu hiệu năng
*   **A. Lọc tác vụ bằng Tags:**
    *   *Phạm vi gán:* Play, task, block, role, import file.
    *   *Khác biệt Import vs Include:*
        *   **Import (Static):** Tag gán ở lệnh import sẽ tự động áp dụng cho tất cả task con bên trong.
        *   **Include (Dynamic):** Tag chỉ gán cho task include; các task con bên trong bắt buộc phải có tag tương ứng hoặc `always` mới chạy.
    *   *Lọc khi chạy:* `--tags "tag1,tag2"`, `--skip-tags "tag3"`, `--list-tags`.
    *   *Special Tags:*
        *   `always`: Luôn chạy, trừ khi dùng `--skip-tags always`.
        *   `never`: Chỉ chạy khi gọi đích danh qua `--tags never`.
        *   `tagged` / `untagged` / `all`.
*   **B. Tối ưu hiệu năng Playbook (Speed Optimization):**
    *   **Tối ưu Fact Gathering:**
        *   *Tắt Facts:* Set `gather_facts: false` nếu không dùng.
        *   *Lọc Facts:* Dùng `gather_subset` (như `network`) để chỉ quét thông tin cần thiết.
        *   *Fact Cache:* Đặt `gathering = smart` hoặc bật *Enable fact storage* trên AWX để dùng lại cache.
    *   **Forks & Pipelining:**
        *   *Tăng Forks:* Cấu hình `forks = 50` hoặc `100` trong `ansible.cfg` để chạy song song nhiều host hơn.
        *   *Bật Pipelining:* Đặt `pipelining = True` trong `ansible.cfg` để giảm kết nối SSH (yêu cầu tắt `requiretty` ở host đích).
    *   **Đo lường thời gian (Profiling):**
        *   Bật callback plug-in trong `ansible.cfg`:
            `callbacks_enabled = ansible.posix.timer, ansible.posix.profile_tasks, ansible.posix.profile_roles`
        *   *Tác dụng:* Thống kê thời gian chạy chi tiết của từng Task/Role để tìm điểm nghẽn.
---

## Ⅹ. BIẾN ĐỔI DỮ LIỆU VỚI FILTERS VÀ PLUG-INS (CHƯƠNG 7)
### Xử lý logic và biến đổi dữ liệu phức tạp trong Playbook
Ansible cung cấp các công cụ mạnh mẽ để thao tác và biến đổi dữ liệu một cách linh hoạt:

#### 1. Xử lý biến bằng Jinja2 Filters
*   **Filter cơ bản:** Ép kiểu dữ liệu (`int`), chuyển kiểu chuỗi (`lower`), gán giá trị mặc định khi biến trống (`default`).
*   **Filter danh sách/từ điển:** Loại bỏ trùng lặp (`unique`), lọc đối tượng thỏa mãn điều kiện thuộc tính (`selectattr`), chuyển đổi cấu trúc dễ lặp qua (`dict2items`).

#### 2. Truy xuất dữ liệu ngoài bằng Lookup Plug-ins
*   Sử dụng cú pháp `lookup()` để đọc dữ liệu động trong quá trình thực thi:
    *   `lookup('env', 'VAR')`: Đọc biến môi trường.
    *   `lookup('file', '/path')`: Đọc nội dung tệp tin.
    *   `lookup('url', 'https://api')`: Truy xuất dữ liệu động từ API ngoại vi.

#### 3. Vòng lặp nâng cao và bộ lọc địa chỉ mạng
*   Sử dụng vòng lặp chờ điều kiện bằng `until` kết hợp `retries` và `delay` (chờ dịch vụ lên thành công).
*   Lặp danh sách lồng nhau bằng bộ lọc `subelements`.
*   Xác thực và phân tách thông tin địa chỉ mạng (Subnet, IP, Netmask) bằng filter chuyên dụng `ipaddr`.

---

## Ⅺ. ĐIỀU PHỐI CẬP NHẬT CUỐN CHIẾU (CHƯƠNG 8)
### Chiến lược nâng cấp hệ thống giảm thiểu tối đa thời gian gián đoạn (Zero Downtime)

Khi triển khai trên quy mô lớn, việc điều phối cập nhật cuốn chiếu là rất quan trọng để đảm bảo tính liên tục của dịch vụ:

#### 1. Cơ chế Ủy quyền thực thi (Delegation)
*   **`delegate_to`**: Ủy quyền chạy task liên quan đến máy chủ đích trên một máy chủ khác (ví dụ: đứng từ máy Control Node gọi API tắt/bật cổng của máy chủ đích trên Load Balancer).
*   **`delegate_facts`**: Cho phép ghi nhận dữ kiện (facts) thu thập được vào bộ biến của máy chủ đích thay vì máy chạy ủy quyền.

#### 2. Phân bổ công việc song song bằng `serial`
*   Giới hạn số lượng máy chủ được cập nhật trong từng đợt để tránh làm sập toàn bộ hệ thống cùng lúc:
    *   **Theo số lượng cứng:** `serial: 2` (mỗi đợt chạy tối đa 2 máy).
    *   **Theo phần trăm:** `serial: "30%"`
    *   **Theo lũy tiến:** `serial: [1, 5, "20%"]` (đợt đầu chạy 1 máy để test lỗi, đợt sau tăng dần).

#### 3. Vòng đời cập nhật cuốn chiếu và bảo vệ lỗi
*   Sử dụng khối nhiệm vụ đặc biệt `pre_tasks` (gỡ máy khỏi LB) and `post_tasks` (gắn lại máy vào LB).
*   Cấu hình **`max_fail_percentage`** để tự động dừng khẩn cấp toàn bộ Playbook nếu tỷ lệ lỗi trong một đợt vượt quá ngưỡng quy định (ví dụ: >25% số máy chủ lỗi).

---

## Ⅻ. TẠO COLLECTIONS VÀ MÔI TRƯỜNG THỰC THI EE (CHƯƠNG 9)
### Tự phát triển Ansible Collections và đóng gói môi trường Execution Environment (EE)

Quy trình đóng gói chuyên nghiệp giúp phân phối hạ tầng tự động hóa đồng bộ trong toàn doanh nghiệp:

#### 1. Viết và Đóng gói Ansible Content Collections tự chế
*   Xây dựng thư mục chuẩn hóa chứa Metadata (`galaxy.yml`), các custom modules viết bằng python (`plugins/`), và các kịch bản mẫu (`roles/`, `playbooks/`).
*   Đóng gói thành file nén bằng lệnh: `ansible-galaxy collection build`
*   Cài đặt sử dụng cục bộ: `ansible-galaxy collection install <file.tar.gz>`

#### 2. Xây dựng Custom Automation Execution Environment (EE)
*   Cài đặt công cụ hỗ trợ: `pip install ansible-builder`
*   Viết tệp khai báo môi trường **`execution-environment.yml`**:
    *   Khai báo Base image của Red Hat (`base_image`).
    *   Khai báo các phụ thuộc: `galaxy` (requirements.yml), `python` (requirements.txt), `system` (bindep.txt).
*   Tiến hành biên dịch đóng gói container image:
    ```bash
    ansible-builder build --tag my-custom-ee:1.0 --container-engine podman
    ```

#### 3. Tích hợp và vận hành trên AWX / Automation Controller
*   Đẩy (push) Custom EE image lên kho chứa container registry nội bộ (như Harbor, Quay.io).
*   Đăng ký Container Image vào mục **Execution Environments** trên giao diện AWX.
*   Liên kết EE mới vào **Job Template** để thực thi playbook một cách đồng nhất và an toàn.

