{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.maas;

in {
  options = {
    maas = {
      baseImageSize = mkOption {
        type = types.int;
        default = 2048;
        description = ''
          The size of the MAAS base image in MiB.
        '';
      };
      imgDerivationName = mkOption {
        type = types.str;
        default = "nixos-maas-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
        description = ''
          The name of the derivation for the MAAS image.
        '';
      };
      imgFileName = mkOption {
        type = types.str;
        default = "nixos-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.tgz";
        description = ''
          The file name of the MAAS image.
        '';
      };
    };
  };

  config = {
    system.build.maasImage = import ../../lib/make-disk-image.nix {
      name = cfg.imgDerivationName;
      postVM = ''
        tar -cz -f $out/${cfg.imgFileName} -C $out nixos.img
        rm $diskImage
      '';
      format = "raw";
      diskSize = cfg.baseImageSize;
      partitionTableType = "efi";
      inherit config lib pkgs;
    };

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };

    boot.growPartition = true;

    boot.loader.grub = {
      version = 2;
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
