{inputs, ...}: {
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem = {
    pkgs,
    config,
    inputs',
    ...
  }: let
    inherit (inputs'.ethereum-nix.packages) geth prysm;
  in {
    devshells.default = {
      name = "ethereum-pos-dev-kit";
      packages = [
        prysm
        geth
      ];
    };
  };
}
