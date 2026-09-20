{ pkgs, ... }:

{
  services.mako = {
    enable = true;

    settings = {
      icon-path = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";
      icons = 1;
      max-icon-size = 33;
      icon-location = "left";
      # Popup rộng 350px, cao tối đa 600px để nội dung dài không bị cắt.
      margin = "35,20,20,20";
      width = 350;
      height = 600;
      default-timeout = 5000;
      background-color = "#1a1b26";
      text-color = "#c0caf5";
      border-color = "#7aa2f7";
      border-radius = 8;
      # timeout riêng từng app.
      # Dịch tự tắt sau ~2 phút; bấm trái tắt sớm.
      "app-name=quick-lang".default-timeout = 120000;
      "app-name=quick-lang".border-color = "#bb9af7";
      # Click trái tắt thông báo dịch.
      "app-name=quick-lang".on-button-left = "dismiss";
      "app-name=volume".default-timeout = 2000;
      "app-name=brightness".default-timeout = 2000;
      "app-name=wlsunset".default-timeout = 2000;
      "app-name=power-profiles".default-timeout = 2000;
      "app-name=toggle-touchpad".default-timeout = 2000;
      # Focus: viền theo màu đồng hồ Waybar.
      "app-name=focus".border-color = "#7aa2f7";
      "app-name=focus".default-timeout = 5000;
      "app-name=screenshot".default-timeout = 2000;
      "app-name=power".default-timeout = 2000;
    };
  };
}
