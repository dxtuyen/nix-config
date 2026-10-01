{ pkgs, ... }:

# Countdown: trạng thái tập trung, chống idle và tự tạm dừng khi máy ngủ.
# Menu là `countdown`, engine nội bộ là `countdown-engine` (từng tên `study`, `pomodoro`).

{
  # Watcher chạy qua systemd (tự hồi sinh, log journald, dừng theo phiên Sway).
  systemd.user.services.countdown-sleep-watch = {
    Unit = {
      Description = "Auto pause/resume Countdown timer on system sleep/wake (logind PrepareForSleep)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      # PATH cho dbus-monitor + countdown-engine.
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/doxuantuyen/bin:%h/.local/bin"
      ];
      Restart = "on-failure";
      RestartSec = 3;
      ExecStart = "%h/.local/bin/countdown-sleep-watch";
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };

  # KHÓA MÀN TRƯỚC KHI MÁY NGỦ — chạy ĐỘC LẬP swayidle chính, vì swayidle
  # chính bị engine TẮT suốt phiên (chống tắt màn/ngủ). Không có service này
  # thì đóng nắp/sleep trong phiên sẽ ra về mà KHÔNG khóa gì cả.
  # `swayidle -w` giữ delay-inhibitor → lock chạy xong mới cho phép suspend.
  systemd.user.services.countdown-lock-on-sleep = {
    Unit = {
      Description = "Lock screen before sleep while Countdown stops swayidle (logind before-sleep)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      # PATH cho lệnh con (lock-screen, swaymsg).
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/doxuantuyen/bin:%h/.local/bin"
      ];
      # "always" để hồi sinh nếu có gì đụng phải instance này.
      Restart = "always";
      RestartSec = 2;
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          before-sleep '%h/.local/bin/lock-screen' \
          lock '%h/.local/bin/lock-screen' \
          after-resume 'swaymsg "output * power on"'
      '';
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
}
