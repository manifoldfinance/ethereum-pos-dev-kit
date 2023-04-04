{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = {
    config,
    pkgs,
    ...
  }: {
    treefmt.config = {
      inherit (config.flake-root) projectRootFile;
      package = pkgs.treefmt;

      programs = {
        alejandra.enable = true;
        prettier.enable = true;
      };
    };

    devshells.default = {
      commands = [
        {
          category = "Formatting & Linting";
          name = "fmt";
          help = "Format the source tree";
          command = "nix fmt";
        }
      ];
    };

    formatter = config.treefmt.build.wrapper;
  };
}
