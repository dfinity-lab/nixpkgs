{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ./maas-config.nix ];

  system.build.maasImage = import (modulesPath + "/../lib/make-disk-image.nix") {
    inherit lib config pkgs;
    diskSize = 4096;
    configFile = pkgs.writeText "configuration.nix" ''
      {
        imports = [
          ${./maas-config.nix}
          ${./configuration.nix}
        ];
      }
    '';
  } // {
    meta.platforms = [ lib.platforms.linux ];
  };
}
