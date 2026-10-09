{ lib, pkgs, ... }:

let
  swayview = pkgs.stdenvNoCC.mkDerivation {
    pname = "swayview";
    version = "0.1.8";
    src = pkgs.fetchurl {
      url = "https://github.com/agejevasv/swayview/releases/download/v0.1.8/swayview-v0.1.8-x86_64-linux.tar.gz";
      hash = "sha256:124szx38lxln3i88rqzvai1q69vvvg74mhhz4mqgfj9qg51g1ira";
    };
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [
      pkgs.libxkbcommon
      pkgs.wayland
      pkgs.fontconfig
      pkgs.freetype
      pkgs.stdenv.cc.cc.lib
    ];
    sourceRoot = "swayview-v0.1.8-x86_64-linux";
    installPhase = ''
      install -Dm755 swayview $out/bin/swayview
      install -Dm644 LICENSE $out/share/licenses/swayview/LICENSE
    '';
    meta = {
      description = "Workspace overview and switcher for Sway";
      homepage = "https://github.com/agejevasv/swayview";
      license = lib.licenses.mit;
      mainProgram = "swayview";
      platforms = lib.platforms.linux;
    };
  };
in

# User packages from the nixos-unstable revision pinned in flake.lock.
{

  home.packages = with pkgs; [
    rofi
    swayr # switch windows by focus history (Alt+Tab-style MRU)
    swayview # overview and switcher for Sway workspaces
    wlsunset
    grim
    slurp
    wl-clipboard
    swaylock
    swayidle
    awww # Wallpaper daemon with animated transitions.
    libnotify
    wiremix # PipeWire mixer (terminal UI).
    brightnessctl
    translate-shell
    goldendict-ng
    wifitui # Wi-Fi management TUI.

    bluetui
    google-chrome
    # E-book reader.
    foliate
    imv # Image viewer.
    mpv # Media player.
    ripgrep # Fast text search.
    fd # Fast file search.
    dust # Disk usage charts.
    ncdu # Interactive disk usage browser.
    sioyek
    obsidian
    # Zotero is temporarily disabled because the pinned package fails to build:
    #   AboutTranslations: ... not found in modules/ActorManagerParent.sys.mjs -- aborting
    # Re-enable after updating nixpkgs to a working version.
    #qzotero # Reference manager.
    jq
    fastfetch
    libreoffice
    # Development tools.
    vscode
    python3
    python3Packages.virtualenv
    gcc
    gnumake
    cmake
    gdb
    jdk
    distrobox
    gh # GitHub CLI.
    # Virtual machine tools.
    qemu_kvm
    qemu-utils
    OVMF
  ];
}
