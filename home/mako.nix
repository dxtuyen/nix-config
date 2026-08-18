{ pkgs, ... }:

{
  services.mako = {
    enable = true;

    settings = {
      icon-path = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";
      icons = 1;
      max-icon-size = 33;
      icon-location = "left";
      # width 400 rộng hơn gốc (300) để hiện nhiều chữ mỗi dòng.
      # height 600 cho phép nội dung dài hiện gần trọn vẹn
      # (Mako không có tính năng hover-mở rộng, nên cần height đủ lớn
      #  để tránh cắt nội dung; 600px chiếm ~58% chiều cao màn hình 1080p).
      margin = "35,20,20,20";
      width = 350;
      height = 600;
      default-timeout = 5000;
      background-color = "#1a1b26";
      text-color = "#c0caf5";
      border-color = "#7aa2f7";
      border-radius = 8;
      "app-name=quick-lang".default-timeout = 10000;
      "app-name=quick-lang".background-color = "#1a1b26";
      "app-name=quick-lang".border-color = "#bb9af7";
      "app-name=volume".default-timeout = 2000;
      "app-name=volume".background-color = "#1a1b26";
      "app-name=brightness".default-timeout = 2000;
      "app-name=brightness".background-color = "#1a1b26";
      "app-name=wlsunset".default-timeout = 2000;
      "app-name=wlsunset".background-color = "#1a1b26";
      "app-name=power-profiles".default-timeout = 2000;
      "app-name=power-profiles".background-color = "#1a1b26";
    };
  };
}
