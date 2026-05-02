#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <qt-build-dir> <qt-install-prefix>" >&2
    exit 2
fi

build_dir=$1
prefix=$2

if [ ! -d "$build_dir" ]; then
    echo "build directory not found: $build_dir" >&2
    exit 1
fi

if [ ! -d "$prefix" ]; then
    echo "install prefix not found: $prefix" >&2
    exit 1
fi

copy_archives() {
    src_dir=$1
    dst_dir=$2

    [ -d "$src_dir" ] || return 0
    mkdir -p "$dst_dir"
    find "$src_dir" -maxdepth 1 -type f -name '*.a' -exec cp {} "$dst_dir/" \;
}

copy_archives "$build_dir/lib/.aarch64" "$prefix/lib/.aarch64"

for plugin_arch_dir in "$build_dir"/plugins/*/.aarch64; do
    [ -d "$plugin_arch_dir" ] || continue
    plugin_name=$(basename "$(dirname "$plugin_arch_dir")")
    copy_archives "$plugin_arch_dir" "$prefix/plugins/$plugin_name/.aarch64"
done

if [ -d "$build_dir/qml" ]; then
    find "$build_dir/qml" -path '*/.aarch64' -type d | while IFS= read -r qml_arch_dir; do
        relative_dir=${qml_arch_dir#"$build_dir"/}
        copy_archives "$qml_arch_dir" "$prefix/$relative_dir"
    done
fi

find "$prefix" \
    -path '*/objects-Release/*/*.o' \
    -not -path '*/.aarch64/*' \
    -type f | while IFS= read -r installed_object; do
        object_name=$(basename "$installed_object")
        source_object=$(find "$build_dir" -path "*/.aarch64/$object_name" -type f | head -n 1)

        [ -n "$source_object" ] || continue

        target_dir="$(dirname "$installed_object")/.aarch64"
        mkdir -p "$target_dir"
        cp "$source_object" "$target_dir/$object_name"
    done
