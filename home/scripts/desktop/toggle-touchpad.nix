{ ... }:

{
  home.file = {
    ".local/bin/toggle-touchpad" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Always read the real state from Sway, never trust an old state file.
        current="$(swaymsg -t get_inputs 2>/dev/null | jq -r '[.[] | select(.type == "touchpad") | .libinput.send_events][0] // empty' 2>/dev/null)"
        [ -n "$current" ] || current="unknown"

        # Re-apply the whole touchpad config (matches sway.nix) so it takes effect immediately.
        apply_touchpad_config() {
          swaymsg input type:touchpad pointer_accel 0.6
          swaymsg input type:touchpad accel_profile adaptive
          swaymsg input type:touchpad natural_scroll enabled
          swaymsg input type:touchpad scroll_method two_finger
          swaymsg input type:touchpad tap enabled
          swaymsg input type:touchpad drag enabled
          swaymsg input type:touchpad dwt enabled
          # events enabled comes last (turn on after everything else is ready).
          swaymsg input type:touchpad events enabled
        }

        case "$current" in
          enabled|disabled_on_external_mouse)
            swaymsg input type:touchpad events disabled
            label="Touchpad off"
            icon="input-touchpad"
            ;;
          disabled)
            apply_touchpad_config
            label="Touchpad on"
            icon="input-touchpad"
            ;;
          *)
            notify-send -a toggle-touchpad -i input-touchpad -t 3000 "Touchpad" \
              "Could not read touchpad state from Sway: $current" 2>/dev/null || true
            exit 1
            ;;
        esac

        notify-send -a toggle-touchpad -i "$icon" -t 2000 "Touchpad" "$label"
      '';
    };
  };
}
