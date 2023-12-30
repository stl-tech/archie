{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, ... }@inputs:
    let system = "x86_64-linux";
    in {
      packages.${system}.default =
        let pkgs = import nixpkgs { inherit system; };
        in pkgs.callPackage ./. { inherit pkgs; };
      devShells.${system} = let pkgs = import nixpkgs { inherit system; };
      in {
        default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [{
            # https://devenv.sh/reference/options/
            packages = [ pkgs.heroku pkgs.yarn ];

            languages.javascript.enable = true;
          }];
        };
      };
      nixosModules = {
        default = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.services.archie;
            description = "archie, a Slack bot for stl-tech";
          in {
            options.services.archie = {
              enable = mkEnableOption description;
              domain = mkOption {
                type = types.str;
                description = "What domain to serve archie from";
              };
              acme-email = mkOption {
                  type = types.str;
                  description = "Which email to use for Let's Encrypt";
              };
              port = mkOption {
                  type = types.int;
                  description = "Which port to serve from. Make sure this matches up with envFile you deploy!";
                  default = 3000;
              };
            };
            config = mkIf cfg.enable {
              security.acme.certs.${cfg.domain}.email = cfg.acme-email;
              services.nginx.virtualHosts.${cfg.domain} = {
                  enableACME = true;
                  forceSSL = true;
                  locations."/" = {
                      proxyPass = "http://localhost:${toString cfg.port}";
                  };
              };
              systemd.services.archie = {
                inherit description;
                path = [ self.outputs.packages.${system}.default ];
                script = ''
                  archie
                '';
              };
            };
          };
      };
    };
}
