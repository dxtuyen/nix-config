# 📘 Chuyển sang máy mới — Hướng dẫn nhanh

## Khi nào cần

- Cài lại / nâng cấp hệ thống
- Hiểu vì sao máy chạy / không chạy
- Đồng bộ cấu hình sang máy khác

---

## 1. Chuẩn bị

Trước khi rebuild, **commit (lưu) lại toàn bộ thay đổi** (Git là bắt buộc với Nix):

```bash
sudo nixos-rebuild switch --flake .#laptop
```

Nếu chưa có Git:

```bash
git init
git add .
git commit -m "Cấu hình laptop"
git push origin main   # sao lưu lên GitHub/GitLab riêng
```

---

## 2. Lệnh rebuild

```bash
cd /home/doxuantuyen/nix-config
git pull --rebase        # cập nhật code mới nhất từ GitHub
sudo nixos-rebuild switch --flake .#laptop
```

---

## 3. Chuyển sang máy mới

1. **Cài Git + clone repo** trên máy mới:
   ```bash
   git clone <url-repo-của-bạn>
   cd nix-config
   ```

2. **Rebuild**:
   ```bash
   sudo nixos-rebuild switch --flake .#laptop
   ```

---

## Lộ trình học hiểu `nix-config` từ đầu

Đọc tuần tự, mỗi ngày một phần:

### Tuần 1-2: Nền tảng
- Đọc `flake.nix` → `inputs`, `outputs` → module `./hosts/laptop/default.nix`
- Xem `modules/nixos/*.nix` — module dùng chung.

### Tuần 3-4: Cấu hình chính
- `hosts/laptop/default.nix` → nơi định nghĩa hostname, users, waybar...
- Bắt đầu xem phần `imports` → `home-manager.users...`

### Tuần 5-7: Home-manager & Ứng dụng
- `home/packages.nix` → `home/sway.nix` → `home/waybar.nix`
- Đọc kỹ `home/default.nix` phần **style** và phần **scripts.nix**

### Khi Sway gặp lỗi
- Xem log: `journalctl --user -u sway`
- Sửa file `home/sway.nix` → rebuild.

---

## Mẹo đọc / tìm kiếm

- **Tìm nhanh config:**
  ```bash
  grep -n "battery" home/default.nix
  ```
- **Chạy thử an toàn:**
  ```bash
  nix eval '.#nixosConfigurations.laptop...'
  ```
- **Rebuild thành công:**
  ```bash
  sudo nixos-rebuild boot --flake .#laptop
  ```

---

## File thiết yếu

- `hosts/laptop/default.nix`
- `home/default.nix`
- `modules/nixos/*.nix`