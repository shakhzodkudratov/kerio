{
  autoPatchelfHook,
  pkgs ? import <nixpkgs> {},
  ...
}: let
  lib = pkgs.lib;
in
  pkgs.stdenv.mkDerivation rec {
    pname = "kerio-control-vpnclient";
    version = "9.4.5-8629";

    src = pkgs.fetchurl {
      url = "https://cdn.kerio.com/dwn/control/control-${version}/${pname}-${version}-linux-amd64.deb";
      hash = "sha256-rQTGjCr5koU06nafK/LWqneEdC0kZYYWwTmUB7MXg/g=";
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      dpkg
    ];

    buildInputs = with pkgs; [
      libgcc
      libstdcxx5
      stdenv.cc.cc.lib

      curl

      procps
      dialog
      util-linux
      libxcrypt-legacy
      openssl
    ];

    installPhase = ''
      mkdir -p $out
      dpkg -x $src $out
    '';

    meta = with lib; {
      homepage = "http://www.kerio.com/control";
      description = "Kerio Control VPN client for corporate networks.";
      licencse = lib.licenses.unfree;
      platforms = with platforms; linux ++ darwin;
    };
  }
