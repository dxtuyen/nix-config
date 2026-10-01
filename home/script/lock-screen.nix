{ pkgs, ... }:

{
  home.file = {
    ".local/bin/lock-screen" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Khóa màn → tạm dừng phiên ngay (no-op nếu không có phiên/paused sẵn);
        # mở khóa KHÔNG tự resume — bấm ▶ để tiếp tục. Đặt TRƯỚC guard để trường
        # hợp swaylock đang chạy (khóa chồng) cũng không bỏ lỡ pause.
        "$HOME/.local/bin/countdown-engine" lock-pause 2>/dev/null || true

        # Tránh khóa chồng (không thì phải mở khóa 2 lần).
        if pgrep -x swaylock >/dev/null 2>&1; then
          exit 0
        fi

        # -f để swayidle không bị block; -e để Enter trống không tính nhập sai.
        exec ${pkgs.swaylock}/bin/swaylock -f -e -i ${./../../lockscreen/nixos.jpg}
      '';
    };
  };
}
