{ system ? "x86_64-linux" }:
let
  pkgs = import ./. { inherit system; };

  build = pkgs.nixos [
    ./configuration.nix
    ./maas-image.nix
  ];
in
pkgs.runCommandNoCC "nixos.tgz" {
  img = build.maasImage;
} ''
  tar -cz -f $out -C $img nixos.img
''
