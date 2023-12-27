{ pkgs ? import <nixpkgs> { } }:
pkgs.mkYarnPackage {
  name = "archie";
  src = ./.;
  packageJSON = ./package.json;
  yarnLock = ./yarn.lock;
  yarnNix = ./yarn.nix;
}
