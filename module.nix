flake: {
  config,
  lib,
  pkgs,
  ...
}: let
  # Shortcuts
  cfg = config.services.kerio-kvc;
  pkg = flake.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Systemd service
  service = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      description = "Kerio control daemon user";
      isSystemUser = true;
      group = cfg.group;
    };

    users.groups.${cfg.group} = {};

    systemd.services.kerio-kvc = {
      description = "Kerio Control VPN Client";
      documentation = ["https://github.com/xinux-org/kerio"];

      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      aliases = [
        "kerio-vpn"
        "kerio-control-vpn"
        "kerio-control-vpnclient"
      ];

      serviceConfig = {
        Type = "forking";
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        RestartSec = 5;
        ExecStart = "${lib.getBin cfg.package}/bin/kvpncsvc /var/lib/${cfg.user} 2>&1 | logger -p daemon.err -t kerio-control-vpnclient 2>/dev/null";
        ExecReload = "pkill -SIGHUP kvpncsvc";
        StateDirectory = cfg.user;
        StateDirectoryMode = "0750";

        # Hardening
        CapabilityBoundingSet = [
          "AF_NETLINK"
          "AF_INET"
          "AF_INET6"
        ];
        DeviceAllow = ["/dev/stdin r"];
        DevicePolicy = "strict";
        IPAddressAllow = "localhost";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        ReadOnlyPaths = ["/"];
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_NETLINK"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
          "@pkey"
        ];
        UMask = "0027";
      };
    };
  };
in {
  options = with lib; {
    services.kerio-kvc = {
      enable = mkEnableOption ''
        Enable Kerio Control VPN service.
      '';

      user = mkOption {
        type = types.str;
        default = "kerio-control-vpn";
        description = "User for running service + accessing keys";
      };

      group = mkOption {
        type = types.str;
        default = "kerio-control-vpn";
        description = "Group for running service + accessing keys";
      };

      package = mkOption {
        type = types.package;
        default = pkg;
        description = ''
          Packaged Kerio Control VPN client for the service.
        '';
      };
    };
  };

  config = lib.mkMerge [service];
}
