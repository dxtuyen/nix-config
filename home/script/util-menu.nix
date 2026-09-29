{ ... }:

{
  home.file = {
    ".local/bin/util-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        set -u

        inhibit_state="$(~/.local/bin/study inhibit-state)"
        read -r inhibit_class inhibit_manual <<< "$inhibit_state"

        case "$inhibit_class:$inhibit_manual" in
          running:true)
            inhibit_row="● Idle: ON (Focus + manual) → Focus only"
            ;;
          running:*)
            inhibit_row="● Idle: ON (Focus) → Add manual"
            ;;
          manual:true)
            inhibit_row="● Idle: ON (manual) → OFF"
            ;;
          *)
            inhibit_row="● Idle: OFF → ON (manual)"
            ;;
        esac

        MENU="$inhibit_row
        ☀ Display  →
        ⚡ Power Profile  →"

        choice=$(printf '%s\n' "$MENU" | rofi -dmenu -i -matching fuzzy -p "Utilities" \
          -mesg "Type to filter · Enter to select")

        case "$choice" in
          "● Idle:"*) exec ~/.local/bin/study inhibit-toggle ;;
          "☀ Display"*) exec ~/.local/bin/wlsunset-menu ;;
          "⚡ Power Profile"*) exec ~/.local/bin/power-profile-menu ;;
        esac
      '';
    };
  };
}
