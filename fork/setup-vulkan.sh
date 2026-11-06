#!/usr/bin/env bash
# Adds the Vulkan backend to node_modules/llama.rn. Run after `yarn install`.
# Shaders are compiled here, before Gradle, so the Android build needs no host tool.
set -euo pipefail

LLAMA_RN_TAG=v0.13.0-rc.9
VULKAN_HEADERS_TAG=v1.4.339
SPIRV_HEADERS_TAG=vulkan-sdk-1.4.363.0
NDK_VERSION=27.3.13750724

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/node_modules/llama.rn"
VK="$PKG/vendor/llama.cpp/ggml/src/ggml-vulkan"
GEN="$PKG/vulkan-generated"
GLSLC="${GLSLC:-$ANDROID_HOME/ndk/$NDK_VERSION/shader-tools/linux-x86_64/glslc}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "::group::Fetch sources"
git clone --depth 1 --branch "$LLAMA_RN_TAG" https://github.com/mybigday/llama.rn "$TMP/llama.rn"
rm -rf "$VK"
cp -r "$TMP/llama.rn/vendor/llama.cpp/ggml/src/ggml-vulkan" "$VK"
rm -rf "$PKG/third_party/Vulkan-Headers" "$PKG/third_party/SPIRV-Headers"
git clone --depth 1 --branch "$VULKAN_HEADERS_TAG" https://github.com/KhronosGroup/Vulkan-Headers "$PKG/third_party/Vulkan-Headers"
git clone --depth 1 --branch "$SPIRV_HEADERS_TAG" https://github.com/KhronosGroup/SPIRV-Headers "$PKG/third_party/SPIRV-Headers"
echo "::endgroup::"

patch -d "$PKG" -p1 --forward < "$ROOT/fork/patches/llama-rn-vulkan.patch"

"$GLSLC" --version
rm -rf "$GEN"; mkdir -p "$GEN/spv"
: > "$GEN/features.txt"
DEFS=()

# Tested WITH -O, the mode the generator uses. Upstream tests without it and
# matches only "extension not supported", so optimizer failures count as
# supported (the shaderc "Invalid capability operand" bug). Any failure = OFF.
feature() {
  if "$GLSLC" -O -o /dev/null -fshader-stage=compute --target-env=vulkan1.3 "$VK/vulkan-shaders/feature-tests/$1.comp" 2>/dev/null; then
    echo "feature ON : $2"; echo "$2" >> "$GEN/features.txt"; DEFS+=("-D$2")
  else
    echo "feature OFF: $2"
  fi
}
feature coopmat GGML_VULKAN_COOPMAT_GLSLC_SUPPORT
feature coopmat2 GGML_VULKAN_COOPMAT2_GLSLC_SUPPORT
feature coopmat2_decode_vector GGML_VULKAN_COOPMAT2_DECODE_VECTOR_GLSLC_SUPPORT
feature integer_dot GGML_VULKAN_INTEGER_DOT_GLSLC_SUPPORT
feature bfloat16 GGML_VULKAN_BFLOAT16_GLSLC_SUPPORT
feature float_e2m1 GGML_VULKAN_FLOAT_E2M1_GLSLC_SUPPORT
feature float_e4m3 GGML_VULKAN_FLOAT_E4M3_GLSLC_SUPPORT

g++ -std=c++17 -O2 -pthread "${DEFS[@]}" "$VK/vulkan-shaders/vulkan-shaders-gen.cpp" -o "$TMP/gen"

HPP="$GEN/ggml-vulkan-shaders.hpp"
"$TMP/gen" --output-dir "$GEN/spv" --target-hpp "$HPP"
for f in "$VK"/vulkan-shaders/*.comp; do
  n="$(basename "$f")"
  echo "shader: $n"
  "$TMP/gen" --glslc "$GLSLC" --source "$f" --output-dir "$GEN/spv" --target-hpp "$HPP" --target-cpp "$GEN/$n.cpp"
done
rm -rf "$GEN/spv"
echo "Generated $(ls "$GEN"/*.cpp | wc -l) shader sources"
