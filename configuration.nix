# NixOS configuration of IC-OS
# =================================
#
# Read the following for an introduction on NixOS modules:
# https://nixos.org/nixos/manual/index.html#sec-writing-modules
#
# Use the following search-engine to lookup up the documentation of an option:
# https://nixos.org/nixos/options.html. Also make sure to click on the source
# link to learn about how the option is used.

{ config, modulesPath, pkgs, lib, ... }: {
  imports = [
    # TODO: this adds support for all hardware supported by NixOS.
    # Since we deploy to specific hardware we might want to trim it
    # and only include what we actually need.
    (modulesPath + "/profiles/all-hardware.nix")

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first in order to
    # install packages.
    #
    # TODO: at some point we may want to remove this because we should
    # not recommend installing packages on a live system.
    # Also nixpkgs is ~123MB.
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];

  # These tags will be shown in the boot-manager (Grub / EFI).
  # Just a bit of branding and making it clear a user is booting IC-OS.
  system.nixos.tags = [ "IC-OS" ];

  # We like all our machines to display time in UTC so as not to become confused
  # when comparing events between machines with different local times.
  time.timeZone = "UTC";

  users = {
    # For reproducibility and security reasons we forbid installing user
    # accounts dynamically (i.e. by running `useradd` on a machine).
    mutableUsers = false;

    # FIXME: we should eventually disable a password for the root user!
    users = {
      root.password = "password:123456";

      # Add a `dfinity` user which will run the `nodemanager`.
      # TODO: think about if we could use systemd's DynamicUser feature instead.
      dfinity = {};
    };
  };

  # We run SSHD so that we can sign in to these machines for debugging.
  services.openssh = {
    enable = true;
    # FIXME: we should eventually disable password logins via SSH and only use
    # public-key authentication!
    #
    # We use `lib.mkDefault` because
    # <nixpkgs/nixos/modules/virtualisation/openstack-config.nix> which is used
    # by the `maas` job is setting this option to "prohibit-password".
    permitRootLogin = lib.mkDefault "yes";
  };

  # Reduce the closure size by removing non-essential things.
  documentation = {
    doc.enable = false;
    nixos.enable = false;
  };
  i18n.supportedLocales = [ (config.i18n.defaultLocale + "/UTF-8") ];
  fonts.fontconfig.enable = false;
  environment.noXlibs = true;

  networking = {
    # systemd-networkd is the future of networking on Linux and on NixOS.
    # Let's use it to simplify things.
    useNetworkd = true;
    # This has to be disabled when networkd is enabled.
    # We enable DHCP per interface below.
    useDHCP = false;

    # Get the hostname from DHCP.
    hostName = "";

    # TODO: think about what to do about the firewall.
    firewall.enable = false;

    firewall.allowedTCPPorts = [
      9100 # Allow prometheus to access the node_exporter service.
    ];
  };

  # Enable DHCP on all links.
  # TODO: for security reasons we might want to restrict this
  # to some pre-specified links.
  systemd.network.networks."main" = {
    matchConfig = { Name = "en* eth*"; };
    DHCP = "yes";
  };

  # Bring some packages into scope which are useful for debugging.
  environment.systemPackages = [
    pkgs.htop

    # Needed for ansible
    pkgs.python3

    # Operations debugging tools.
    pkgs.arping
    pkgs.dhcpdump
    pkgs.inetutils
    pkgs.ngrep
    pkgs.nmap
    pkgs.tcpdump
  ];

  # ansible will add systemd service files dynamically which causes a
  # write to /etc/systemd/system/multi-user.target.wants. That path is
  # in the read-only /nix/store which causes ansible to fail. So we
  # won't make the /nix/store read-only to allow those writes.
  #
  # TODO: This is an ugly hack. We should do proper NixOS deployments
  # instead of using ansible.
  nix.readOnlyStore = false;

  # Enable prometheus node_exporter which accepts requests from prometheus for
  # sending system metrics. Node that we open up TCP port 9100 for this above.
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "0.0.0.0";
    extraFlags = [ "--collector.systemd" ];
  };

  # Forward logs to ElasticSearch
  services.journalbeat = {
    enable = true;
    package = pkgs.journalbeat7;
    extraConfig = ''
      tags: [ "demonet" ]
      logging:
        to_syslog: true
        level: info
        metrics.enabled: false
      journalbeat.inputs:
        - paths: []
          seek: cursor
      output.elasticsearch:
        hosts: [ "elasticsearch.dfinity.systems:9200" ]
        compression_level: 9
      # If "message" is a string-encoded JSON object, parse it as JSON and add
      # this object to the top level JSON object output by journalbeat. This
      # allows JSON log lines to be sent to Elasticsearch as JSON instead of
      # string-encoded JSON, which enables the indexing of the fields in the
      # JSON object.
      processors:
        - decode_json_fields:
            fields: ["message"]
            target: ""
        # If "message" has been extracted into "log_entry", remove "message"
        - drop_fields:
            when:
              has_fields: ['log_entry']
            fields: ["message"]
    '';
  };

  # We disable rate limiting of journald log messages
  # because dropped messages make it harder
  # to debug problems with the replica.
  services.journald.rateLimitInterval = "0";
}
