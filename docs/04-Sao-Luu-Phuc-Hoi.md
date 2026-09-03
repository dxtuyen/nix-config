# 04 — Sao lưu & Khôi phục dữ liệu

> Dùng kèm với [03-Cai-May-Moi](03-Cai-May-Moi.md): sau khi cài máy mới xong phần hệ thống,
> làm tiếp theo tài liệu này để lấy lại dữ liệu cá nhân.

## Vì sao cần

Config Nix (theme, phím tắt, danh sách gói) **tự tái tạo** từ repo khi cài lại.
Nhưng **dữ liệu cá nhân nằm ngoài Nix** — cài máy mới / hỏng ổ sẽ **mất hẳn** nếu không backup trước.

> 🔑 **SSH key không còn cần backup**: mỗi máy tự tạo key mới theo
> **Đường B — [03 Bước 10](03-Cai-May-Moi.md)** (~2 phút), key cũ trên GitHub cứ để nguyên.

## Những gì cần backup

| Thứ | Vị trí | Ghi chú |
|---|---|---|
| RemNote AppImage | `~/Apps/RemNote/RemNote.AppImage` | hoặc tải lại từ trang chủ (xem `docs/REMNOTE.md`) |
| Gemini API key | `~/.config/quick-lang/api.key` | mất → `quick-lang` hỏng |
| Từ điển StarDict | `~/.stardict/dic/` | cho GoldenDict |
| Tài liệu & tải về | `~/Documents`, `~/Downloads`, `~/Pictures/Screenshots` | ảnh chụp màn hình |
| ~~SSH keys~~ | ~~`~/.ssh/`~~ | **không cần nữa** — tạo key mới theo Đường B (docs/03 Bước 10) |

## Backup trước khi cài mới (chạy trên máy cũ)

### Cách 1 — Copy trực tiếp ra ổ ngoài / USB (rsync)

Cắm ổ ngoài / USB, mount tại `/mnt/backup`, rồi:

```bash
mkdir -p /mnt/backup

rsync -a ~/Apps/RemNote               /mnt/backup/
rsync -a ~/.config/quick-lang         /mnt/backup/config/
rsync -a ~/.stardict                  /mnt/backup/
rsync -a ~/Documents ~/Downloads ~/Pictures /mnt/backup/

# Kiểm tra đủ trước khi rời máy cũ:
ls -la /mnt/backup/
```

### Cách 2 — Nén thành 1 file (tar / zip) rồi chép USB hoặc đẩy lên cloud

Quy tắc chọn định dạng:

- **`tar`** (`.tar.gz`) — khuyên dùng: **giữ nguyên quyền file** và gói cả đống
  thư mục thành một file duy nhất.
- **`zip`** — chỉ dùng khi cần mở trên Windows/điện thoại. **Không dùng zip cho
  các thư mục đòi quyền riêng** (vd `~/.ssh` nếu lỡ backup): zip không giữ quyền
  → restore xong bị lỗi "bad permissions".

```bash
# Nén TẤT CẢ data cần giữ vào 1 file (rồi chép USB / đẩy Google Drive...)
tar czf ~/backup-personal.tar.gz \
  ~/Apps/RemNote ~/.config/quick-lang ~/.stardict \
  ~/Documents ~/Downloads ~/Pictures 2>/dev/null

# Kiểm tra trước khi rời máy cũ:
ls -lh ~/backup-personal.tar.gz              # dung lượng hợp lý?
tar tzf ~/backup-personal.tar.gz | head -20  # xem trong file có gì
```

Chỉ nén một phần? Ví dụ riêng Documents + Pictures:

```bash
cd ~
tar czf backup-docs.tar.gz Documents Pictures
# hoặc zip (mở được trên Windows/điện thoại):
zip -r backup-docs.zip Documents Pictures
```

**Giải nén lại trên máy mới** (giả sử file nằm ở `~/Downloads`):

```bash
tar xzf ~/Downloads/backup-personal.tar.gz -C ~   # -C ~ = giải về ĐÚNG vị trí cũ
tar xzf ~/Downloads/backup-docs.tar.gz -C ~
unzip ~/Downloads/backup-docs.zip -d ~            # nếu là zip
```

> Không có ổ ngoài? Tải file `backup-personal.tar.gz` lên Google Drive/Dropbox
> bằng Chrome (được cài sẵn), máy mới tải ngược về là xong.

### Cách 3 — Chuyển thẳng máy cũ → máy mới qua mạng (SSH, không cần USB)

Nguyên lý: máy **cũ** (nơi có data) mở dịch vụ SSH (`sshd`), máy **mới**
"kéo" data về bằng `rsync`. Hai máy phải cùng mạng wifi/router.

**Bước 1 — trên MÁY CŨ: bật sshd tạm thời + xem IP.**

Config của repo này **không bật sẵn sshd**, nên phải chạy tạm qua nix-shell:

```bash
# Sinh host key lần đầu (chỉ cần 1 lần):
sudo nix-shell -p openssh --run 'sudo ssh-keygen -A'

# Chạy sshd tạm — GIỮ terminal này mở đến khi chép xong:
sudo nix-shell -p openssh --run 'sudo $(which sshd) -D'
# (sshd đòi chạy bằng đường dẫn tuyệt đối → phải viết $(which sshd))

# Xem IP máy cũ (nhìn dòng 192.168.x.x):
ip addr | grep 'inet 192'
```

> Máy cũ là Ubuntu/Debian thì đơn giản hơn: `sudo apt install openssh-server`
> (chạy nền luôn, khỏi giữ terminal).

**Bước 2 — trên MÁY MỚI (đã cài xong + vào desktop): kéo data về.**

```bash
# Thay tenuser / 192.168.1.23 bằng user + IP của MÁY CŨ:
OLD=tenuser@192.168.1.23

rsync -av $OLD:Apps/RemNote ~/Apps/
rsync -av $OLD:.config/quick-lang ~/.config/
rsync -av $OLD:.stardict ~/
rsync -av $OLD:Documents $OLD:Downloads $OLD:Pictures ~/
```

> Lần đầu kết nối hỏi fingerprint → gõ `yes`. Chỉ cần 1 file?
> `scp $OLD:.config/quick-lang/api.key ~/Downloads/`

## Khôi phục sau khi cài máy mới

Sau khi vào được desktop (theo [03-Cai-May-Moi](03-Cai-May-Moi.md)):

```bash
mkdir -p ~/Apps ~/.config

# Từ ổ backup (Cách 1):
rsync -a /mnt/backup/RemNote     ~/Apps/
rsync -a /mnt/backup/config/quick-lang ~/.config/
rsync -a /mnt/backup/stardict    ~/.stardict
rsync -a /mnt/backup/Documents   ~/Documents
rsync -a /mnt/backup/Downloads   ~/Downloads
rsync -a /mnt/backup/Pictures    ~/Pictures

# Từ file tar (Cách 2): tar xzf backup-personal.tar.gz -C ~
# Cách 3 đã kéo thẳng về đúng chỗ → không cần làm gì thêm
```

## Checklist khôi phục nhanh (10 phút)

- [ ] `swapon --show` → có `/dev/nvme0n1p3` (10G)
- [ ] `cat /proc/cmdline` → có `resume=UUID=...`
- [ ] `systemctl hibernate` thử → bật lại, cửa sổ còn nguyên
- [ ] Menu nguồn (`power-menu`) có mục `⏾ Hibernate`
- [ ] `ssh-keygen` + add key GitHub + `ssh -T git@github.com` → "Hi dxtuyen!" (docs/03 Bước 10)
- [ ] `cd ~/nix-config && git pull --rebase && git push` → thành công qua SSH
- [ ] RemNote mở được (AppImage đã copy/tải lại)
- [ ] `quick-lang` dịch được (api.key đã copy)
- [ ] `cd ~/nix-config && git status` sạch → config khớp repo

## Liên quan

- [03-Cai-May-Moi](03-Cai-May-Moi.md) — toàn bộ quy trình cài máy mới (**Bước 10: Git & SSH**)
- [01-Tong-Quan-He-Thong](01-Tong-Quan-He-Thong.md) — mục "Config vs Dữ liệu"
