{ pkgs, projectPython }:

self: super: {
  # Use nixpkgs's pip.
  pip = projectPython.pkgs.pip;

  pkg-metadata = super.pkg-metadata.overridePythonAttrs (
    old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.flit-core ];
    }
  );
}
