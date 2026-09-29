{ pkgs, ... }:

{
  home.file = {
    ".local/bin/vm-nixos" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # vm-nixos — chạy VM luyện tập cài NixOS (docs/06-Luyen-Tap-VM.md)
        #   vm-nixos         boot từ đĩa đã cài (mặc định)
        #   vm-nixos iso     boot từ ISO để cài mới
        #   VM_DIR=~/VMs     đổi thư mục chứa iso/ nếu muốn
        set -euo pipefail
  
        DIR="''${VM_DIR:-$HOME/VMs}"
        DISK="$DIR/disk/training.qcow2"
        ISO="$(find "$DIR/iso" -maxdepth 1 -name '*.iso' 2>/dev/null | sort | head -1 || true)"
  
        MODE="''${1:-disk}"
        case "$MODE" in
          iso|install) MODE=iso ;;
          disk|boot)   MODE=disk ;;
          *) echo "Dùng: vm-nixos [iso|disk]" >&2; exit 1 ;;
        esac
  
        [ -f "$DISK" ] || {
          echo "Không thấy đĩa $DISK" >&2
          echo "Tạo bằng: qemu-img create -f qcow2 \"$DISK\" 30G" >&2
          exit 1
        }
        if [ "$MODE" = iso ] && [ -z "$ISO" ]; then
          echo "Không thấy ISO trong $DIR/iso — xem docs/06-Luyen-Tap-VM.md Bước 1" >&2
          exit 1
        fi
  
        # Firmware UEFI nội suy lúc BUILD từ pkgs.OVMF → offline, pin theo
        # flake.lock.
        OVMF_CODE="${pkgs.OVMF.firmware}"
  
        ARGS=(
          -machine q35,accel=kvm
          -cpu host
          -m 3G
          -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
          -drive "file=$DISK,if=virtio,format=qcow2"
          -nic user,model=virtio
          -display gtk
        )
        if [ "$MODE" = iso ]; then
          ARGS+=(-boot d -cdrom "$ISO")
        else
          ARGS+=(-boot c)
        fi
  
        exec ${pkgs.qemu_kvm}/bin/qemu-system-x86_64 "''${ARGS[@]}"
      '';
    };
  };
}
