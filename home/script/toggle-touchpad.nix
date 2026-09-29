{ ... }:

{
  home.file = {
    ".local/bin/toggle-touchpad" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/touchpad-enabled"
        mkdir -p "$STATE_DIR"
  
        # Query trạng thái thực từ sway (state file có thể lệch sau restart).
        current="$(swaymsg -t get_inputs 2>/dev/null | jq -r '[.[] | select(.type == "touchpad") | .libinput.send_events][0] // empty' 2>/dev/null)"
        [ -n "$current" ] || current="enabled"
  
        # Áp lại toàn bộ cấu hình touchpad (khớp sway.nix) để đúng ngay lập tức.
        apply_touchpad_config() {
          swaymsg input type:touchpad pointer_accel 0.6
          swaymsg input type:touchpad accel_profile adaptive
          swaymsg input type:touchpad natural_scroll disabled
          swaymsg input type:touchpad scroll_method two_finger
          swaymsg input type:touchpad tap enabled
          swaymsg input type:touchpad drag enabled
          # events enabled cuối cùng (bật sau khi mọi thiết lập sẵn sàng).
          swaymsg input type:touchpad events enabled
        }
  
        case "$current" in
          enabled)
            swaymsg input type:touchpad events disabled
            new_state="off"
            label="Touchpad đã tắt"
            icon="input-touchpad"
            ;;
          disabled)
            apply_touchpad_config
            new_state="on"
            label="Touchpad đã bật"
            icon="input-touchpad"
            ;;
        esac
  
        echo "$new_state" > "$STATE_FILE"
        notify-send -a toggle-touchpad -i "$icon" -t 2000 "Touchpad" "$label"
      '';
    };
  };
}
