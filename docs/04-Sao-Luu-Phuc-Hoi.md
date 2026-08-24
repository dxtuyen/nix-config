# 04 — Sao lưu & Khôi phục dữ liệu

> Dùng kèm với [03-Cai-May-Moi](03-Cai-May-Moi.md): sau khi cài máy mới xong phần hệ thống,
> làm tiếp theo tài liệu này để lấy lại dữ liệu cá nhân.

## Vì sao cần

Config Nix (theme, phím tắt, danh sách gói) **tự tái tạo** từ repo khi cài lại.
Nhưng **dữ liệu cá nhân nằm ngoài Nix** — cài máy mới / hỏng ổ sẽ **mất hẳn** nếu không backup trước.

## Những gì cần backup

| Thứ | Vị trí | Ghi chú |
|---|---|---|
| RemNote AppImage | `~/Apps/RemNote/RemNote.AppImage` | bản cài; ghi chú đã có trên cloud RemNote |
| Gemini API key | `~/.config/quick-lang/api.key` | mất → `quick-lang` hỏng |
| Từ điển StarDict | `~/.stardict/dic/` | cho GoldenDict |
| Tài liệu & tải về | `~/Documents`, `~/Downloads`, `~/Pictures/Screenshots` | ảnh chụp màn hình |
| SSH keys | `~/.ssh/`, `~/.gnupg/` | nếu có |

## Backup trước khi cài mới (chạy trên máy cũ)

Cắm ổ ngoài / USB, mount tại `/mnt/backup`, rồi:

```bash
mkdir -p /mnt/backup

rsync -a ~/Apps/RemNote               /mnt/backup/
rsync -a ~/.config/quick-lang         /mnt/backup/config/
rsync -a ~/.stardict                  /mnt/backup/
rsync -a ~/Documents ~/Downloads ~/Pictures /mnt/backup/
rsync -a ~/.ssh ~/.gnupg              /mnt/backup/ 2>/dev/null || true

# Kiểm tra đủ trước khi rời máy cũ:
ls -la /mnt/backup/
```

> Không có ổ ngoài? Tạo 1 file tar rồi đẩy lên cloud:
> ```bash
> tar czf ~/backup-personal.tar.gz \
>   ~/Apps/RemNote ~/.config/quick-lang ~/.stardict \
>   ~/Documents ~/Downloads ~/Pictures ~/.ssh 2>/dev/null
> ```

## Khôi phục sau khi cài máy mới

Sau khi vào được desktop (theo [03-Cai-May-Moi](03-Cai-May-Moi.md)), cắm ổ backup và copy ngược:

```bash
mkdir -p ~/Apps ~/.config

rsync -a /mnt/backup/RemNote     ~/Apps/
rsync -a /mnt/backup/config/quick-lang ~/.config/
rsync -a /mnt/backup/stardict    ~/.stardict
rsync -a /mnt/backup/Documents   ~/Documents
rsync -a /mnt/backup/Downloads   ~/Downloads
rsync -a /mnt/backup/Pictures    ~/Pictures
rsync -a /mnt/backup/.ssh        ~/.ssh 2>/dev/null || true

# Nếu dùng file tar:
# tar xzf backup-personal.tar.gz -C ~
```

## Checklist khôi phục nhanh (10 phút)

- [ ] `swapon --show` → có `/dev/nvme0n1p3` (10G)
- [ ] `cat /proc/cmdline` → có `resume=UUID=...`
- [ ] `systemctl hibernate` thử → bật lại, cửa sổ còn nguyên
- [ ] Menu nguồn (`power-menu`) có mục `⏾ Hibernate`
- [ ] RemNote mở được (AppImage đã copy)
- [ ] `quick-lang` dịch được (api.key đã copy)
- [ ] `cd ~/nix-config && git status` sạch → config khớp repo

## Liên quan

- [03-Cai-May-Moi](03-Cai-May-Moi.md) — toàn bộ quy trình cài máy mới
- [01-Tong-Quan-He-Thong](01-Tong-Quan-He-Thong.md) — mục "Config vs Dữ liệu"