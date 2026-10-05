# BÁO CÁO BÀI 2: CẤU HÌNH PHÂN QUYỀN NHÓM VÀ SUDOERS BẰNG VISUDO

**Họ và tên học viên:** Nguyễn Phúc  
**Email:** phuchb24@gmail.com  
**Đường dẫn nộp bài trên GitHub:** `homework/session_06/ex2/`  
**Ngày thực hiện:** 05/10/2026  

---

## 1. Mục tiêu bài thực hành

- **Quản lý User & Group:** Biết cách tạo nhóm dùng chung (`groupadd`) và tạo/thêm tài khoản người dùng (`useradd`, `usermod`) trên Linux.
- **Cơ chế Quản trị Sudo & `/etc/sudoers`:** Hiểu sâu cách thức ủy quyền quản trị an toàn thông qua tệp `/etc/sudoers`.
- **Cấu hình đặc quyền giới hạn (Granular Privilege Delegation):** Phân quyền chỉ cho phép thực thi một nhóm lệnh giới hạn (`systemctl start/stop/restart/status`) mà không cấp toàn quyền root (`ALL=(ALL) ALL`).
- **Thực thi không mật khẩu (NOPASSWD):** Giúp tự động hóa các kịch bản CI/CD Deployer mà không bị tắc nghẽn bởi nhắc nhập mật khẩu tương tác (interactive password prompt).
- **Thao tác an toàn với `visudo`:** Sử dụng `visudo` để kiểm tra cú pháp trước khi lưu nhằm tránh nguy cơ khóa quyền root hệ thống.

---

## 2. Bối cảnh & Yêu cầu bài toán

Đội ngũ DevOps/Ops cần cấp quyền quản lý và khởi động lại dịch vụ hệ thống cho tài khoản tự động hóa `deployer` thuộc nhóm `devops-admin`.

### Quy tắc bảo mật (Security Constraints):
1. **Tạo nhóm:** `devops-admin`.
2. **Tạo tài khoản:** `deployer` và gán vào nhóm `devops-admin`.
3. **Cấp đặc quyền Sudoers:**
   - Đối tượng áp dụng: Tất cả thành viên thuộc nhóm `%devops-admin`.
   - Các lệnh cho phép thực thi với quyền root: Chỉ duy nhất các lệnh quản lý dịch vụ `systemctl` (`start`, `stop`, `restart`, `status`).
   - Cơ chế xác thực: Khỏi yêu cầu mật khẩu (`NOPASSWD`).

---

## 3. Kiến thức nền tảng (Theoretical Background)

### 3.1 Cấu trúc cú pháp quy tắc Sudoers

Một dòng cấu hình trong tệp `/etc/sudoers` tuân theo cú pháp chuẩn:

$$\text{User/Group} \quad \text{Host}=(\text{Runas\_User}:\text{Runas\_Group}) \quad [\text{Tag:}] \quad \text{Commands}$$

Ví dụ quy tắc bài thực hành:
```sudoers
%devops-admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *
```

#### Phân tích chi tiết từng trường dữ liệu:

| Trường | Giá trị | Ý nghĩa kỹ thuật |
| :--- | :--- | :--- |
| **User/Group** | `%devops-admin` | Tiền tố `%` biểu thị đây là một **Group** trên hệ thống (nếu không có `%` sẽ hiểu là User). |
| **Host** | `ALL` | Quy tắc có hiệu lực trên mọi máy chủ/hostname. |
| **(Runas)** | `(ALL)` | Có thể chạy lệnh dưới danh nghĩa bất kỳ user nào (mặc định là `root`). |
| **Tag** | `NOPASSWD:` | Cho phép thực thi lệnh trực tiếp mà **không cần nhập mật khẩu** của user `deployer`. |
| **Commands** | `/usr/bin/systemctl ...` | Danh sách đường dẫn tuyệt đối của các lệnh được phép thực thi kèm tham số wildcard (`*`). |

### 3.2 Tầm quan trọng của công cụ `visudo`
- Tệp `/etc/sudoers` là tệp cấu hình cốt lõi quản lý quyền root. Nếu chỉnh sửa trực tiếp bằng `nano` hoặc `vim` thông thường và xảy ra lỗi cú pháp (syntax error), toàn bộ câu lệnh `sudo` trên hệ thống sẽ bị khóa, khiến quản trị viên không thể sửa lại tệp.
- Công cụ `visudo` cung cấp cơ chế:
  1. Khoá tệp tạm (file locking) chống tranh chấp chỉnh sửa đồng thời.
  2. Tự động chạy trình kiểm tra cú pháp (`visudo -c`) trước khi ghi đè vào hệ thống.
  3. Hỗ trợ cơ chế mô-đun hóa an toàn qua thư mục `/etc/sudoers.d/`.

---

## 4. Nhật ký thực thi chi tiết (Step-by-Step Execution Log)

### Bước 1: Tạo Nhóm `devops-admin` và Người dùng `deployer`

Thực thi các lệnh với đặc quyền quản trị:

```bash
# 1. Tạo nhóm quản trị devops-admin
sudo groupadd devops-admin

# 2. Tạo tài khoản người dùng deployer với shell mặc định là /bin/bash
sudo useradd -m -s /bin/bash deployer

# 3. Đưa tài khoản deployer vào nhóm devops-admin
sudo usermod -aG devops-admin deployer

# 4. Kiểm tra danh sách nhóm của user deployer
id deployer
```

#### Kết quả lệnh `id deployer`:
```text
uid=1002(deployer) gid=1002(deployer) groups=1002(deployer),1003(devops-admin)
```

---

### Bước 2: Cấu hình quy tắc Sudoers an toàn với `visudo`

Mở trình biên soạn sudoers an toàn:

```bash
sudo visudo
```

Hoặc thêm cấu hình vào tệp mô-đun độc lập trong thư mục `/etc/sudoers.d/devops-admin` (Best Practice):

```bash
# Chỉnh sửa file sudoers riêng cho nhóm devops-admin
sudo visudo -f /etc/sudoers.d/devops-admin
```

#### Thêm đoạn quy tắc sau vào tệp cấu hình:

```sudoers
# ==============================================================================
# Rule per-group cho devops-admin: Chi duoc phep quan ly dich vu bang systemctl
# ==============================================================================
%devops-admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *
```

*Lưu ý:* Cần ghi đường dẫn tuyệt đối của lệnh (ví dụ `/usr/bin/systemctl` hoặc `/bin/systemctl`). Có thể tra cứu bằng lệnh `which systemctl`.

---

## 5. Kiểm tra kết quả & Chứng minh thực nghiệm (Verification)

### Bước 1: Chuyển sang tài khoản `deployer`
Sử dụng `su` để giả lập môi trường đăng nhập của user `deployer`:

```bash
su - deployer
```

---

### Bước 2: Kiểm tra danh mục lệnh sudo được phép thực thi (`sudo -l`)

Thực thi lệnh kiểm tra phân quyền:

```bash
sudo -l
```

#### Kết quả xuất ra màn hình Terminal (Actual Output):

```text
Matching Defaults entries for deployer on ubuntu-server:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User deployer may run the following commands on ubuntu-server:
    (ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *
```

> **Đánh giá:** Lệnh `sudo -l` xác nhận user `deployer` (thông qua nhóm `%devops-admin`) chỉ được phép chạy 4 nhóm thao tác `systemctl` không cần mật khẩu.

---

### Bước 3: Chạy thử lệnh khởi động lại dịch vụ hệ thống (`sudo systemctl restart cron`)

Thực thi lệnh restart dịch vụ `cron`:

```bash
sudo systemctl restart cron
```

Kiểm tra trạng thái dịch vụ sau khi restart:

```bash
sudo systemctl status cron
```

#### Kết quả xuất ra màn hình Terminal (Actual Output):

```text
● cron.service - Regular background program processing daemon
     Loaded: loaded (/lib/systemd/system/cron.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2026-10-05 22:05:12 ICT; 4s ago
       Docs: man:cron(8)
   Main PID: 14820 (cron)
      Tasks: 1 (limit: 4642)
     Memory: 1.2M
        CPU: 4ms
     CGroup: /system.slice/cron.service
             └─14820 /usr/sbin/cron -f -P
```

> **Đánh giá [OK]:** Lệnh `sudo systemctl restart cron` thực thi hoàn thành **tức thì mà KHÔNG yêu cầu nhập mật khẩu**.

---

### Bước 4: Kiểm chứng tính an toàn - Thử nghiệm lệnh KHÔNG được cấp phép

Để chứng minh tài khoản `deployer` không có toàn quyền root, thử chạy một lệnh quản trị khác (ví dụ: `reboot` hoặc xem tệp `/etc/shadow`):

```bash
deployer@ubuntu-server:~$ sudo reboot
```

#### Kết quả xuất ra màn hình Terminal:

```text
Sorry, user deployer is not allowed to execute '/usr/sbin/reboot' as root on ubuntu-server.
```

```bash
deployer@ubuntu-server:~$ sudo cat /etc/shadow
```

#### Kết quả xuất ra màn hình Terminal:

```text
Sorry, user deployer is not allowed to execute '/usr/bin/cat /etc/shadow' as root on ubuntu-server.
```

> **Đánh giá [SECURITY OK]:** Nguyên tắc đặc quyền tối thiểu (PoLP) hoạt động hoàn hảo. Tài khoản `deployer` bị chặn hoàn toàn khi cố gắng thực thi các lệnh ngoài danh mục được cấp phép.

---

## 6. Script Tự động hoá (Automation Setup Script)

Bài thực hành đi kèm tệp script tự động hoá [setup.sh](file:///homework/session_06/ex2/setup.sh) giúp tự động cấu hình toàn bộ user, group, và quy tắc `sudoers` an toàn:

```bash
chmod +x setup.sh
./setup.sh
```

---

## 7. Bài học kinh nghiệm & Best Practices trong Security & DevOps

1. **Nguyên tắc Đặc quyền Tối thiểu (Principle of Least Privilege - PoLP):**
   - Không giờ cấp `ALL=(ALL) ALL` cho tài khoản CI/CD hoặc User vận hành thông thường. Chỉ whitelist các lệnh thực sự cần thiết.

2. **Sử dụng Đường dẫn Tuyệt đối trong Sudoers (Absolute Paths):**
   - Luôn sử dụng `/usr/bin/systemctl` thay vì `systemctl` trong file sudoers để tránh lỗ hổng **PATH Hijacking** (kẻ tấn công tạo file `systemctl` giả mạo nằm ở `/tmp` hoặc `/usr/local/bin` để leo leo quyền root).

3. **Cấu hình Mô-đun hóa qua `/etc/sudoers.d/`:**
   - Thay vì sửa trực tiếp tệp gốc `/etc/sudoers`, hãy tạo các tệp nhỏ trong `/etc/sudoers.d/name` (ví dụ: `/etc/sudoers.d/devops-admin`). Việc này giúp quản lý cấu hình theo dạng Infrastructure as Code (IaC) vô cùng tiện lợi và không làm hỏng cấu hình gốc.
   - Luôn đảm bảo phân quyền cho tệp trong `/etc/sudoers.d/` là `0440` (chỉ cho phép đọc bởi root).
