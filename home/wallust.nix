{ pkgs, config, ... }:

# Wallpaper engine: awww (fork mới của swww — swww đã archive 10/2025) + wallust.
# - awww-daemon  : systemd user service, đổi nền bằng transition hoạt ảnh.
# - wallpaper-set: chọn ảnh random day-/night- trong ~/Pictures/wallpapers
#                  → awww img (fade) → wallust sinh palette màu theo ảnh.
# - Palette được templating sang: alacritty, waybar, rofi, sway client colors.
# Các file màu sinh ra nằm NGOÀI tầm quản lý của home-manager (wallust ghi
# thường xuyên): ~/.config/wallust/colors/*, ~/.config/waybar/colors.css,
# ~/.config/rofi/themes/wallust.rasi. Hai file rofi/sway được seed sẵn Tokyo
# Night (activation dưới đây) để rofi/sway không lỗi khi chưa chạy lần đầu.
{
  programs.wallust = {
    enable = true;
    settings = {
      # Palette tối mềm — hợp rice Tokyo Night, ổn với cả ảnh sáng lẫn tối.
      palette = "softdark16";
      templates = {
        # Đường dẫn tương đối với ~/.config/wallust/templates/ (wallust 3.5
        # tự thêm prefix đó — không viết "templates/..." ở đây).
        alacritty = {
          template = "alacritty.toml";
          target = "~/.config/wallust/colors/alacritty.toml";
        };
        waybar = {
          template = "waybar.css";
          target = "~/.config/waybar/colors.css";
        };
        rofi = {
          template = "rofi.rasi";
          target = "~/.config/rofi/themes/wallust.rasi";
        };
        sway = {
          template = "sway.conf";
          target = "~/.config/wallust/colors/sway.conf";
        };
      };
    };
  };

  home.file = {
    # ── Templates wallust ────────────────────────────────────────────────
    # Biến {{background}}, {{foreground}}, {{color0..15}} do wallust thay.
    ".config/wallust/templates/alacritty.toml".text = ''
      # Sinh tự động bởi wallust từ wallpaper — KHÔNG sửa tay (sẽ bị ghi đè).
      [colors.primary]
      background = "{{background}}"
      foreground = "{{foreground}}"

      [colors.cursor]
      text = "{{background}}"
      cursor = "{{cursor}}"

      [colors.vi_mode_cursor]
      text = "{{background}}"
      cursor = "{{color6}}"

      [colors.selection]
      text = "{{foreground}}"
      background = "{{color8}}"

      [colors.search.matches]
      foreground = "{{background}}"
      background = "{{color3}}"

      [colors.search.focused_match]
      foreground = "{{background}}"
      background = "{{color2}}"

      [colors.normal]
      black = "{{color0}}"
      red = "{{color1}}"
      green = "{{color2}}"
      yellow = "{{color3}}"
      blue = "{{color4}}"
      magenta = "{{color5}}"
      cyan = "{{color6}}"
      white = "{{color7}}"

      [colors.bright]
      black = "{{color8}}"
      red = "{{color9}}"
      green = "{{color10}}"
      yellow = "{{color11}}"
      blue = "{{color12}}"
      magenta = "{{color13}}"
      cyan = "{{color14}}"
      white = "{{color15}}"
    '';

    ".config/wallust/templates/waybar.css".text = ''
      /* Palette wallust sinh từ wallpaper — KHÔNG sửa tay (sẽ bị ghi đè). */
      @define-color wbg {{background}};
      @define-color wbg2 {{color0}};
      @define-color wfg {{foreground}};
      @define-color wtxt2 {{color7}};
      @define-color wdim {{color8}};
      @define-color wac {{color4}};
      @define-color wred {{color1}};
      @define-color wgrn {{color2}};
      @define-color wylw {{color3}};
    '';

    ".config/wallust/templates/sway.conf".text = ''
      # Palette wallust sinh từ wallpaper — KHÔNG sửa tay (sẽ bị ghi đè).
      client.focused          {{color4}} {{color1}} {{foreground}} {{color5}} {{color4}}
      client.focused_inactive {{color8}} {{background}} {{foreground}} {{color8}} {{color8}}
      client.unfocused        {{color8}} {{background}} {{color8}} {{color8}} {{color8}}
      client.urgent           {{color1}} {{background}} {{color1}} {{color8}} {{color1}}
      client.background       {{background}}
    '';

    # Rofi theme theo wallpaper + config nhẹ cho các menu rofi -dmenu hiện có
    # (power-menu, pomodoro-menu, wallpaper-menu, screenshot-menu...).
    ".config/wallust/templates/rofi.rasi".text = ''
      /* Palette wallust sinh từ wallpaper — KHÔNG sửa tay (sẽ bị ghi đè). */
      * {
          bg:  {{background}};
          bg2: {{color8}};
          fg:  {{foreground}};
          ac:  {{color4}};
          red: {{color1}};
      }
      window {
          background-color: @bg;
          border: 2px; border-color: @ac; border-radius: 12px;
      }
      inputbar {
          children: [prompt, entry];
          background-color: @bg2;
          border-radius: 8px;
          margin: 10px 10px 4px 10px;
          padding: 10px 14px;
      }
      prompt { text-color: @ac; }
      entry {
          text-color: @fg;
          placeholder: "Type to filter…";
          placeholder-color: @bg2;
      }
      listview {
          lines: 8; fixed-height: false; scrollbar: false;
          margin: 4px 10px 10px 10px;
      }
      element {
          padding: 8px 12px; border-radius: 8px;
          text-color: @fg; background-color: transparent;
      }
      element selected.normal {
          background-color: @bg2; text-color: @ac;
      }
      element-text { text-color: inherit; }
      element-icon { size: 24px; }
      textbox { text-color: @fg; }
    '';

    ".config/rofi/config.rasi".text = ''
      /* Config chung cho mọi menu rofi của hệ (dmenu + drun/window).
         Màu lấy từ theme wallust — sinh lại mỗi lần đổi wallpaper. */
      configuration {
          modi: "drun,window";
          show-icons: true;
          icon-theme: "Papirus-Dark";
          display-drun: " Apps";
          display-window: " Windows";
          drun-display-format: "{name}";
          font: "JetBrainsMono Nerd Font 11";
      }
      @theme "wallust"
    '';

    # ── Ảnh nền mặc định từ repo → ~/Pictures/wallpapers ─────────────────
    # day-* dùng ban ngày (06:00–17:59), night-* ban đêm; cp thêm ảnh riêng
    # vào ~/Pictures/wallpapers với đúng tiền tố là được (không cần rebuild).
    "Pictures/wallpapers/day-anime_skyline.png".source = ./../wallpapers/day-anime_skyline.png;
    "Pictures/wallpapers/day-pastel-city.png".source = ./../wallpapers/day-pastel-city.png;
    "Pictures/wallpapers/day-japan_anime_city.jpg".source = ./../wallpapers/day-japan_anime_city.jpg;
    "Pictures/wallpapers/night-anime_cafe_tokyonight.png".source =
      ./../wallpapers/night-anime_cafe_tokyonight.png;
    "Pictures/wallpapers/night-wide_tokyonight_skyline.jpg".source =
      ./../wallpapers/night-wide_tokyonight_skyline.jpg;
    "Pictures/wallpapers/night-neocity2.jpg".source = ./../wallpapers/night-neocity2.jpg;
    "Pictures/wallpapers/night-neon-lights.jpg".source = ./../wallpapers/night-neon-lights.jpg;
  };

  # Seed file LẦN ĐẦU nếu chưa có: rofi @theme "wallust" và sway include
  # không chịu được file thiếu → cần file thật (wallust ghi đè thường xuyên,
  # không thể là symlink store của HM). Sau lần seed, file thuộc về wallust.
  home.activation.seedWallustTargets = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    rofiSeed="${pkgs.writeText "rofi-wallust-seed.rasi" ''
      /* Seed Tokyo Night — bị wallust ghi đè ngay lần chạy wallpaper-set đầu. */
      * {
          bg:  #1a1b26;
          bg2: #292e42;
          fg:  #c0caf5;
          ac:  #7aa2f7;
          red: #f7768e;
      }
      window { background-color: @bg; border: 2px; border-color: @ac; border-radius: 12px; }
      inputbar {
          children: [prompt, entry];
          background-color: @bg2;
          border-radius: 8px;
          margin: 10px 10px 4px 10px;
          padding: 10px 14px;
      }
      prompt { text-color: @ac; }
      entry { text-color: @fg; }
      listview { lines: 8; fixed-height: false; scrollbar: false; margin: 4px 10px 10px 10px; }
      element { padding: 8px 12px; border-radius: 8px; text-color: @fg; background-color: transparent; }
      element selected.normal { background-color: @bg2; text-color: @ac; }
      element-text { text-color: inherit; }
      element-icon { size: 24px; }
      textbox { text-color: @fg; }
    ''}"
    swaySeed="${pkgs.writeText "sway-wallust-seed.conf" ''
      # Seed Tokyo Night — bị wallust ghi đè ngay lần chạy wallpaper-set đầu.
      client.focused          #7aa2f7 #364a82 #c0caf5 #bb9af7 #7aa2f7
      client.focused_inactive #a9b1d6 #1a1b26 #c0caf5 #a9b1d6 #a9b1d6
      client.unfocused        #414868 #1a1b26 #565f89 #414868 #414868
      client.urgent           #ff9e64 #1a1b26 #ff9e64 #565f89 #ff9e64
      client.background       #1a1b26
    ''}"
    $DRY_RUN_CMD mkdir -p "$HOME/.config/rofi/themes" "$HOME/.config/wallust/colors"
    if [ ! -f "$HOME/.config/rofi/themes/wallust.rasi" ]; then
      $DRY_RUN_CMD install -m 644 "$rofiSeed" "$HOME/.config/rofi/themes/wallust.rasi"
    fi
    if [ ! -f "$HOME/.config/wallust/colors/sway.conf" ]; then
      $DRY_RUN_CMD install -m 644 "$swaySeed" "$HOME/.config/wallust/colors/sway.conf"
    fi
  '';

  # Daemon awww — PartOf sway-session để dừng theo phiên (đúng mẫu swayidle).
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
}
