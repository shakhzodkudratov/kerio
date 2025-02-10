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
      dpkg
      glibc
      patchelf
      autoPatchelfHook
    ];

    unpackPhase = ''
      # Unpack .deb
      mkdir -p $out $out/bin
      dpkg -x $src $out

      # Follow nix way
      cp -r $out/usr/lib/* $out/lib/  # LD libraries
      cp -r $out/usr/sbin/* $out/bin/ # Binaries / executables
      rm -rf $out/usr                 # Deleting garbages
    '';

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
      echo $unpackPhase
      runHook preInstall
      runHook postInstall
    '';

    meta = with lib; {
      homepage = "http://www.kerio.com/control";
      description = "Kerio Control VPN client for corporate networks.";
      licencse = lib.licenses.unfree;
      platforms = with platforms; linux;
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
        # TODO: Shakhzod
      ];
    };
  }
