{ pkgs, ... }:

{
  # Tools needed for study. Language libraries stay per-project: use a Python
  # venv today, and `nix develop` when a project gains a flake.
  environment.systemPackages = with pkgs; [
    vscode
    python3 python3Packages.virtualenv
    gcc gnumake cmake gdb
    distrobox podman
  ];

  # Available for the occasional Fedora/Ubuntu-only project; no container is
  # created automatically and normal study projects do not need it.
  virtualisation.podman.enable = true;
}
