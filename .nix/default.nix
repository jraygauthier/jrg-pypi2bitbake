{ pkgs ? null
, workspaceDir ? null
} @ args:

let
  nixpkgsSrc = builtins.fetchTarball {
    # nixos-22.11 as of 15/02/2023
    url = "https://github.com/nixos/nixpkgs/archive/c43f676c938662072772339be6269226c77b51b8.tar.gz";
    sha256 = "17qxy63va7yfaf3l4j28d40q2sfb323p4f9x5y57y9dfk26kfwp8";
  };

  ensurePkgs = { pkgs ? null}:
    if null != pkgs
      then pkgs
    else
      import nixpkgsSrc { overlays = []; config = {}; };
in

{
  inherit ensurePkgs;
}
