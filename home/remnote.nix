{ pkgs, config, ... }:

{
  xdg.enable = true;

  home.packages = with pkgs; [
    appimage-run
  ];

  xdg.desktopEntries.remnote = {
    name = "RemNote";
    comment = "RemNote note-taking app";
    exec = "appimage-run ${config.home.homeDirectory}/Apps/RemNote/RemNote.AppImage";
    terminal = false;
    type = "Application";
    categories = [ "Office" "Utility" ];
  };

  home.file.".local/bin/update-remnote" = {
    executable = true;
    text = ''
      #! /usr/bin/env bash
      set -euo pipefail

      downloads="''${HOME}/Downloads"
      apps_dir="''${HOME}/Apps/RemNote"
      target="''${apps_dir}/RemNote.AppImage"
      url="https://backend.remnote.com/desktop/linux"

      mkdir -p "$apps_dir"

      install_file() {
        local src="$1"
        if [ -f "$target" ]; then
          local hashes
          hashes="$(sha256sum "$src" "$target" | awk '{print $1}' | sort -u | wc -l)"
          if [ "$hashes" -eq 1 ]; then
            rm -f "$src"
            echo "RemNote đã là phiên bản mới nhất, không cần cập nhật."
            exit 0
          fi
        fi
        mv -f "$src" "$target"
        chmod +x "$target"
        echo "Đã cập nhật RemNote: $target"
      }

      latest="$(find "$downloads" -maxdepth 1 -name 'RemNote-*.AppImage' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)"
      if [ -n "$latest" ]; then
        install_file "$latest"
        exit 0
      fi

      tmp="''${apps_dir}/.RemNote.AppImage.download"
      echo "Không tìm thấy file trong ''${downloads}, đang tải từ ''${url} ..."
      if ! curl -fL --retry 2 -o "$tmp" "$url"; then
        rm -f "$tmp"
        echo "Lỗi: Không có mạng hoặc tải thất bại." >&2
        echo "Nếu link tải đã đổi, hãy tải tay file RemNote-*.AppImage về ''${downloads} rồi chạy lại lệnh này." >&2
        exit 1
      fi
      install_file "$tmp"
    '';
  };
}