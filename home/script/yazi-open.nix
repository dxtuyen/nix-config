{ pkgs, ... }:

{
  home.file = {
    ".local/bin/yazi-open" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Mở yazi trong cửa sổ foot NHỎ (popup) — gắn $mod+y, chọn nhanh file /
        # thêm-xoá ảnh. Duyệt kỹ (xem trước ảnh/PDF) thì gõ `yazi` trong terminal.
        #
        # Yazi chạy BÊN TRONG foot nên sway chỉ thấy app_id="foot". Title riêng
        # `yazi-popup` để chỉ cửa sổ này float (rule trong home/config/sway.nix).
        set -u
        TERM_BIN="${pkgs.foot}/bin/foot"
        FOOT_SIZE="--window-size-pixels=1000x700"
  
        exec "$TERM_BIN" --title=yazi-popup $FOOT_SIZE -e yazi "$@"
      '';
    };
  };
}
