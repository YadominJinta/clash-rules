#!/bin/bash

set -euo pipefail

MIHOMO_DOWNLOAD_URL="${MIHOMO_URL:-https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-linux-amd64-v3-v1.19.24.gz}"
MIHOMO_CMD="${MIHOMO_CMD:-mihomo}"
MRS_DIR="${MRS_DIR:-./mrs}"
CIDR_FILES=("cncidr.txt" "lancidr.txt" "telegramcidr.txt")
SKIP_FILES=("applications.txt")

install_mihomo() {
    local archive="./mihomo.gz"
    local target="./mihomo"

    curl -fL "$MIHOMO_DOWNLOAD_URL" -o "$archive"
    gunzip -f "$archive"
    chmod +x "$target"
    MIHOMO_CMD="$target"
}

resolve_mihomo() {
    if [[ "$MIHOMO_CMD" == */* && -x "$MIHOMO_CMD" ]]; then
        return
    fi

    if command -v "$MIHOMO_CMD" >/dev/null 2>&1; then
        MIHOMO_CMD="$(command -v "$MIHOMO_CMD")"
        return
    fi

    if [[ -x "./$MIHOMO_CMD" ]]; then
        MIHOMO_CMD="./$MIHOMO_CMD"
        return
    fi

    install_mihomo
}

contains_file() {
    local needle="$1"
    shift

    local item
    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done

    return 1
}

cleanup_mihomo() {
    if [[ "$MIHOMO_CMD" == "./mihomo" && -f "./mihomo" ]]; then
        rm -f "./mihomo"
    fi
}

convert_ruleset() {
    local input_file="$1"
    local behavior="$2"
    local output_file="$MRS_DIR/${input_file%.txt}.mrs"

    echo "Converting $input_file -> $output_file ($behavior)"
    "$MIHOMO_CMD" convert-ruleset "$behavior" yaml "$input_file" "$output_file"
}

resolve_mihomo
trap cleanup_mihomo EXIT
mkdir -p "$MRS_DIR"

shopt -s nullglob
for input_file in *.txt; do
    if contains_file "$input_file" "${SKIP_FILES[@]}"; then
        echo "Skipping $input_file"
        continue
    fi

    if contains_file "$input_file" "${CIDR_FILES[@]}"; then
        convert_ruleset "$input_file" ipcidr
        continue
    fi

    convert_ruleset "$input_file" domain
done
