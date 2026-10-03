#!/usr/bin/env bash
# Cross-compile kanata for Windows from WSL: the GUI, Interception, cmd-allowed variant of the
# pinned release with wintercept-output-device.patch applied. The exe and interception.dll go to
# $1 (default D:\opt\kanata-1.12.0-outdev). rustup with the gnullvm target, llvm-mingw and the
# kanata checkout are downloaded once into $KANATA_BUILD_DIR.
set -euo pipefail

version=v1.12.0
llvm_mingw_release=20260922
llvm_mingw=llvm-mingw-$llvm_mingw_release-ucrt-ubuntu-22.04-x86_64
target=x86_64-pc-windows-gnullvm
here=$(dirname "$(realpath "$0")")
build=${KANATA_BUILD_DIR:-$HOME/.cache/kanata-windows-build}
dest=${1:-/mnt/d/opt/kanata-1.12.0-outdev}

export RUSTUP_HOME=$build/rustup CARGO_HOME=$build/cargo
export PATH=$CARGO_HOME/bin:$build/$llvm_mingw/bin:$PATH
mkdir -p "$build"
[[ -x $CARGO_HOME/bin/cargo ]] ||
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal --target $target
[[ -d $build/$llvm_mingw ]] ||
    curl -fsSL "https://github.com/mstorsjo/llvm-mingw/releases/download/$llvm_mingw_release/$llvm_mingw.tar.xz" |
    tar -xJ -C "$build"
if [[ ! -d $build/kanata ]]; then
    git clone --quiet --depth 1 --branch $version https://github.com/jtroo/kanata.git "$build/kanata"
    git -C "$build/kanata" apply "$here/wintercept-output-device.patch"
fi

# Link libunwind statically so the exe needs no llvm-mingw DLLs, and strip it like a release build.
export CARGO_TARGET_X86_64_PC_WINDOWS_GNULLVM_LINKER=x86_64-w64-mingw32-clang
export CARGO_TARGET_X86_64_PC_WINDOWS_GNULLVM_RUSTFLAGS="-C target-feature=+crt-static"
export CC_x86_64_pc_windows_gnullvm=x86_64-w64-mingw32-clang AR_x86_64_pc_windows_gnullvm=llvm-ar
export CARGO_PROFILE_RELEASE_STRIP=symbols
cd "$build/kanata"
cargo build --release --target $target --features win_manifest,gui,cmd,interception_driver

mkdir -p "$dest"
cp target/$target/release/kanata.exe "$dest/kanata_windows_gui_wintercept_cmd_allowed_x64.exe"
cp "$(find target/$target/release/build -name interception.dll -print -quit)" "$dest/"
echo "Built into $dest"
