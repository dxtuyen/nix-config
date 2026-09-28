#!/usr/bin/env bash
# reset-generations.sh — dọn generation NixOS cũ + ĐÁNH SỐ LẠI profile về 1.
#
# VÌ SAO CẦN: mỗi lần `nixos-rebuild switch` thêm 1 generation
# (/nix/var/nix/profiles/system-<N>-link). Nix đánh số mới = **số lớn nhất còn
# lại + 1**, nên chỉ xoá bớt generation thì số KHÔNG nhỏ đi — muốn về 1 phải
# đổi tên link còn lại.
#
# Script làm 4 việc:
#   1. Xoá mọi generation trừ bản đang chạy (`nix-env --delete-generations old`).
#   2. Đổi tên `system-<N>-link` còn lại thành `system-1-link`, sửa symlink
#      `system` trỏ vào nó ⇒ lần rebuild sau tự là generation 2, rồi 3, 4...
#   3. `nixos-rebuild switch` để tạo generation 2 và ghi lại boot entry. Builder
#      systemd-boot XOÁ MỌI entry `nixos*` trong /boot/loader/entries rồi ghi
#      lại theo danh sách generation hiện có ⇒ entry cũ tự được dọn, không cần
#      xoá tay.
#   4. `nix-collect-garbage -d` — thu hồi dung lượng store của generation cũ.
#
# ⚠️ SAU KHI CHẠY KHÔNG THỂ rollback về các bản cũ nữa (đã xoá vĩnh viễn).
#    Lưới an toàn còn lại: generation 1 (bản đang chạy) + `configurationLimit`
#    (menu boot giữ 10 entry) + GC tự động hàng tuần (`--delete-older-than 7d`).
#
# 2 chốt an toàn bắt buộc, script tự kiểm:
#   • /boot phải đang mount — không thì bước 3 chết ở "Failed to install
#     bootloader" (đã từng xảy ra do /etc/fstab còn UUID máy khác).
#   • Không bao giờ để 0 generation — builder systemd-boot từ chối chạy và
#     thoát 1 khi danh sách generation rỗng.
#
# Dùng:  sudo bash scripts/reset-generations.sh [flake-dir] [host]
#        mặc định: flake-dir = thư mục cha của script, host = laptop

set -euo pipefail

FLAKE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
HOST="${2:-laptop}"
PROFILE=/nix/var/nix/profiles/system
GEN_DIR=/nix/var/nix/profiles

if [ "$(id -u)" -ne 0 ]; then
  echo "Phải chạy bằng sudo (đụng /nix/var/nix/profiles và /boot)." >&2
  exit 1
fi
if [ ! -f "$FLAKE/flake.nix" ]; then
  echo "Không thấy $FLAKE/flake.nix — truyền đường dẫn flake: sudo bash $0 /đường/dẫn" >&2
  exit 1
fi
if ! mountpoint -q /boot; then
  echo "LỖI: /boot chưa mount ⇒ rebuild sẽ chết ở 'Failed to install bootloader'." >&2
  echo "     Kiểm tra: lsblk -o NAME,UUID   rồi  mount /dev/disk/by-uuid/<UUID-ESP> /boot" >&2
  exit 1
fi

echo "== 0. Hiện trạng =="
nix-env -p "$PROFILE" --list-generations
CUR_LINK="$(readlink "$PROFILE")"                      # vd: system-18-link
CUR_NUM="${CUR_LINK#system-}"; CUR_NUM="${CUR_NUM%-link}"
CUR_STORE="$(readlink -f "$PROFILE")"
echo "   đang dùng: generation $CUR_NUM → $CUR_STORE"
echo "   flake: $FLAKE#${HOST} · /boot: đã mount · dung lượng:"; df -h /nix | tail -1

echo
echo "== 1. Xoá mọi generation cũ (giữ bản đang chạy) =="
nix-env -p "$PROFILE" --delete-generations old

echo
echo "== 2. Đánh số lại thành generation 1 =="
if [ "$CUR_NUM" = "1" ]; then
  echo "   đã là generation 1, không cần đổi tên."
else
  [ -e "$GEN_DIR/system-1-link" ] && { echo "LỖI: system-1-link đã tồn tại." >&2; exit 1; }
  mv "$GEN_DIR/system-$CUR_NUM-link" "$GEN_DIR/system-1-link"
  ln -sfn system-1-link "$PROFILE"
  echo "   system-$CUR_NUM-link → system-1-link (đích giữ nguyên: $CUR_STORE)"
fi
nix-env -p "$PROFILE" --list-generations

echo
echo "== 3. Rebuild (tạo generation 2 + ghi lại boot entry) =="
nixos-rebuild switch --flake "$FLAKE#$HOST"

echo
echo "== 4. Dọn store =="
nix-collect-garbage -d

echo
echo "== Xong =="
nix-env -p "$PROFILE" --list-generations
echo "Entry trong /boot:"; ls -1 /boot/loader/entries/
df -h /nix | tail -1
