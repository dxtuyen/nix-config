{ pkgs, ... }:

# popup-restore [--one] — show hidden scratchpad window(s) on this workspace.
# $mod+equal uses --one (show ONE — the most RECENTLY stashed, LIFO — show-only:
# never hides back); $mod+Shift+equal shows ALL, oldest first so the freshest one
# ends up on top. Empty in both modes -> notify, no-op.
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

      # LIFO, not FIFO: Sway keeps its scratchpad list ordered by hide recency,
      # oldest first — root_scratchpad_hide() calls list_move_to_end() on every
      # hide, and ipc_json_describe_scratchpad_output() emits the __i3_scratch
      # floating_nodes in exactly that list order. So the LAST hidden window is
      # the one just stashed -> pop from the END. Taking hidden[0] (what this did
      # before) always surfaced the OLDEST stashed window instead.
      # Show ALL keeps oldest->newest, which leaves the freshest one on top.
      one = "--one" in sys.argv[1:]
      targets = hidden[-1:] if one else hidden
      for window in targets:
          subprocess.run([swaymsg, f"[con_id={window['id']}] scratchpad show"], check=False)
    '';
  };
}
