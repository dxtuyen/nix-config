# 📚 Tài liệu Nix-Config

Tài liệu tiếng Việt của repo `nix-config` — **đọc thẳng trên GitHub**.
Mỗi trang trả lời một câu hỏi thực tế, đọc theo nhu cầu, không cần theo thứ tự.

## Bắt đầu ở đâu

| Trang | Nội dung | Đọc khi nào |
|---|---|---|
| **[01 — Tổng quan hệ thống](01-Tong-Quan-He-Thong.md)** | Repo bố trí thế nào, module nào lo gì, Config vs Dữ liệu | Muốn hiểu hệ thống đang chạy |
| **[02 — Vận hành hằng ngày](02-Van-Hanh-Hang-Ngay.md)** | Rebuild, generation, scripts, lock/sleep, hibernate, sự cố | Dùng máy mỗi ngày |
| **[03 — Cài máy mới từ đầu](03-Cai-May-Moi.md)** | Từ USB → phân vùng → `nixos-install` → kiểm tra hibernate → **Bước 10: Git & SSH** | Máy mới / máy hỏng nặng |
| **[04 — Sao lưu & Khôi phục](04-Sao-Luu-Phuc-Hoi.md)** | Backup dữ liệu ngoài Nix (tar/zip, SSH giữa 2 máy), khôi phục sau khi cài | Chuẩn bị cài lại / sang máy mới |
| **[05 — Từ điển thuật ngữ](05-Tu-Dien-Thuat-Ngu.md)** | Tra nhanh: Nix, flake, zram, hibernate, module... | Gặp thuật ngữ lạ |
| **[06 — Luyện VM](06-Luyen-Tap-VM.md)** | Tập cài máy bằng máy ảo (QEMU/KVM), không rủi ro | Muốn làm quen cài máy |
| **[RemNote](REMNOTE.md)** | Cài & cập nhật RemNote AppImage | Cần xài / cập nhật RemNote |

## Luồng nhanh theo tình huống

- **Sửa config hàng ngày** → [02](02-Van-Hanh-Hang-Ngay.md)
- **Cài máy mới** → [03](03-Cai-May-Moi.md) rồi [04](04-Sao-Luu-Phuc-Hoi.md) (đừng quên khôi phục dữ liệu!)
- **Sang máy mới chỉ có 2 việc tay**: đặt mật khẩu ([03 Bước 7.5](03-Cai-May-Moi.md)) + SSH key lên GitHub ([03 Bước 10](03-Cai-May-Moi.md)) — còn lại tự có sau `nixos-install`
- **Hỏng máy nặng / mất dữ liệu** → [04](04-Sao-Luu-Phuc-Hoi.md)
- **Không hiểu thuật ngữ** → [05](05-Tu-Dien-Thuat-Ngu.md)

## Ghi nhớ quan trọng nhất

- Thay đổi chỉ có hiệu lực sau `sudo nixos-rebuild switch --flake .#laptop` (hoặc `nh os switch`).
- **Config** nằm trong Nix → tái tạo được từ repo. **Dữ liệu** (RemNote AppImage, API key, tài liệu...) nằm ngoài Nix → **nhớ backup** (xem [04](04-Sao-Luu-Phuc-Hoi.md)).