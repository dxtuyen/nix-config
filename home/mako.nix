{ ... }:

{
  services.mako = {
    enable = true;
    settings = {
      # width 400 rộng hơn gốc (300) để hiện nhiều chữ mỗi dòng.
      # height 600 cho phép nội dung dài hiện gần trọn vẹn
      # (Mako không có tính năng hover-mở rộng, nên cần height đủ lớn
      #  để tránh cắt nội dung; 600px chiếm ~58% chiều cao màn hình 1080p).
      margin = "35,20,20,20";
      width = 400;
      height = 600;
      default-timeout = 5000;
      "app-name=quick-lang".default-timeout = 8000;
      "app-name=volume".default-timeout = 2000;
      "app-name=brightness".default-timeout = 2000;
      "app-name=wlsunset".default-timeout = 2000;
      "app-name=power-profiles".default-timeout = 2000;
    };
  };
}
