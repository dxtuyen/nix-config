{ pkgs, userName, ... }:

{
  # Tools needed for study. Language libraries stay per-project: use a Python
  # venv today, and `nix develop` when a project gains a flake.
  home-manager.users.${userName}.home.packages = with pkgs; [
    vscode
    python3
    python3Packages.virtualenv
    gcc
    gnumake
    cmake
    gdb
    distrobox

    # R + RStudio cho STAT20 (Berkeley Statistical Thinking). Khóa học làm
    # việc hoàn toàn trong RStudio + Quarto (Quarto nằm sẵn trong RStudio)
    # với bộ package: library(tidyverse); library(stat20data); library(infer)
    # - tidyverse + infer: dùng xuyên suốt khóa → đưa vào Nix cho ổn định.
    # - stat20data: KHÔNG có trên CRAN (package GitHub của khóa, thuần R),
    #   cài 1 lần trong R bằng: remotes::install_github("stat20/stat20data")
    # - remotes: để cài stat20data và các package phát sinh trong R mà
    #   không phải rebuild NixOS.
    (rstudioWrapper.override {
      packages = with rPackages; [
        tidyverse
        infer
        remotes
      ];
    })
    (rWrapper.override {
      packages = with rPackages; [
        tidyverse
        infer
        remotes
      ];
    })
  ];

  # Available for the occasional Fedora/Ubuntu-only project; no container is
  # created automatically and normal study projects do not need it.
  virtualisation.podman.enable = true;
}
