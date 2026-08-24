{ pkgs, ... }:

{
  home.file = {
    ".local/bin/lock-screen" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Nếu swaylock đã chạy thì thoát ngay (tránh khóa chồng kép → phải mở khóa 2 lần)
        if pgrep -x swaylock >/dev/null 2>&1; then
          exit 0
        fi

        # -f (daemonize): swaylock tách background và thoát NGAY LẬP TỨC,
        # nên swayidle -w không bị block chờ swaylock → fix tận gốc bug "phải mở khóa nhiều lần"
        # và giúp before-sleep / timeout 900 (auto suspend) chạy đúng lúc.
        # -e (ignore-empty-password): Enter không password sẽ không bị tính là nhập sai.
        exec ${pkgs.swaylock}/bin/swaylock -f -e -i ${./../wallpapers/nixos.jpg}
      '';
    };

    ".local/bin/cycle-wallpaper" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Đổi wallpaper theo giờ: 6:00-17:59 sáng, 18:00-5:59 tối
        hour="$(date +%H)"
        if [ "$hour" -ge 6 ] && [ "$hour" -lt 18 ]; then
          swaymsg "output * bg ${./../wallpapers/tokyonight-bright.jpg} fill"
        else
          swaymsg "output * bg ${./../wallpapers/tokyonight-night.png} fill"
        fi
      '';
    };

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

        # Firmware UEFI: hỏi nix lấy đúng đường dẫn (KHÔNG find /nix/store)
        OVMF_CODE="$(${pkgs.nix}/bin/nix eval --raw nixpkgs#OVMF.firmware)"

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

        exec ${pkgs.qemu}/bin/qemu-system-x86_64 "''${ARGS[@]}"
      '';
    };

    ".local/bin/refresh-session" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        pkill wlsunset 2>/dev/null || true
        wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8 &
        swaymsg reload
        ~/.local/bin/cycle-wallpaper
      '';
    };
    ".local/bin/dict-lookup" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Mở GoldenDict để tra từ điển (hiển thị đẹp, có IPA).
        # GoldenDict tự đọc bộ từ điển StarDict trong ~/.stardict/dic.
        exec ${pkgs.goldendict-ng}/bin/goldendict
      '';
    };

    ".local/bin/quick-lang" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Dịch nhanh bằng Gemini API — hiểu ngữ cảnh, hỗ trợ cả đoạn dài.
        # API key đọc từ biến GEMINI_API_KEY hoặc file ~/.config/quick-lang/api.key.
        set -u

        mode="''${1:-vi-en}"

        # ---- Lấy API key ----
        API_KEY="''${GEMINI_API_KEY:-}"
        if [ -z "$API_KEY" ] && [ -r "''${XDG_CONFIG_HOME:-$HOME/.config}/quick-lang/api.key" ]; then
          API_KEY="$(cat "''${XDG_CONFIG_HOME:-$HOME/.config}/quick-lang/api.key" 2>/dev/null | tr -d '[:space:]')"
        fi
        if [ -z "$API_KEY" ]; then
          notify-send -a quick-lang -u critical -t 7000 "Quick Lang" "Chưa có API key. Ghi key vào ~/.config/quick-lang/api.key hoặc đặt biến GEMINI_API_KEY."
          exit 1
        fi

        # ---- Lấy văn bản: ưu tiên primary selection (text đang bôi), fallback clipboard ----
        text="$(wl-paste -p 2>/dev/null || true)"
        [ -n "''${text//[[:space:]]/}" ] || text="$(wl-paste 2>/dev/null || true)"
        [ -n "''${text//[[:space:]]/}" ] || {
          notify-send -a quick-lang -t 7000 "Quick Lang" "Không có văn bản nào được chọn hoặc copy."
          exit 1
        }

        case "$mode" in
          vi-en) from="Vietnamese"; to="English"; label="VI → EN" ;;
          en-vi) from="English"; to="Vietnamese"; label="EN → VI" ;;
          *) notify-send -a quick-lang -t 7000 "Quick Lang" "Mode không hợp lệ: $mode"; exit 1 ;;
        esac

        # ---- Gọi Gemini Flash ----
        prompt="$(printf 'Dịch văn bản sau từ %s sang %s. Chỉ trả về bản dịch, không thêm giải thích hay chú thích.\n\nVăn bản:\n%s' "$from" "$to" "$text")"
        response="$(timeout 30 curl -sS \
          -H "Content-Type: application/json" \
          -d "$(jq -n --arg p "$prompt" '{contents:[{parts:[{text:$p}]}]}')" \
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$API_KEY" 2>/dev/null || true)"

        result="$(printf '%s' "$response" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null || true)"
        # Làm sạch nếu model tự bọc markdown code fence
        result="$(printf '%s' "$result" | sed -e 's/^```[a-zA-Z]*//' -e 's/```$//' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

        if [ -z "''${result//[[:space:]]/}" ]; then
          notify-send -a quick-lang -u critical -t 7000 "Quick Lang" "Dịch thất bại. Kiểm tra API key hoặc kết nối mạng."
          exit 1
        fi

        printf %s "$result" | wl-copy
        notify-send -a quick-lang -t 7000 "$label" "$result"
      '';
    };

    ".local/bin/toggle-touchpad" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/touchpad-enabled"
        mkdir -p "$STATE_DIR"

        # Query trạng thái THỰC TẾ từ sway thay vì tin state file
        # (state file có thể lệch sau khi restart session vì sway luôn bật touchpad khi khởi động)
        current="$(swaymsg -t get_inputs 2>/dev/null | jq -r '[.[] | select(.type == "touchpad") | (.libinput.send_events // .libinput.events)][0] // empty' 2>/dev/null)"
        [ -n "$current" ] || current="enabled"

        case "$current" in
          enabled)
            swaymsg input type:touchpad events disabled
            new_state="off"
            label="Touchpad đã tắt"
            icon="input-touchpad"
            ;;
          disabled)
            swaymsg input type:touchpad events enabled
            new_state="on"
            label="Touchpad đã bật"
            icon="input-touchpad"
            ;;
        esac

        echo "$new_state" > "$STATE_FILE"
        notify-send -a toggle-touchpad -i "$icon" -t 2000 "Touchpad" "$label"
      '';
    };

    ".local/bin/toggle-wlsunset" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Toggle chế độ ánh sáng màn hình: Tự động → Vàng 4000K → Trắng 6500K → Tự động
        # Query trạng thái THỰC TẾ từ process wlsunset thay vì tin state file
        # (state file có thể lệch sau restart session vì sway luôn bật auto khi khởi động)

        mode="auto"
        pid="$(pgrep -x wlsunset | head -1 2>/dev/null || true)"
        args=""
        if [ -n "$pid" ]; then
          args="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)"
        fi

        case "$args" in
          *"-t 3900"*) mode="warm" ;;
          *"-t 6400"*) mode="cold" ;;
          *) mode="auto" ;;
        esac

        pkill -x wlsunset 2>/dev/null || true

        case "$mode" in
          auto)
            wlsunset -t 3900 -T 4000 -l 21.0 -L 105.8 &
            label="Vàng 4000K"
            icon="weather-clear-night"
            ;;
          warm)
            wlsunset -t 6400 -T 6500 -l 21.0 -L 105.8 &
            label="Trắng 6500K"
            icon="weather-clear"
            ;;
          cold)
            wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8 &
            label="Tự động"
            icon="preferences-system-time"
            ;;
        esac

        notify-send -a wlsunset -i "$icon" -t 2000 "Ánh sáng màn hình" "$label"
      '';
    };

    ".local/bin/power-profile-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Rofi menu to select power profile directly
        set -u

        current="$(powerprofilesctl get)"

        case "$current" in
          power-saver) current_label="Power Saver" ;;
          balanced) current_label="Balanced" ;;
          performance) current_label="Performance" ;;
          *) current_label="$current" ;;
        esac

        MENU="🔋 Power Saver
        ⚖️ Balanced
        🚀 Performance"

        choice=$(printf '%s\n' "$MENU" | rofi -dmenu -i -p "Power Profile" \
          -mesg "Current: $current_label — Select a profile, then press Enter")

        case "$choice" in
          "🔋 Power Saver")
            powerprofilesctl set power-saver
            notify-send -a power-profiles -i "battery" -t 2000 "Power Profile" "Power Saver"
            ;;
          "⚖️ Balanced")
            powerprofilesctl set balanced
            notify-send -a power-profiles -i "power-profile-balanced" -t 2000 "Power Profile" "Balanced"
            ;;
          "🚀 Performance")
            powerprofilesctl set performance
            notify-send -a power-profiles -i "power-profile-performance" -t 2000 "Power Profile" "Performance"
            ;;
        esac
      '';
    };

    ".local/bin/media-notify" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        set -eu

        if [ "''${MEDIA_NOTIFY_LOCKED:-}" != 1 ]; then
          exec env MEDIA_NOTIFY_LOCKED=1 ${pkgs.util-linux}/bin/flock \
            "''${XDG_RUNTIME_DIR:?}/media-notify.lock" "$0" "$@"
        fi

        notify_replace() {
          name="$1"
          shift
          id_file="''${XDG_RUNTIME_DIR:?}/media-notify-''${name}.id"
          replace_id=""

          if [ -r "$id_file" ]; then
            read -r replace_id < "$id_file" || true
            case "$replace_id" in
              *[!0-9]*|"") replace_id="" ;;
            esac
          fi

          if [ -n "$replace_id" ]; then
            notification_id="$(notify-send -p -r "$replace_id" "$@")"
          else
            notification_id="$(notify-send -p "$@")"
          fi

          case "$notification_id" in
            *[!0-9]*|"") ;;
            *) printf '%s\n' "$notification_id" > "$id_file" ;;
          esac
        }

        notify_volume() {
          status="$(wpctl get-volume @DEFAULT_AUDIO_SINK@)"
          volume="$(printf '%s\n' "$status" | awk '{ printf "%d", ($2 * 100) + 0.5 }')"
          case "$status" in
            *MUTED*) 
              notify_replace volume -a volume -i "audio-volume-muted" -h int:value:0 -t 2000 "Volume" "Muted" 
              ;;
            *) 
              if [ "$volume" -ge 70 ]; then
                icon="audio-volume-high"
              elif [ "$volume" -ge 30 ]; then
                icon="audio-volume-medium"
              elif [ "$volume" -gt 0 ]; then
                icon="audio-volume-low"
              else
                icon="audio-volume-muted"
              fi
              notify_replace volume -a volume -i "$icon" -h "int:value:$volume" -t 2000 "Volume" "''${volume}%" 
              ;;
          esac
        }

        notify_microphone() {
          status="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)"
          case "$status" in
            *MUTED*) 
              notify_replace microphone -a volume -i "microphone-sensitivity-muted" -t 2000 "Microphone" "Muted" 
              ;;
            *) 
              notify_replace microphone -a volume -i "audio-input-microphone" -t 2000 "Microphone" "On" 
              ;;
          esac
        }

        notify_brightness() {
          # Lấy % độ sáng dạng số nguyên (bỏ ký tự %)
          bright_raw="$(brightnessctl -m | cut -d, -f4)"
          bright_val="''${bright_raw%%%}"
          notify_replace brightness -a brightness -i "display-brightness" -h "int:value:$bright_val" -t 2000 "Brightness" "''${bright_raw}"
        }

        case "''${1:?missing action}" in
          volume-up) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+; notify_volume ;;
          volume-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; notify_volume ;;
          volume-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; notify_volume ;;
          mic-mute)
            wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            notify_microphone
            ;;
          brightness-up)
            brightnessctl set +10%
            notify_brightness
            ;;
          brightness-down)
            brightnessctl set 10%-
            notify_brightness
            ;;
        esac
      '';
    };

    ".local/bin/open-study-apps" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Mở RemNote và Calibre (không tự chuyển workspace)
        set -u

        notify-send -a open-study-apps -i "view-refresh" -t 3000 -u normal \
          "Mở app Study" "Đang mở RemNote, Calibre..."

        swaymsg "exec appimage-run $HOME/Apps/RemNote/RemNote.AppImage" >/dev/null 2>&1 || true
        swaymsg "exec calibre" >/dev/null 2>&1 || true

        notify-send -a open-study-apps -i "document-open-recent" -t 3000 \
          "Mở app Study" "Đã mở: RemNote, Calibre."
      '';
    };

    ".local/bin/power-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Rofi menu for power & session actions
        set -u

        MENU="⏻ Poweroff
        ↻ Reboot
        ⏾ Suspend
        ⏾ Hibernate
        🔒 Lock
        ⚡ Power Profile
        ↺ Reload Session
        ⏏ Exit Sway"

        choice=$(printf '%s\n' "$MENU" | rofi -dmenu -i -p "Power" \
          -mesg "Select an action, then press Enter")

        case "$choice" in
          "⏻ Poweroff") notify-send -a power -i "system-shutdown" -t 2000 "Power" "Powering off..."; exec systemctl poweroff ;;
          "↻ Reboot") notify-send -a power -i "system-reboot" -t 2000 "Power" "Rebooting..."; exec systemctl reboot ;;
          "⏾ Suspend") notify-send -a power -i "system-suspend" -t 2000 "Power" "Suspending..."; exec systemctl suspend ;;
          "⏾ Hibernate") notify-send -a power -i "system-suspend" -t 2000 "Power" "Hibernating..." ; exec systemctl hibernate ;;
          "🔒 Lock") exec ~/.local/bin/lock-screen ;;
          "⚡ Power Profile") exec ~/.local/bin/power-profile-menu ;;
          "↺ Reload Session") exec ~/.local/bin/refresh-session ;;
          "⏏ Exit Sway") exec swaynag -t warning -m 'Exit Sway?' -B 'Yes, exit sway' 'swaymsg exit' ;;
        esac
      '';
    };

    ".local/bin/screenshot" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Screenshot helper: kiểm tra exit code của slurp để tránh thông báo sai khi hủy
        set -u

        mode="''${1:?missing mode}"

        case "$mode" in
          selection-clipboard)
            region="$(slurp)" || exit 1
            grim -g "$region" - | wl-copy
            notify-send -a screenshot -i "camera-photo" -t 2000 "Screenshot" "Selection copied to clipboard"
            ;;
          fullscreen-clipboard)
            grim - | wl-copy
            notify-send -a screenshot -i "camera-photo" -t 2000 "Screenshot" "Fullscreen copied to clipboard"
            ;;
          selection-save)
            region="$(slurp)" || exit 1
            f="$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"
            mkdir -p "$(dirname "$f")"
            grim -g "$region" "$f" && wl-copy < "$f"
            notify-send -a screenshot -i "camera-photo" -t 2000 "Screenshot" "Selection saved to file"
            ;;
          fullscreen-save)
            f="$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"
            mkdir -p "$(dirname "$f")"
            grim "$f" && wl-copy < "$f"
            notify-send -a screenshot -i "camera-photo" -t 2000 "Screenshot" "Fullscreen saved to file"
            ;;
          *)
            echo "Unknown mode: $mode" >&2
            exit 1
            ;;
        esac
      '';
    };

    ".local/bin/screenshot-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Rofi menu for screenshot actions
        set -u

        MENU="📷 Selection → Clipboard (Print)
        🖥️ Fullscreen → Clipboard (Alt+Print)
        📁 Selection → Save file (Shift+Print)
        💾 Fullscreen → Save file (Ctrl+Print)"

        choice=$(printf '%s\n' "$MENU" | rofi -dmenu -i -p "Screenshot" \
          -mesg "Select an action, then press Enter")

        case "$choice" in
          "📷 Selection → Clipboard (Print)")
            exec ~/.local/bin/screenshot selection-clipboard
            ;;
          "🖥️ Fullscreen → Clipboard (Alt+Print)")
            exec ~/.local/bin/screenshot fullscreen-clipboard
            ;;
          "📁 Selection → Save file (Shift+Print)")
            exec ~/.local/bin/screenshot selection-save
            ;;
          "💾 Fullscreen → Save file (Ctrl+Print)")
            exec ~/.local/bin/screenshot fullscreen-save
            ;;
        esac
      '';
    };
  };

  systemd.user.services.cycle-wallpaper = {
    Unit = {
      Description = "Cycle wallpaper based on time of day";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/cycle-wallpaper";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.timers.cycle-wallpaper = {
    Unit = {
      Description = "Run cycle-wallpaper at 6:00 and 18:00";
    };
    Timer = {
      OnCalendar = [
        "*-*-* 06:00:00"
        "*-*-* 18:00:00"
      ];
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
