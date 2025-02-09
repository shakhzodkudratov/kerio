{
  description = "Kerio Control VPN Client (Linux x86_64 only)";

  inputs = {
    # Good for now!
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    # Optimized best for 24.11
    # Unstable only when maintainer is suicidal
    # nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # The flake-utils library
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachSystem [
      "x86_64-linux"
    ] (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # Nix script formatter
        formatter = pkgs.alejandra;

        # Development environment
        devShells.default = import ./shell.nix {inherit pkgs;};

        # Output package
        packages.default = pkgs.callPackage ./. {inherit pkgs;};
      }
    )
    // {
      # Overlay module
      # nixosModules.kerio = import ./module.nix self;
    };
}
