{ ... }:

{
  home.file = {
    ".local/bin/bar-toggle" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Ẩn/hiện Waybar bằng SIGUSR1 (chính là toggle của Waybar: ẩn rồi hiện
        # lại đúng chỗ cũ, không restart nên không nháy layout, không mất state
        # của các module custom).
        #
        # ⚠️ Tên tiến trình KHÔNG phải luôn là `waybar`:
        #   - `programs.waybar.systemd.enable = true` (đang dùng) → Home-Manager
        #     bọc qua `.waybar-wrapped`, nên `pkill -x waybar` KHÔNG khớp.
        #   - Nếu sau này tắt systemd.enable, tên lại thành `waybar`.
        # Thử cả hai, không đoán mò.
        set -u

        killed=0
        for name in waybar .waybar-wrapped; do
          if pkill -x -SIGUSR1 "$name" 2>/dev/null; then
            killed=1
            break
          fi
        done

        if [ "$killed" -eq 0 ]; then
          notify-send -a bar-toggle -t 3000 "Waybar" \
            "Không tìm thấy tiến trình waybar (đã thử cả 'waybar' và '.waybar-wrapped')" \
            2>/dev/null || true
          exit 1
        fi

        # SIGUSR1 tự đảo trạng thái; script không cần (và không nên) đoán trước
        # là đang ẩn hay hiện — đọc state của Waybar là thừa.
      '';
    };
  };
}
