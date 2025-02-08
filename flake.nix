{
  description = "Kerio Control VPN Client (Linux x86_64 only)";

  # Use latest stable channel: 24.11
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

  outputs =
    { self, nixpkgs, ... } @ inputs:
    let
      lib = nixpkgs.lib;

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      forEachSystem = f: lib.genAttrs systems (system: f system);
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # nixosModules.kerio-control-vpnclient = import ./module.nix self;

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        {
          default = pkgs.callPackage ./. { };
        });
    };
}
