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
        exec ${pkgs.swaylock}/bin/swaylock -f -e -i ${./../wallpapers/nixos.jpg}
      '';
    };

    ".local/bin/idle-suspend" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Chỉ ngủ khi dùng pin. Cắm sạc → thức tiếp (màn vẫn tắt & khóa).
        # Phiên Focus chạy → không suspend (END_TIME wall-clock).
        if pgrep -f "study daemon" >/dev/null 2>&1; then
          exit 0
        fi
        for bat in /sys/class/power_supply/BAT*; do
          [ -e "$bat/status" ] || continue
          if [ "$(cat "$bat/status")" = Discharging ]; then
            exec ${pkgs.systemd}/bin/systemctl suspend
          fi
        done
        # Cắm sạc → trồng watcher: rút sạc khi vẫn idle → khóa + suspend
        # (swayidle chỉ chạy timeout 900 một lần mỗi chu kỳ).
        if ! pgrep -f idle-suspend-ac-watch >/dev/null 2>&1; then
          ${pkgs.bash}/bin/bash "$HOME/.local/bin/idle-suspend-ac-watch" >/dev/null 2>&1 &
        fi
      '';
    };

    ".local/bin/idle-suspend-ac-watch" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Watcher cho trường hợp idle 900s mà đang cắm sạc: poll pin mỗi 30s.
        # Thoát khi có thao tác / phiên Focus bật / mất sway / rút sạc → suspend.
        while true; do
          out="$(swaymsg -t get_outputs 2>/dev/null)" || exit 0
          [ -n "$out" ] || exit 0
          if printf '%s' "$out" | grep -q '"power": true'; then
            exit 0
          fi
          if pgrep -f "study daemon" >/dev/null 2>&1; then
            exit 0
          fi
          for bat in /sys/class/power_supply/BAT*; do
            [ -e "$bat/status" ] || continue
            if [ "$(cat "$bat/status")" = Discharging ]; then
              "$HOME/.local/bin/lock-screen" >/dev/null 2>&1
              exec ${pkgs.systemd}/bin/systemctl suspend
            fi
          done
          sleep 30
        done
      '';
    };

    ".local/bin/wallpaper-set" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # wallpaper-set [ảnh|day|night] — random ảnh theo giờ qua awww
        # (transition fade 2s). day- 06:00–17:59, night- còn lại; tránh lặp
        # lại ảnh đang đặt. Ảnh để ở ~/Pictures/wallpapers — thêm ảnh mới
        # với tiền tố day-/night- là dùng được ngay, không cần rebuild.
        set -u

        WALL_DIR="$HOME/Pictures/wallpapers"
        CACHE="$HOME/.cache/wallpaper-current"

        img=""
        if [ "$#" -ge 1 ] && [ -f "$1" ]; then
          img="$1"
        else
          hour="$(date +%H)"
          prefix="night-"
          if [ "$hour" -ge 6 ] && [ "$hour" -lt 18 ]; then prefix="day-"; fi
          case "''${1:-}" in
            day) prefix="day-" ;;
            night) prefix="night-" ;;
          esac
          mapfile -t imgs < <(find "$WALL_DIR" -maxdepth 1 -xtype f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -name "$prefix*" | sort)
          if [ "''${#imgs[@]}" -eq 0 ]; then
            mapfile -t imgs < <(find "$WALL_DIR" -maxdepth 1 -xtype f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | sort)
          fi
          n="''${#imgs[@]}"
          if [ "$n" -eq 0 ]; then
            notify-send -a wallpaper "wallpaper-set" "Không có ảnh nào trong $WALL_DIR" 2>/dev/null || true
            exit 1
          fi
          prev="$(cat "$CACHE" 2>/dev/null || true)"
          img="''${imgs[$((RANDOM % n))]}"
          while [ "$n" -gt 1 ] && [ "$img" = "$prev" ]; do
            img="''${imgs[$((RANDOM % n))]}"
          done
        fi

        # Bảo đảm daemon sống (thường đã chạy theo sway-session.target).
        systemctl --user start awww-daemon.service 2>/dev/null || true
        i=0
        while ! ${pkgs.awww}/bin/awww query >/dev/null 2>&1; do
          i=$((i + 1))
          if [ "$i" -ge 40 ]; then
            notify-send -a wallpaper "wallpaper-set" "awww-daemon không phản hồi" 2>/dev/null || true
            exit 1
          fi
          sleep 0.25
        done

        # Đặt nền với transition fade 2s.
        ${pkgs.awww}/bin/awww img "$img" -t fade --transition-duration 2
        printf '%s\n' "$img" > "$CACHE"
      '';
    };

    ".local/bin/wallpaper-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # wallpaper-menu — rofi chọn ảnh nền trong ~/Pictures/wallpapers.
        set -u
        WALL_DIR="$HOME/Pictures/wallpapers"

        list="$(find "$WALL_DIR" -maxdepth 1 -xtype f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -printf '%f\n' | sort)"
        if [ -z "$list" ]; then
          notify-send -a wallpaper "wallpaper-menu" "Không có ảnh nào trong $WALL_DIR"
          exit 0
        fi

        choice="$(printf '%s\n' "$list" | rofi -dmenu -i -p '🖼️ Wallpaper' \
          -mesg 'Enter: đặt ảnh này')"
        [ -n "$choice" ] && exec "$HOME/.local/bin/wallpaper-set" "$WALL_DIR/$choice"
      '';
    };

    # ── Ảnh nền từ repo → ~/Pictures/wallpapers (symlink) ────────────────
    # day-* ban ngày (06:00–17:59), night-* ban đêm; cp thêm ảnh riêng với
    # tiền tố day-/night- là dùng ngay, không cần rebuild.
    "Pictures/wallpapers/day-anime_skyline.png".source = ./../wallpapers/day-anime_skyline.png;
    "Pictures/wallpapers/day-pastel-city.png".source = ./../wallpapers/day-pastel-city.png;
    "Pictures/wallpapers/day-japan_anime_city.jpg".source = ./../wallpapers/day-japan_anime_city.jpg;
    "Pictures/wallpapers/night-anime_cafe_tokyonight.png".source =
      ./../wallpapers/night-anime_cafe_tokyonight.png;
    "Pictures/wallpapers/night-wide_tokyonight_skyline.jpg".source =
      ./../wallpapers/night-wide_tokyonight_skyline.jpg;
    "Pictures/wallpapers/night-neocity2.jpg".source = ./../wallpapers/night-neocity2.jpg;
    "Pictures/wallpapers/night-neon-lights.jpg".source = ./../wallpapers/night-neon-lights.jpg;

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

        # Firmware UEFI: nội suy lúc BUILD từ pkgs.OVMF — offline, pin theo
        # flake.lock (trước đây gọi `nix eval nixpkgs#OVMF` lúc chạy, phụ thuộc
        # global registry & có thể phải tải mạng).
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

    ".local/bin/refresh-session" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        pkill wlsunset 2>/dev/null || true
        wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8 &
        # Wallpaper giữ nguyên khi reload (awww daemon vẫn hiển thị); sway
        # re-read include màu wallust → đồng bộ palette nếu thiếu.
        swaymsg reload
      '';
    };
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

    ".local/bin/sioyek-open" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Mở PDF qua sioyek; file đã mở ở workspace khác → kéo về (Wayland cấm
        # app tự focus, phải để sway kéo — cùng cơ chế dict-toggle).
        set -u
        JQ="${pkgs.jq}/bin/jq"
        SWAYMSG="${pkgs.sway}/bin/swaymsg"

        if [ $# -ge 1 ]; then
          base="$(basename -- "$1")"
          # jq/swaymsg absolute vì desktop entry chạy với PATH tối thiểu.
          cid="$($SWAYMSG -t get_tree | $JQ -r --arg b "$base" '
            [.. | objects
             | select(((.app_id? // "") == "sioyek")
                      or (((.window_properties.class? // "") | test("^sioyek$"; "i"))))
             | select((.name // "") | contains($b))
             | .id][0] // empty')"
          if [ -n "$cid" ]; then
            $SWAYMSG "[con_id=$cid] move container to workspace current"
            $SWAYMSG "[con_id=$cid] focus"
            exit 0
          fi
        fi

        exec ${pkgs.sioyek}/bin/sioyek "$@"
      '';
    };

    ".local/bin/sioyek" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Wrapper để gõ `sioyek` cũng qua sioyek-open (không đệ quy vì sioyek-open
        # gọi binary bằng đường dẫn absolute).
        exec "$HOME/.local/bin/sioyek-open" "$@"
      '';
    };

    ".local/bin/quick-lang" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Trợ lý dịch cho văn bản đang bôi (primary, fallback clipboard).
        # vi-en (mặc định) / en-vi / fix. Tag [xxx] đầu văn bản = ngữ cảnh;
        # key ở ~/.config/quick-lang/api.key; hết quota → fallback Google Translate.
        set -u

        mode="''${1:-vi-en}"
        FALLBACK_GT=0

        # -p = print-id để dismiss thông báo cũ; dịch mới đè thông báo cũ.
        # ID lưu trong tmpfs ($XDG_RUNTIME_DIR).
        NTF_ID_FILE="''${XDG_RUNTIME_DIR:-/tmp}/quick-lang-notify-id"
        ntf() {
          old_id="$(cat "$NTF_ID_FILE" 2>/dev/null || true)"
          if [ -n "$old_id" ]; then
            makoctl dismiss -n "$old_id" 2>/dev/null || true
            sleep 0.1
          fi
          printf %s "$(notify-send -a quick-lang -p "$@")" > "$NTF_ID_FILE"
        }

        # Ưu tiên selection đang bôi, fallback clipboard.
        text="$(wl-paste -p 2>/dev/null || true)"
        [ -n "''${text//[[:space:]]/}" ] || text="$(wl-paste 2>/dev/null || true)"
        [ -n "''${text//[[:space:]]/}" ] || {
          ntf "Quick Lang" "Không có văn bản nào được chọn hoặc copy."
          exit 1
        }

        # Tag [xxx] đầu văn bản; tag bị cắt trước khi gửi.
        CTX_LABEL=""
        CTX_RULE="Infer the domain and register from the text itself, then write the way an educated native speaker in that domain would naturally write."
        if [[ $text =~ ^\[[[:space:]]*([A-Za-z]+)[[:space:]]*\] ]]; then
          tag="''${BASH_REMATCH[1],,}"
          text="''${text#*\]}"
          text="''${text#"''${text%%[![:space:]]*}"}"
          case "$tag" in
            phi) CTX_LABEL="phi"; CTX_RULE="Register: philosophical writing. Use precise abstract terminology, preserve hedging (perhaps, seems, may), and phrase it the way a careful philosopher would." ;;
            sci) CTX_LABEL="sci"; CTX_RULE="Register: academic/scientific writing. Formal and precise, with standard scientific hedging (suggest, indicate) and academic conventions." ;;
            lit) CTX_LABEL="lit"; CTX_RULE="Register: literary prose. Preserve imagery, voice, rhythm and figurative language; favor evocative, idiomatic phrasing over literal accuracy." ;;
            cas) CTX_LABEL="cas"; CTX_RULE="Register: casual natural conversation, the way a native speaker chats informally." ;;
            *)   CTX_LABEL="$tag"; CTX_RULE="Domain: $tag. Write it the way an expert in this field would naturally express the idea." ;;
          esac
        fi

        # Prompt theo mode (vi-en hợp nhất VI/EN/trộn; EN thuần chỉ sửa lỗi thật).
        case "$mode" in
          vi-en)
            rule="Convert the text below into polished, natural English. The text may be entirely Vietnamese (with or without diacritics), entirely English, or a mix of both. If it contains any Vietnamese, translate it and render the whole meaning as one coherent English text, integrating any already-English parts naturally. If it is entirely English, proofread it: when it is already correct and natural, output it EXACTLY unchanged; when it has real errors (grammar, word choice, collocation), output only the corrected text. $CTX_RULE Preserve the full meaning and tone of the original. Keep proper nouns and technical terms. Output ONLY the resulting English text, with no explanations or notes."
            gt_tl="en" ;;
          en-vi)
            rule="Convert the text below into natural Vietnamese with correct diacritics. The text may be entirely English, entirely Vietnamese, or a mix of both; render the whole meaning as one coherent Vietnamese text, integrating all parts naturally. $CTX_RULE Preserve the full meaning and tone of the original. Keep proper nouns and technical terms. Output ONLY the resulting Vietnamese text, with no explanations or notes."
            gt_tl="vi" ;;
          fix)
            rule="The text below is English written by a learner. Proofread it. If it is already correct and natural, output it EXACTLY unchanged. If it has real errors (grammar, word choice, collocation, unnatural phrasing), output only the corrected version, changing as little as possible. $CTX_RULE Preserve the author's meaning and voice. Keep proper nouns and technical terms. Output ONLY the resulting text, with no explanations or notes."
            gt_tl="" ;;
          *) ntf "Quick Lang" "Mode không hợp lệ: $mode (dùng vi-en | en-vi | fix)"; exit 1 ;;
        esac

        # Gemini: chỉ retry lỗi mạng/5xx; 429 (hết quota) báo ngay không retry.
        translate_ai() {
          # vi-en/en-vi → flash-lite (nhanh, quota lớn); fix → flash (chuẩn hơn).
          case "$mode" in
            vi-en|en-vi) MODEL="gemini-flash-lite-latest" ;;
            *)           MODEL="gemini-flash-latest" ;;
          esac

          API_KEY="''${GEMINI_API_KEY:-}"
          if [ -z "$API_KEY" ] && [ -r "''${XDG_CONFIG_HOME:-$HOME/.config}/quick-lang/api.key" ]; then
            API_KEY="$(cat "''${XDG_CONFIG_HOME:-$HOME/.config}/quick-lang/api.key" 2>/dev/null | tr -d '[:space:]')"
          fi
          if [ -z "$API_KEY" ]; then
            ntf -u critical "Quick Lang" "Chưa có API key. Ghi key vào ~/.config/quick-lang/api.key hoặc đặt biến GEMINI_API_KEY."
            exit 1
          fi

          prompt="$(printf '%s\n\nText:\n%s' "$rule" "$text")"
          resp_file="''${XDG_RUNTIME_DIR:-/tmp}/quick-lang-resp.$$"
          http_code=""
          for attempt in 1 2 3; do
            http_code="$(timeout 40 curl -sS \
              --connect-timeout 5 --max-time 35 \
              -H "Content-Type: application/json" \
              -d "$(jq -n --arg p "$prompt" '{contents:[{parts:[{text:$p}]}], generationConfig:{temperature:0.2}}')" \
              -o "$resp_file" -w '%{http_code}' \
              "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY" 2>/dev/null || true)"
            case "$http_code" in
              000|"") [ "$attempt" -lt 3 ] && sleep 1; continue ;;  # lỗi mạng → thử lại
              5*)     [ "$attempt" -lt 3 ] && sleep 1; continue ;;  # lỗi server tạm thời → thử lại
            esac
            break  # 2xx / 4xx (gồm 429) → xử lý bên dưới
          done
          response="$(cat "$resp_file" 2>/dev/null || true)"
          rm -f "$resp_file"

          result="$(printf '%s' "$response" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null || true)"
          # Bỏ markdown fence nếu model tự bọc.
          result="$(printf '%s' "$result" | sed -e 's/^```[a-zA-Z]*//' -e 's/```$//' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

          if [ -z "''${result//[[:space:]]/}" ]; then
            # 429 ở mode có chiều dịch → cờ fallback Google Translate.
            if [ "$http_code" = 429 ] && [ -n "$gt_tl" ]; then
              FALLBACK_GT=1
              return
            fi
            case "$http_code" in
              200)          msg="API trả về phản hồi rỗng, thử lại." ;;
              429)          msg="Gemini hết quota free tier (HTTP 429). Chờ ~1 phút rồi thử lại." ;;
              400|401|403)  msg="API key sai hoặc bị từ chối (HTTP ''${http_code})." ;;
              5*)           msg="Lỗi phía Google API (HTTP ''${http_code}), thử lại sau." ;;
              *)            msg="Mạng/DNS không truy cập được Google API. Bấm Super+Shift+r để reload mạng rồi thử lại." ;;
            esac
            ntf -u critical "Quick Lang" "$msg"
            exit 1
          fi
        }

        # Google Translate làm fallback khi Gemini 429 (nhanh, không cần key).
        # sl=auto tự nhận nguồn; response có 2 dạng — jq xử lý cả hai.
        translate_gt() {
          q="$(jq -rn --arg q "$text" '$q|@uri')"
          result=""
          for attempt in 1 2; do
            response="$(curl -sS --connect-timeout 5 --max-time 15 \
              -A 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36' \
              "https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=auto&tl=$gt_tl&q=$q" 2>/dev/null || true)"
            result="$(printf '%s' "$response" | jq -r 'if (.[0]|type)=="string" then map(select(type=="string"))|join("") else map(.[0] // "")|join("") end' 2>/dev/null || true)"
            [ -n "''${result//[[:space:]]/}" ] && break
            sleep 1
          done

          if [ -z "''${result//[[:space:]]/}" ]; then
            ntf -u critical "Quick Lang · GT" "Dịch thất bại — kiểm tra kết nối mạng (hoặc bấm Super+Shift+r để reload mạng)."
            exit 1
          fi
        }

        translate_ai

        if [ "''${FALLBACK_GT:-0}" = 1 ]; then
          ntf "Quick Lang · GT" "Gemini hết quota (429) → dùng Google Translate."
          translate_gt
        fi

        printf %s "$result" | wl-copy

        # So sánh đầu ra với đầu vào: nguyên văn = đã tự nhiên, khác = đã sửa.
        case "$mode" in
          vi-en)
            if [ "$result" = "$text" ]; then title="✓ EN đã tự nhiên"; else title="→ EN"; fi ;;
          fix)
            if [ "$result" = "$text" ]; then title="✓ EN đã tự nhiên"; else title="✍️ EN đã sửa"; fi ;;
          en-vi) title="→ VI" ;;
        esac
        [ -n "$CTX_LABEL" ] && title="$title · $CTX_LABEL"

        ntf "$title" "$result"
      '';
    };

    ".local/bin/quick-net-reload" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Reload mạng nhanh: tắt/bật NetworkManager (renew DHCP + DNS).
        # Không cần sudo (polkit cho user local). Dùng khi mạng "đứng hình".
        set -u

        notify() {
          notify-send -a quick-net-reload -i network-wireless -t 3000 "Reload mạng" "$@"
        }

        # Xoá cache DNS (best-effort).
        resolvectl flush-caches >/dev/null 2>&1 || true

        if ! nmcli networking off; then
          notify -u critical "Không tắt được mạng — kiểm tra quyền user/polkit."
          exit 1
        fi
        if ! nmcli networking on; then
          notify -u critical "Không bật lại được mạng — kiểm tra quyền user/polkit."
          exit 1
        fi

        # Chờ kết nối trở lại (tối đa ~10s).
        state=""
        for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
          state="$(nmcli -t -f STATE,CONNECTIVITY general status 2>/dev/null | cut -d: -f2)"
          [ "$state" = "full" ] && break
          sleep 0.5
        done

        if [ "$state" = "full" ]; then
          notify "Đã bật lại mạng — kết nối full."
        else
          notify -u critical "Đã bật lại mạng nhưng chưa kết nối được — kiểm tra wifi."
          exit 1
        fi
      '';
    };

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

    ".local/bin/toggle-wlsunset" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Vòng lặp: Tự động → Vàng 4000K → Trắng 6500K → Tự động.
        # Query process thực (state file có thể lệch sau restart).

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

        # flock để bấm phím liên tục không đè thông báo nhau.
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

    ".local/bin/power-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
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
        # Kiểm tra exit slurp để hủy không báo sai.
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

  # Daemon awww (fork của swww) — PartOf sway-session để dừng theo phiên
  # (đúng mẫu swayidle). wallpaper-set tự chờ daemon sẵn sàng.
  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww wallpaper daemon (fork của swww)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };

  # Chạy wallpaper-set lúc 6:00 (pool day-) và 18:00 (pool night-).
  systemd.user.services.cycle-wallpaper = {
    Unit = {
      Description = "Random wallpaper theo giờ + palette wallust";
    };
    Service = {
      Type = "oneshot";
      # PATH cho lệnh con của script (find, date, sleep, notify-send...).
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/doxuantuyen/bin:%h/.local/bin"
      ];
      ExecStart = "%h/.local/bin/wallpaper-set";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.timers.cycle-wallpaper = {
    Unit = {
      Description = "Run wallpaper-set at 6:00 and 18:00";
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
