{ pkgs, ... }:

{
  services.mako = {
    enable = true;

    settings = {
      icon-path = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";
      icons = 1;
      max-icon-size = 33;
      icon-location = "left";
      # Popup 350px wide, max 600px tall so long content is not cut off.
      margin = "35,20,20,20";
      width = 350;
      height = 600;
      default-timeout = 5000;
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#89b4fa";
      border-radius = 8;
      # Per-app timeouts.
      # Translation auto-dismisses after ~2 min; left click dismisses early.
      "app-name=quick-lang".default-timeout = 120000;
      "app-name=quick-lang".border-color = "#cba6f7";
      # Left click dismisses the translation notification.
      "app-name=quick-lang".on-button-left = "dismiss";
      "app-name=volume".default-timeout = 2000;
      "app-name=brightness".default-timeout = 2000;
      "app-name=wlsunset".default-timeout = 2000;
      "app-name=power-profiles".default-timeout = 2000;
      "app-name=toggle-touchpad".default-timeout = 2000;
      # Countdown: border matches the Waybar clock color.
      "app-name=countdown".border-color = "#89b4fa";
      "app-name=countdown".default-timeout = 5000;
      "app-name=screenshot".default-timeout = 2000;
      "app-name=power".default-timeout = 2000;
    };
  };
}
