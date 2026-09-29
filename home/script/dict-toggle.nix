{ pkgs, ... }:

{
  home.file = {
    ".local/bin/dict-toggle" = {
      executable = true;
      text = ''
          #! /usr/bin/env bash
          # Wayland cấm app tự focus/nhảy workspace → sway kéo cửa sổ về.
          # Đóng khi đang focus = ẩn về tray (tiến trình giữ nguyên, mở lại nhanh).
          set -u
          APP_ID="io.github.xiaoyifang.goldendict_ng"

          # Ưu tiên cửa sổ chính; fallback node bất kỳ (tránh bắt nhầm dialog About).
          node="$(swaymsg -t get_tree | jq -c --arg id "$APP_ID" '
            ([.. | objects | select(.app_id? == $id and .type? == "floating_con")][0]
             // [.. | objects | select(.app_id? == $id)][0]) // empty')"

          if [ -z "$node" ]; then
            exec ${pkgs.goldendict-ng}/bin/goldendict
          fi

          cid="$(jq -rn --argjson n "$node" '$n.id')"
          focused="$(jq -rn --argjson n "$node" '$n.focused // false')"

          if [ "$focused" = "true" ]; then
            swaymsg "[con_id=$cid] kill"
          else
            # Kéo về workspace hiện tại + focus.
            swaymsg "[con_id=$cid] move container to workspace current"
            swaymsg "[con_id=$cid] focus"
          fi
      '';
    };
  };
}
