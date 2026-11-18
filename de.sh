#!/usr/bin/env bash
# Run from the Android source-tree root.
# WARNING: This permanently deletes the listed top-level folders and everything inside them.
set -euo pipefail

if [[ ! -d ".repo" || ! -f "build/envsetup.sh" ]]; then
    echo "Error: this does not look like an Android source-tree root." >&2
    echo "Change to the source-tree root and run this script again." >&2
    exit 1
fi

echo "The following top-level folders will be permanently deleted:"
printf "  %s\n" "android"
printf "  %s\n" "art"
printf "  %s\n" "bionic"
printf "  %s\n" "bootable"
printf "  %s\n" "build"
printf "  %s\n" "cts"
printf "  %s\n" "dalvik"
printf "  %s\n" "developers"
printf "  %s\n" "development"
printf "  %s\n" "device"
printf "  %s\n" "external"
printf "  %s\n" "frameworks"
printf "  %s\n" "hardware"
printf "  %s\n" "kernel"
printf "  %s\n" "libcore"
printf "  %s\n" "libnativehelper"
printf "  %s\n" "lineage-sdk"
printf "  %s\n" "lineage"
printf "  %s\n" "packages"
printf "  %s\n" "pdk"
printf "  %s\n" "platform_testing"
printf "  %s\n" "prebuilts"
printf "  %s\n" "sdk"
printf "  %s\n" "system"
printf "  %s\n" "test"
printf "  %s\n" "toolchain"
printf "  %s\n" "tools"
printf "  %s\n" "trusty"
printf "  %s\n" "vendor"

read -r -p 'Type DELETE to continue: ' confirmation
if [[ "$confirmation" != "DELETE" ]]; then
    echo "Cancelled."
    exit 0
fi

rm -rf -- "android"
rm -rf -- "art"
rm -rf -- "bionic"
rm -rf -- "bootable"
rm -rf -- "build"
rm -rf -- "cts"
rm -rf -- "dalvik"
rm -rf -- "developers"
rm -rf -- "development"
rm -rf -- "device"
rm -rf -- "external"
rm -rf -- "frameworks"
rm -rf -- "hardware"
rm -rf -- "kernel"
rm -rf -- "libcore"
rm -rf -- "libnativehelper"
rm -rf -- "lineage-sdk"
rm -rf -- "lineage"
rm -rf -- "packages"
rm -rf -- "pdk"
rm -rf -- "platform_testing"
rm -rf -- "prebuilts"
rm -rf -- "sdk"
rm -rf -- "system"
rm -rf -- "test"
rm -rf -- "toolchain"
rm -rf -- "tools"
rm -rf -- "trusty"
rm -rf -- "vendor"
echo "Main-folder deletion completed."
