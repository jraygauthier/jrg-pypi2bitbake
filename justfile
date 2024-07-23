in_requirements_file := justfile_directory() / "in-requirements.txt"
out_dir := justfile_directory() / "out"
sdist_out_dir := out_dir / "sdist"
recipe_out_dir := out_dir / "recipe"

set shell := ["bash", "-uc"]

default:
    @just _dowload-reqs
    @just _mk_recipe_files

clean:
    rm -rf "{{ out_dir }}"

_mk-sdist-out-dir:
    mkdir -p "{{ sdist_out_dir }}"

_dowload-reqs: _mk-sdist-out-dir
    cd "{{ sdist_out_dir }}" \
      && pip download --disable-pip-version-check --no-deps --no-build-isolation --no-binary=:all: -r "{{ in_requirements_file }}"

_mk-recipe-out-dir:
    mkdir -p "{{ recipe_out_dir }}"

_mk_recipe_files: _mk-recipe-out-dir
    #!/usr/bin/env bash
    set -euf pipefail
    while read -r archive; do
        1>&2 echo "INFO: archive='$archive'"

        declare pkg_info_json
        pkg_info_json="$(pkginfo --json "$archive")"

        declare pkg_info_raw
        if [[ "$archive" == *.tar.gz ]]; then
            unset GZIP
            pkg_info_raw="$(tar \
              --wildcards '**/PKG-INFO' --use-compress-program=gzip \
              -xOzf \
              "$archive" \
            )"
        elif [[ "$archive" == *.zip ]]; then
            pkg_info_raw="$(unzip -p "$archive" '*/PKG-INFO')"
        else
            1>&2 printf -- "ERROR: Cannot extract license from python sdist.\n"
            1>&2 printf -- " -> Unsupported sdist file format: '%s'.\n" \
              "$archive"
            exit 1
        fi

        declare license_file
        license_file="$(echo "$pkg_info_raw" | grep -E '^License-File' | head -n 1 | awk '{ print $2 }' | awk -v RS='\r' '{ print $1}')"

        if [[ -z "$license_file" ]]; then
            1>&2 printf -- "WARNING: Missing 'License-File' pkg info field.\n"
            1>&2 printf -- " -> Defaulting to 'LICENSE'.\n"
            license_file="LICENSE"
        fi

        1>&2 echo "DEBUG: license_file='$license_file'"

        declare license
        if [[ "$archive" == *.tar.gz ]]; then
            license="$(tar \
              --wildcards "**/${license_file}" --use-compress-program=gzip \
              -xOzf \
              "$archive" \
            )"
        elif [[ "$archive" == *.zip ]]; then
            license="$(unzip -p "$archive" "*/${license_file}")"
        else
            1>&2 printf -- "ERROR: Cannot extract license from python sdist.\n"
            1>&2 printf -- " -> Unsupported sdist file format: '%s'.\n" \
              "$archive"
            exit 1
        fi

        declare license_md5
        license_md5="$(echo "$license" | md5sum | awk '{print $1}')"

        declare src_uri_line="$( \
          pip hash --disable-pip-version-check --algorithm sha256 "$archive" \
          | grep -E "^--hash" \
          | sed -E \
              -e 's/^--hash\=([^\:]+)\:([0-9a-fA-F]+)$/SRC_URI[\1sum] = "\2"/g')"

        1>&2 echo "DEBUG: src_uri_line='$src_uri_line'"

        declare pkg_name
        pkg_name="$(echo "$pkg_info_json" | jq -j '.name')"

        declare pkg_version
        pkg_version="$(echo "$pkg_info_json" | jq -j '.version')"

        declare license_name
        license_name="$(echo "$pkg_info_json" | jq -j '.license')"

        declare summary
        summary="$(echo "$pkg_info_json" | jq -j '.summary')"

        declare homepage
        homepage="$(echo "$pkg_info_json" | jq -j '.home_page')"

        declare -A lic_py2yocto=( \
          ["MIT"]="MIT" \
        )

        declare lic_yocto_name="$license_name"
        if [[ "${lic_py2yocto["${license_name}"]+x}" = "x" ]]; then
            lic_yocto_name="${lic_py2yocto["${license_name}"]}"
        else
            1>&2 printf -- "WARNING: No matching yocto license name for '%s'.\n" \
              "$license_name"
            1>&2 printf -- " -> Keeping license name as is.\n"
            lic_yocto_name="$license_name"
        fi

        1>&2 echo "DEBUG: license_name='$license_name'"
        1>&2 echo "DEBUG: lic_yocto_name='$lic_yocto_name'"

        declare recipe_out_file="{{ recipe_out_dir }}/python3-${pkg_name}_${pkg_version}.bb"

        printf -- 'SUMMARY = "%s"\n' "$summary" > "$recipe_out_file"
        printf -- 'HOMEPAGE = "%s"\n' "$homepage" >> "$recipe_out_file"
        printf -- 'LICENSE = "%s"\n' "$lic_yocto_name" >> "$recipe_out_file"
        printf -- 'LIC_FILES_CHKSUM = "file://%s;md5=%s"\n' \
          "$license_file" "$license_md5" >> "$recipe_out_file"

        printf -- "\n" >> "$recipe_out_file"
        echo "$src_uri_line" >> "$recipe_out_file"

        printf -- "\n" >> "$recipe_out_file"
        # printf -- 'PYPI_PACKAGE = "%s"\n' "$pkg_name" >> "$recipe_out_file"
        # printf -- "\n" >> "$recipe_out_file"
        printf -- "inherit setuptools3 pypi\n" >> "$recipe_out_file"
        printf -- "\n" >> "$recipe_out_file"
        printf -- 'BBCLASSEXTEND = "native nativesdk"\n' >> "$recipe_out_file"

    done < <(find "{{ sdist_out_dir }}" -mindepth 1 -maxdepth 1)
