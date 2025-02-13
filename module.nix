flake: {
  config,
  lib,
  pkgs,
  ...
}: let
  # Shortcuts
  cfg = config.services.kerio-kvc;
  pkg = flake.packages.${pkgs.stdenv.hostPlatform.system}.default;
  file = "/etc/kerio-kvc.conf";

  # Password XOR generator
  xor = password: ''
    XOR=""
    for i in `echo -n "$password" | od -t d1 -A n`; do
      XOR=$(printf "%s%02x" "$XOR" $((i ^ 85)))
    done
  '';

  # Systemd service
  service = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      description = "Kerio control daemon user";
      isSystemUser = true;
      group = cfg.group;
    };

    users.groups.${cfg.group} = {};

    environment.etc.${file} = {
      mode = "0600";
      user = cfg.user;
    };

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
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "full";
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

      # Pre-start script to generate config file
      preStart = ''
        PASSWORD=""
        if [ -f "${cfg.config.password}" ]; then
          PASSWORD=$(cat ${cfg.config.password})
        fi

        XOR=""
        if [ -n "$PASSWORD" ]; then
          ${xor "$PASSWORD"}
        fi

        # Auto-detect fingerprint if enabled
        FINGERPRINT=""
        if [ "${toString cfg.config.fingerprint.auto}" == "true" ]; then
          echo "Fetching fingerprint from ${cfg.config.domain}:${toString cfg.config.port}..."
          FINGERPRINT=$(echo | openssl s_client -connect "${cfg.config.domain}:${toString cfg.config.port}" 2>/dev/null | openssl x509 -fingerprint -md5 -noout | sed 's/.*=//')

          if [ -z "$FINGERPRINT" ]; then
            echo "Error: Failed to fetch fingerprint!" >&2
            exit 1
          fi
        elif [ -f "${
          if cfg.config.fingerprint.data == null
          then cfg.config.fingerprint.data
          else "/dev/null"
        }" ]; then
          FINGERPRINT=$(cat ${
          if cfg.config.fingerprint.data == null
          then cfg.config.fingerprint.data
          else "/dev/null"
        })
        fi

        cat > ${file} << EOF
        <config>
          <connections>
            <connection type="persistent">
              <server>${cfg.config.domain}</server>
              <port>${toString cfg.config.port}</port>
              <username>${cfg.config.user}</username>
              <password>XOR:$XOR</password>
              <fingerprint>$FINGERPRINT</fingerprint>
              <active>1</active>
            </connection>
          </connections>
        </config>
        EOF

        chmod 0600 ${file}
      '';
    };
  };
in {
  options = with lib; {
    services.kerio-kvc = {
      enable = mkEnableOption ''
        Enable Kerio Control VPN service.
      '';

      config = {
        domain = mkOption {
          type = types.str;
          default = "192.168.0.1";
          example = "uic-gw.example.uz";
          description = "Domain or IP address of Kerio Control VPN server";
        };

        port = mkOption {
          type = types.int;
          default = 4090;
          description = "Port to Kerio Control VPN server";
        };

        user = mkOption {
          type = types.str;
          default = "example";
          example = "example";
          description = "Domain or IP address of Kerio Control VPN server";
        };

        password = mkOption {
          type = with types; nullOr path;
          default = null;
          description = lib.mdDoc ''
            Path to password file of Kerio Control VPN user.
          '';
        };

        fingerprint = {
          auto = mkEnableOption ''
            Automatically detect the fingerprint from server or enter manually.
          '';

          data = mkOption {
            type = with types; nullOr path;
            default = null;
            description = lib.mdDoc ''
              Path to server provided fingerprint.
            '';
          };
        };
      };

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
