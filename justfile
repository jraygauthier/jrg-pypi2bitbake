repo_root := absolute_path(justfile_directory())
in_requirements_file := repo_root / "in-requirements.txt"
out_dir := repo_root / "out"
sdist_out_dir := out_dir / "sdist"
recipe_out_dir := out_dir / "recipe"

set shell := ["bash", "-uc"]

default: init _dowload-reqs _mk_recipe_files

init: _init_in_req

clean:
    @rm -rf "{{ out_dir }}"

_init_in_req:
    @touch "{{ in_requirements_file }}"

_dowload-reqs:
    @"{{ repo_root }}/.scripts/download-sdists" \
      "{{ sdist_out_dir }}" \
      "{{ in_requirements_file }}"

_mk_recipe_files:
    @"{{ repo_root }}/.scripts/generate-bb-recipes" \
      "{{ recipe_out_dir }}" \
      "{{ sdist_out_dir }}"
