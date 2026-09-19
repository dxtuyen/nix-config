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
      # Riêng timeout từng app — background-color đã trùng mặc định nên không
      # cần khai lại từng app nữa.
      # Thông báo dịch tự biến mất sau ~2 phút (120000ms); bấm chuột trái tắt sớm
      "app-name=quick-lang".default-timeout = 120000;
      "app-name=quick-lang".border-color = "#bb9af7";
      # Chuột trái click để tắt thông báo dịch (mặc định là invoke-default-action, không có tác dụng vì app không có action)
      "app-name=quick-lang".on-button-left = "dismiss";
      "app-name=volume".default-timeout = 2000;
      "app-name=brightness".default-timeout = 2000;
      "app-name=wlsunset".default-timeout = 2000;
      "app-name=power-profiles".default-timeout = 2000;
      "app-name=toggle-touchpad".default-timeout = 2000;
      # Study/Burst (pomodoro): viền màu theo màu đồng hồ trên Waybar
      "app-name=study".border-color = "#7aa2f7";
      "app-name=study".default-timeout = 5000;
      "app-name=burst".border-color = "#ff9e64";
      "app-name=burst".default-timeout = 5000;
      "app-name=screenshot".default-timeout = 2000;
      "app-name=power".default-timeout = 2000;
    };
  };
}
