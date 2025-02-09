{pkgs ? import <nixpkgs> {}, ...}: let
  lib = pkgs.lib;
in
  pkgs.stdenv.mkDerivation rec {
    pname = "kerio-control-vpnclient";
    version = "9.4.5-8629";

    src = pkgs.fetchurl {
      url = "https://cdn.kerio.com/dwn/control/control-${version}/${pname}-${version}-linux-amd64.deb";
      hash = "sha256-rU5tinj1FN2z8u7w7GEV9oa21v+eeo8OQXXWnyZw9ys=";
    };

    nativeBuildInputs = with pkgs; [
      # autoPatchelfHook
      dpkg
    ];

    unpackPhase = "true";

    buildInputs = with pkgs; [
      libgcc
      stdenv.cc.cc.lib

      curl

      procps
      dialog
      util-linux
      libxcrypt-legacy
      openssl
    ];

    installPhase = ''
      mkdir -p $out $out/bin
      dpkg -x $src $out
    '';

    meta = with lib; {
      homepage = "http://www.kerio.com/control";
      description = "Kerio Control VPN client for corporate networks.";
      licencse = lib.licenses.unfree;
      platforms = with platforms; linux ++ darwin;
      maintainers = [
        {
          name = "Sokhibjon Orzikulov";
          email = "sakhib@orzklv.uz";
          handle = "orzklv";
          github = "orzklv";
          githubId = 54666588;
          keys = [
            {
              fingerprint = "00D2 7BC6 8707 0683 FBB9  137C 3C35 D3AF 0DA1 D6A8";
            }
          ];
        }
      ];
    };
  }
