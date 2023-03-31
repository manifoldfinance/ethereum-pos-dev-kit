{inputs, ...}: {
  imports = [
    inputs.flake-root.flakeModule
    ./checks.nix
    ./formatter.nix
    ./shell.nix
  ];
}
