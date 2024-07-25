Readme
======

A quickly sketched tool to generate yocto bitbake recipes from a python
requirements file.


## Prequisites

### Entering the reproducible environment

```bash
$ cd /path/to/this/repo
$ nix develop
# ..
```

Once within the environment, all required dependencies will be available for
this tool to run properly.

The above requires that [`nix` is installed][nix-install] and that the [flakes
feature is enabled][nix-flake-enabled].

[nix-install]: https://nixos.org/download
[nix-flake-enabled]: https://nixos.wiki/wiki/Flakes#Enable_flakes_permanently_in_NixOS


## Usage

### Specifying python requirements

Create a `./in-requirements.txt` file with the requirements of your choice:

```txt
py-pkg-a==2.2.1
py-pkg-b==5.6.1
py-pkg-c
```


### Running the tool

Run the tool as follow:

```bash
$ just
# ..
# -> ./out/
```

You will find the generated yocto bitbake recipes under `./out/recipe`
and the intermediate python sdist under `./out/sdist`.


## To do

 -  Add support for dependencies.

    Currently, this tool won't generate the recipe's dependencies.

 -  Add support for generating transitive depdencies.

    Currently, this tool only generate recipes explicitly listed
    in the requirement input file and won't generate anything
    else.

 -  Add support to customize input and output paths.

    Currently, the tool assume input requirements are in file at a hardcoded
    location (`./in-requirements.txt`) and produces its outputs under an
    hardcoded directory (`./out/`).


## Similar tools

 -  [NFJones/pipoe: Generate python bitbake recipes!](https://github.com/NFJones/pipoe)

    Was previously using this tool but it no longer works with the current
    version of pypi.

 -  [robseb/PiP2Bitbake: Script to create a Bitbake recipe for Python pip (PyPI) Packages to be embedded within the Yocto Project](https://github.com/robseb/PiP2Bitbake)

    Attempted to use this tool and found out unexpected / dangerous use of
    `sudo`. Attempted to fix the tool only to find out it would not work on some
    dependencies.

## License

Licensed under Apache License, Version 2.0 [LICENSE](./LICENSE).
