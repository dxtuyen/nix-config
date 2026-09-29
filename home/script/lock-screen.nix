{ pkgs, ... }:

{
  home.file = {
    ".local/bin/lock-screen" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
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
