{ pkgs, ... }:

let
  trashCleaner = pkgs.writeShellApplication {
    name = "thunar-trash-cleaner";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnused
    ];
    text = ''
      set -euo pipefail

      trash_root="''${XDG_DATA_HOME:-$HOME/.local/share}/Trash"
      files_dir="$trash_root/files"
      info_dir="$trash_root/info"

      # Thunar/GIO ghi thời điểm xóa vào .trashinfo. Dùng mối tuổi của
      # metadata để không phụ thuộc mtime của file/thư mục bên trong.
      [ -d "$files_dir" ] || exit 0
      [ -d "$info_dir" ] || exit 0

      # Đọc DeletionDate chuẩn của GIO; bỏ qua metadata dị dạng để không xóa nhầm.
      # 30 ngày = 2.592.000 giây; chỉ xử lý metadata có trong Trash.
      while IFS= read -r -d $'\0' info; do
        deletion_date="$(sed -n 's/^DeletionDate=//p' "$info")"
        deletion_epoch="$(date -d "$deletion_date" +%s 2>/dev/null || true)"
        [ -n "$deletion_epoch" ] || continue

        now="$(date +%s)"
        if [ $((now - deletion_epoch)) -le $((30 * 24 * 60 * 60)) ]; then
          continue
        fi

        name="''${info##*/}"
        name="''${name%.trashinfo}"
        target="$files_dir/$name"

        if [ -e "$target" ] || [ -L "$target" ]; then
          rm -rf -- "$target"
        fi
        rm -f -- "$info"
      done < <(find "$info_dir" -maxdepth 1 -type f -name '*.trashinfo' -print0)
    '';
  };
in

# Đăng ký Alacritty làm terminal mặc định cho Thunar + entry Neovim mở trong
# Alacritty. Thunar dùng GIO; thùng rác cục bộ không phụ thuộc daemon GVFS.
{
  # Dọn Thùng rác tự động sau 30 ngày lúc 03:00. Nếu máy đang tắt hoặc
  # chưa đăng nhập, Persistent sẽ chạy bù ngay khi người dùng đăng nhập lại.
  # Script chỉ xóa mục có DeletionDate hợp lệ trong .trashinfo, nên an toàn hơn
  # việc dựa vào mtime của file.
  systemd.user.services.trash-cleaner = {
    Unit = {
      Description = "Remove Thunar trash items older than 30 days";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${trashCleaner}/bin/thunar-trash-cleaner";
    };
  };

  systemd.user.timers.trash-cleaner = {
    Unit = {
      Description = "Daily Thunar trash cleanup";
    };
    Timer = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
  # libexo dùng Alacritty làm terminal.
  xdg.configFile."xfce4/helpers.rc" = {
    text = ''
      TerminalEmulator=alacritty
    '';
  };

  # Entry Neovim mở trực tiếp trong Alacritty (không qua exo helper).
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    comment = "Open in neovim inside alacritty";
    icon = "nvim";
    exec = "alacritty -e nvim %F";
    terminal = false;
    type = "Application";
    categories = [
      "Utility"
      "TextEditor"
      "Development"
    ];
    mimeType = [
      "text/plain"
      "text/x-makefile"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-csrc"
      "text/x-java"
      "text/x-moc"
      "text/x-pascal"
      "text/x-tcl"
      "text/x-tex"
      "application/x-shellscript"
      "text/x-c"
      "text/x-c++"
    ];
  };

  # Mở text/plain bằng entry Neovim trên.
  xdg.mimeApps.defaultApplications."text/plain" = [ "nvim.desktop" ];
}
