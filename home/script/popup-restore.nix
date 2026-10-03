{ pkgs, ... }:

# popup-restore [--one] — show hidden scratchpad window(s) on this workspace.
# $mod+equal uses --one (show ONE, show-only: never hides back);
# $mod+Shift+equal shows ALL. Empty in both modes -> notify, no-op.
# One-way, stateless: no cache. Kebab-case per repo convention.
{
  home.file.".local/bin/popup-restore" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import json
      import shutil
      import subprocess
      import sys

      swaymsg = shutil.which("swaymsg")
      if not swaymsg:
          sys.exit("popup-restore: swaymsg is not in PATH")

      tree = json.loads(subprocess.run(
          [swaymsg, "-t", "get_tree"], check=True, capture_output=True, text=True
      ).stdout)

      def find_hidden(node):
          if node.get("scratchpad_state") not in (None, "none") and not node.get("visible"):
              if node.get("type") in ("con", "floating_con"):
                  yield node
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  yield from find_hidden(child)

      hidden = list(find_hidden(tree))
      if not hidden:
          subprocess.run([
              shutil.which("notify-send") or "notify-send",
              "Scratchpad",
              "No hidden window",
          ], check=False)
          sys.exit(0)

      targets = hidden[:1] if "--one" in sys.argv[1:] else hidden
      for window in targets:
          subprocess.run([swaymsg, f"[con_id={window['id']}] scratchpad show"], check=False)
    '';
  };
}
