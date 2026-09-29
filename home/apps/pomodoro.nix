{ ... }:

# Focus: trạng thái tập trung, chống idle và tự tạm dừng khi máy ngủ.

{
  # Watcher chạy qua systemd (tự hồi sinh, log journald, dừng theo phiên Sway).
  systemd.user.services.focus-sleep-watch = {
    Unit = {
      Description = "Auto pause/resume Focus timer on system sleep/wake (logind PrepareForSleep)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      # PATH cho dbus-monitor + study.
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/doxuantuyen/bin:%h/.local/bin"
      ];
      Restart = "on-failure";
      RestartSec = 3;
      ExecStart = "%h/.local/bin/focus-sleep-watch";
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
}
