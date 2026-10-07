{ ... }:

{
  home.file = {
    ".local/bin/sioyek" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Wrapper so typing `sioyek` also goes through sioyek-open (no recursion
        # because sioyek-open invokes the binary by absolute path).
        exec "$HOME/.local/bin/sioyek-open" "$@"
      '';
    };
  };
}
