{ pkgs ? null} @ args:

let
  pkgs = (import ./.nix/default.nix {}).ensurePkgs args;
in

with pkgs;

let
  projectPython = python3;
  /*
  projectPythonEnv = projectPython.withPackages (pp: with pp; [
    pip setuptools wheel
  ]);
  */

  projectPythonEnv = poetry2nix.mkPoetryEnv {
    python = projectPython;
    projectDir = ./.nix/poetry;
    overrides = poetry2nix.overrides.withDefaults (
      import ./.nix/poetry/overrides.nix { inherit pkgs projectPython; }
    );
  };

in

mkShell rec {
  name = "jrg-pypi2bitbake-shell";

  nativeBuildInputs = [
    coreutils
    findutils
    gnused
    gnugrep
    perl
    which
    just
    dtrx
    projectPythonEnv
    projectPython.pkgs.poetry
    projectPython.pkgs.pip
    gnutar
    gzip
    jq
  ];

  shellHook = ''
  '';
}
