{ ... }:

# Countdown: trạng thái tập trung, chống idle và tự tạm dừng khi máy ngủ.
# Engine nội bộ là `countdown-engine` (trước đây `study`); menu là `countdown`.

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
}
