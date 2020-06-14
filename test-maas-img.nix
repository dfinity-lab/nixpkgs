{ system ? "x86_64-linux" }:
let
  pkgs = import ./. { inherit system; };

  build = pkgs.nixos [
    ./nixos/modules/virtualisation/maas-image.nix
    # You can place NixOS customizations here
  ];
in
build.maasImage
