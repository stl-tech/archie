{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, ... }@inputs:
    let
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f:
        builtins.listToAttrs (map (name: {
          inherit name;
          value = f name;
        }) systems);
    in {
      packages = forAllSystems (system: {
        default = let pkgs = import nixpkgs { inherit system; };
        in pkgs.callPackage ./.;
      });
      devShell =
        forAllSystems (system: self.outputs.devShells.${system}.default);
      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [{
              # https://devenv.sh/reference/options/
              packages = [ pkgs.heroku pkgs.yarn ];

              languages.javascript.enable = true;
            }];
          };
        });
      nixosModules = {
        default = { config, lib, pkgs, ... }:
          let
            cfg = config.services.archie;
            description = "archie, a Slack bot for stl-tech";
          in {
            options.services.archie = {
              enable = lib.mkEnableOption description;
              domain = lib.mkOption {
                type = lib.types.str;
                description = "What domain to use for archie";
              };
              port = lib.mkOption {
                type = lib.types.int;
                description = "What port to serve archie on";
                default = 3000;
              };
            };
            config = lib.mkIf cfg.enable {
              networking.firewall.allowedTCPPorts = [ cfg.port ];
              systemd.services.archie = {
                inherit description;
                path = [ pkgs.yarn ];
                script = ''
                  yarn start
                '';
              };
            };
          };
      };
    };
}
