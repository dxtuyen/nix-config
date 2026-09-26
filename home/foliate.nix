# Foliate — trình đọc sách điện tử (epub / mobi / azw3 / fb2 / cbz / opds).
# Gói cài ở `home/packages.nix`, app mặc định khai ở `home/mimeapps.nix`.
#
# ⚠️ `dconf.settings` CHỈ nhận đúng 2 cấp: `attrsOf (attrsOf gvariant)`.
# Nên phải ghi key là ĐƯỜNG DẪN PHẲNG tới tận key cuối, không lồng nhau —
# lồng 3 cấp sẽ báo "not of type 'GVariant value'" lúc eval.
{ lib, ... }:
{
  dconf.settings = {
    # ── Trang đọc ────────────────────────────────────────────────────────────
    # GSettings path: /com/github/johnfactotum/Foliate/viewer/view/<key>
    "com/github/johnfactotum/Foliate/viewer/view" = {
      # Căn đều 2 mép — chỉ đẹp khi có `hyphenate` bên dưới.
      justify = true;
      # Tự ngắt từ. ⚠️ KHÔNG chỉ cài `hyphenDicts` trong home là đủ:
      # WebKitGTK hardcode đường dẫn /usr/share/hyphen (đã kiểm tra bằng
      # `strings` trên libwebkitgtk-6.0.so.4) — phải symlink ở tầng NixOS,
      # xem `modules/nixos/desktop.nix`.
      hyphenate = true;
      # 1.5 là default của foliate, khai lại để rõ ý định.
      # Kiểu GVariant `d` (double) → số thực trong Nix (có dấu chấm).
      line-height = 1.5;
      # 680px @ 18px ≈ 65–70 ký tự/dòng. Mặc định 720px hơi rộng, mắt dễ
      # lạc khi quét dòng dài.
      #
      # ⚠️ Schema khai kiểu `u` (uint32), KHÔNG phải `i` (int32). Nếu để số Nix
      # thuần, Home-Manager ghi thành `@i` → GSettings từ chối nạp key này
      # (âm thầm mất setting). Phải bọc `mkUint32`.
      max-inline-size = lib.hm.gvariant.mkUint32 680;
      # Ép font hệ thống thay vì font lạ nhúng trong sách — nhiều EPUB bán
      # kèm font rác (chữ sáng mờ, khoảng cách kỳ) → đọc rất mệt.
      # Các font này đã có ở `modules/nixos/desktop.nix` (noto-fonts).
      override-font = true;
      # File JSON tự tạo bên dưới (foliate không có sẵn theme này).
      theme = "tokyo-night.json";
    };

    # ── Chữ ─────────────────────────────────────────────────────────────────
    # GSettings path: /com/github/johnfactotum/Foliate/viewer/font/<key>
    "com/github/johnfactotum/Foliate/viewer/font" = {
      # Kiểu `u` (uint32) → mkUint32, lý do như trên.
      default-size = lib.hm.gvariant.mkUint32 18;
      serif = "Noto Serif";
      sans-serif = "Noto Sans";
      monospace = "JetBrains Mono";
    };
  };

  # Theme tự tạo khớp Tokyonight (các app khác cũng dùng theme này).
  # Foliate quét `pkg.configpath('themes')` = ~/.config/com.github.johnfactotum.Foliate/themes
  # rồi nạp mọi file `.json`; `label` là tên hiện trong menu.
  # ⚠️ `viewer/view/theme` phải trỏ đúng TÊN FILE, kể cả đuôi `.json`.
  xdg.configFile."com.github.johnfactotum.Foliate/themes/tokyo-night.json".text = ''
    {
      "label": "Tokyo Night",
      "light": {
        "fg": "#3760bf",
        "bg": "#e1e2e7",
        "link": "#2e7de9"
      },
      "dark": {
        "fg": "#c0caf5",
        "bg": "#1a1b26",
        "link": "#7aa2f7"
      }
    }
  '';
}
