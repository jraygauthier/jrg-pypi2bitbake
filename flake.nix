{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    systems.url = "github:nix-systems/default/main";
    flake-utils.url = "github:numtide/flake-utils/main";
    flake-utils.inputs.systems.follows = "systems";
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
    poetry2nix.inputs.systems.follows = "systems";
    poetry2nix.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {nixpkgs, poetry2nix, ...}: let
    overlays = [
      poetry2nix.overlays.default
      (import ./.nix/overlay.nix)
    ];
    forAllSystems = f:
      nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ] (
        system:
          f (let
            pkgs = import nixpkgs {
              inherit overlays system;
              config = {
                allowUnfree = false;
              };
            };

            projectPython = pkgs.python3;
            projectPythonEnv = pkgs.poetry2nix.mkPoetryEnv {
              python = projectPython;
              projectDir = ./.nix/poetry;
              overrides = pkgs.poetry2nix.defaultPoetryOverrides.extend (
                import ./.nix/poetry/overrides.nix {inherit pkgs projectPython;}
              );
            };

          in {
            inherit pkgs;
            inherit projectPython;
            inherit projectPythonEnv;
          })
      );
  in {
    inherit overlays;
    devShells = forAllSystems (
      {
        pkgs,
        projectPython,
        projectPythonEnv,
        ...
      }: {
        default = with pkgs;
          mkShell {
            packages = [
              bashInteractive
              coreutils
              findutils
              gnused
              gnugrep
              perl
              which
              just
              dtrx
              projectPythonEnv
              poetry
              projectPython.pkgs.poetry-dynamic-versioning
              projectPython.pkgs.poetry-core
              projectPython.pkgs.pkginfo
              projectPython.pkgs.pip
              gnutar
              gzip
              jq
            ];

            shellHook = ''
            '';
          };
      }
    );
  };
}
