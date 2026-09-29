{ ... }:

{
  home.file = {
    ".local/bin/sioyek" = {
      executable = true;
      text = ''
          #! /usr/bin/env bash
          # Wrapper để gõ `sioyek` cũng qua sioyek-open (không đệ quy vì sioyek-open
          # gọi binary bằng đường dẫn absolute).
          exec "$HOME/.local/bin/sioyek-open" "$@"
      '';
    };
  };
}
