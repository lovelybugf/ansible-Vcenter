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
*   ** Các chỉ thị đặc quyền cơ bản:**

    ![Chỉ thị cấu hình đặc quyền](images/config%20directive.png)
*   ** Các cấp độ cấu hình & Độ ưu tiên (Cái nào ghi đè cái nào):**
    *   Cấu hình đi từ phạm vi rộng đến hẹp: **Play level** (Toàn playbook) $\rightarrow$ **Block level** (Khối lệnh) $\rightarrow$ **Task level** (Từng tác vụ đơn lẻ).
    *   **Quy tắc ghi đè:** Cấp độ hẹp hơn sẽ ghi đè cấp độ rộng hơn. Biến set ở phần option của lệnh chạy playbook sẽ ghi đè tất cả (-b -e -K)
*   ** Các biến kết nối đặc quyền (Connection Variables):**

    ![Biến kết nối đặc quyền](images/connection%20var.png)

    *   Được khai báo trong Inventory hoặc Group/Host vars để định nghĩa riêng cho từng máy chủ(ghi đè các biến trong playbook nhưng không đè được extra var)
        *   `ansible_become`: Bật chuyển quyền cho host cụ thể.
        *   `ansible_become_method` & `ansible_become_user`: Định nghĩa phương thức và user đích cho host.
        *   `ansible_become_password` (hoặc `ansible_become_pass`): Mật khẩu nhập để leo thang (thường được lưu mã hóa an toàn trong Ansible Vault hoặc AWX Credential).
*   ** Best Practices:**
    *   **Nguyên tắc đặc quyền tối thiểu:** Bật `become: false` làm mặc định toàn cục, chỉ set `become: true` ở các task thực sự cần thiết (như cài gói, cấu hình firewall).
    *   **Tránh lỗi quyền sở hữu:** Không chạy các tác vụ tạo tệp tin của người dùng thường bằng quyền root để tránh lỗi `Permission Denied` sau này.

#### 2. Kiểm soát và xử lý lỗi hệ thống (Task Error Control)
*   Sử dụng `ignore_errors: true` để bỏ qua lỗi cục bộ của task.
*   Sử dụng `force_handlers: true` cưỡng ép chạy handlers ngay cả khi playbook bị đứt gãy do lỗi ở task khác.
*   Áp dụng mô hình **Block-Rescue-Always** (tương tự try-catch-finally) để tự động hóa kịch bản rollback (giải cứu) và dọn dẹp tài nguyên.

#### 3. Chạy chọn lọc qua Tags và Tối ưu hiệu năng
*   Gán thẻ `tags` cho task để chỉ định chạy (`--tags`) hoặc bỏ qua (`--skip-tags`).
*   Tăng tốc độ bằng cách cấu hình tiến trình song song `forks` và bật `pipelining = True` trong `ansible.cfg`.
*   Chạy bất đồng bộ bằng `async` và `poll: 0` đối với các tác vụ tốn thời gian.

#### 4. Quản lý Thứ tự Thực thi Task (Controlling Task Execution Order)
*   **Thứ tự mặc định:** Trong một Play, Ansible luôn thực thi các task của **`roles` trước**, sau đó mới thực thi các task trong khối **`tasks`**, bất kể bạn khai báo khối nào trước trong file code.
*   **Cơ chế điều khiển thứ tự chạy linh hoạt:**
    *   **Thực thi Role như một Task:** Dùng module `ansible.builtin.import_role` (Static) hoặc `ansible.builtin.include_role` (Dynamic) để có thể chèn Role chạy xen kẽ giữa các task thường.
    *   **Khai báo `pre_tasks` và `post_tasks`:** Giúp phá vỡ trật tự chạy mặc định bằng các khối tác vụ chạy trước và sau:
        *   `pre_tasks`: Khối tác vụ chạy trước khi cài đặt các roles.
        *   `post_tasks`: Khối tác vụ chạy cuối cùng (sau khi cả tasks và các handlers của play đã hoàn tất).
*   **Sơ đồ luồng thứ tự thực thi của một Play (Execution Flowchart):**
    ```text
    ┌──────────────────────────────────────────────┐
    │                 [1] pre_tasks                │
    └──────────────────────┬───────────────────────┘
                           ▼
    ┌──────────────────────────────────────────────┐
    │     [2] Handlers được notify ở pre_tasks     │
    └──────────────────────┬───────────────────────┘
                           ▼
    ┌──────────────────────────────────────────────┐
    │                  [3] roles                   │
    └──────────────────────┬───────────────────────┘
                           ▼
    ┌──────────────────────────────────────────────┐
    │                  [4] tasks                   │
    └──────────────────────┬───────────────────────┘
                           ▼
    ┌──────────────────────────────────────────────┐
    │  [5] Handlers được notify ở roles & tasks    │
    └──────────────────────┬───────────────────────┘
                           ▼
    ┌──────────────────────────────────────────────┐
    │                 [6] post_tasks               │
    └──────────────────────┬───────────────────────┘
                           ▼
    ┌──────────────────────────────────────────────┐
    │     [7] Handlers được notify ở post_tasks    │
    └──────────────────────────────────────────────┘
    ```
*   **Cơ chế điều khiển Handlers & Hosts:**
    *   **Kích hoạt nóng Handlers:** Sử dụng tác vụ `ansible.builtin.meta: flush_handlers` để ép chạy ngay lập tức các handler đã xếp hàng, không cần đợi đến cuối play.
    *   **Lắng nghe sự kiện (`listen`):** Cho phép một sự kiện thông báo (`notify`) kích hoạt đồng thời nhiều handler khác nhau cùng lắng nghe qua chỉ thị `listen`.
    *   **Sắp xếp thứ tự Host chạy (`order`):** Điều khiển thứ tự chọn host chạy qua tham số `order` (các giá trị: `inventory`, `reverse_inventory`, `sorted`, `reverse_sorted`, `shuffle`).

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

