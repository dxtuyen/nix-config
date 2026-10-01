{ ... }:

# Pomodoro: trạng thái tập trung, chống idle và tự tạm dừng khi máy ngủ.
# Menu là `pomodoro`, engine nội bộ là `pomodoro-engine` (từng tên `countdown`, `study`).

{
  # Watcher chạy qua systemd (tự hồi sinh, log journald, dừng theo phiên Sway).
  systemd.user.services.pomodoro-sleep-watch = {
    Unit = {
      Description = "Auto pause/resume Pomodoro timer on system sleep/wake (logind PrepareForSleep)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      # PATH cho dbus-monitor + pomodoro-engine.
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/doxuantuyen/bin:%h/.local/bin"
      ];
      Restart = "on-failure";
      RestartSec = 3;
      ExecStart = "%h/.local/bin/pomodoro-sleep-watch";
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
}
